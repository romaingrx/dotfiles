import { exec } from "herdr";
import { machineOf } from "../terminal";
import type { Thread } from "../threads";
import { baseRefs, parseBranchDiff, type BranchDiff } from "./diff";
import { DISCUSSIONS_QUERY, parseDiscussions, REPLY_MUTATION, type Discussion } from "./discussions";
import type { About } from "./draft";

/** How long the read of a branch's diff may take. */
const DIFF_TIMEOUT = 60_000;

/**
 * Prints the first of the refs `$@` that the branch has a common commit with,
 * then all the folder holds against that commit: what the branch committed,
 * what is not committed yet, and the files git does not track yet. The reads
 * take no lock and write nothing under `.git`.
 */
const DIFF = `cd "$(git rev-parse --show-toplevel)" || exit 1
for base in "$@"; do
  fork=$(git merge-base "$base" HEAD 2>/dev/null) || continue
  printf '%s\\n' "$base"
  git --no-optional-locks -c core.quotePath=false diff --no-color --no-ext-diff --no-textconv -M "$fork" -- || exit 1
  git ls-files --others --exclude-standard -z |
    xargs -0 -r -n 1 git -c core.quotePath=false diff --no-color --no-index -- /dev/null
  exit 0
done
echo "this repository has no base branch to compare with" >&2
exit 1`;

/** How long the read of a pull request's discussions may take. */
const DISCUSSIONS_TIMEOUT = 30_000;

/**
 * The open discussions of a thread's pull request, read with `gh` in the
 * thread's folder on its machine. `gh` fills in the repository of that folder.
 * None for a thread without a pull request.
 */
export async function readDiscussions(thread: Thread): Promise<Discussion[]> {
  if (!thread.checkout || !thread.pull) return [];
  const fields = ["owner={owner}", "name={repo}", `number=${thread.pull.number}`].flatMap((field) => ["-F", field]);
  const options = { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout: DISCUSSIONS_TIMEOUT };
  const result = await exec("gh", ["api", "graphql", ...fields, "-f", `query=${DISCUSSIONS_QUERY}`], options);
  if (result.code !== 0)
    throw new Error(`GitHub's comments: ${result.stderr.trim() || `gh ended with code ${result.code}`}`);
  return parseDiscussions(JSON.parse(result.stdout));
}

/**
 * Posts an answer on GitHub as a reply in its discussion, in the name of
 * whoever `gh` is signed in as on the thread's machine. The body goes as it
 * is: `-f` takes it as text.
 */
export async function postReply(thread: Thread, about: About, body: string): Promise<void> {
  if (!thread.checkout) throw new Error("this thread has no folder of its own to post from");
  const fields = [`query=${REPLY_MUTATION}`, `discussion=${about.discussion}`, `body=${body}`].flatMap((field) => [
    "-f",
    field,
  ]);
  const options = { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout: DISCUSSIONS_TIMEOUT };
  const result = await exec("gh", ["api", "graphql", ...fields], options);
  if (result.code !== 0)
    throw new Error(
      `GitHub did not take the reply to @${about.author}: ${result.stderr.trim() || `gh ended with code ${result.code}`}`,
    );
}

/** The whole branch of a thread against its base, read in the thread's folder on its machine. */
export async function readBranchDiff(thread: Thread): Promise<BranchDiff> {
  if (!thread.checkout) throw new Error("this thread has no folder of its own to review");
  const options = { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout: DIFF_TIMEOUT };
  const result = await exec("sh", ["-c", DIFF, "sh", ...baseRefs(thread.pull?.base ?? null)], options);
  if (result.code !== 0) throw new Error(result.stderr.trim() || `git ended with code ${result.code}`);
  return parseBranchDiff(result.stdout);
}
