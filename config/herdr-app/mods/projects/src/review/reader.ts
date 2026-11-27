import { exec } from "herdr";
import { placeOf, type Pull } from "../pulls";
import { machineOf } from "../terminal";
import type { Thread } from "../threads";
import { parseBranchDiff, type BranchDiff, type ReviewRange } from "./diff";
import { DISCUSSIONS_QUERY, parseDiscussions, REPLY_MUTATION, type Discussion } from "./discussions";
import type { About } from "./draft";

/** How long the read of a branch's diff may take. */
const DIFF_TIMEOUT = 60_000;
/** What the script takes in place of a branch, to read the folder. */
const FOLDER = "-";

/**
 * Takes a branch, or `-` for the folder, then the refs it may be compared
 * with. Prints the first of those refs that it has a common commit with, then
 * the diff against that commit. For the folder, that is what the branch
 * committed, what is not committed yet, and the files git does not track yet.
 * A branch that is only on the remote is read there. The reads take no lock
 * and write nothing under `.git`.
 */
const DIFF = `cd "$(git rev-parse --show-toplevel)" || exit 1
tip=$1
shift
[ "$tip" = ${FOLDER} ] && tip=
if [ -n "$tip" ] && ! git rev-parse --verify --quiet "$tip^{commit}" >/dev/null; then tip="origin/$tip"; fi
for base in "$@"; do
  fork=$(git merge-base "$base" "\${tip:-HEAD}" 2>/dev/null) || continue
  printf '%s\\n' "$base"
  git --no-optional-locks -c core.quotePath=false diff --no-color --no-ext-diff --no-textconv -M "$fork" \${tip:+"$tip"} -- || exit 1
  [ -n "$tip" ] || git ls-files --others --exclude-standard -z |
    xargs -0 -r -n 1 git -c core.quotePath=false diff --no-color --no-index -- /dev/null
  exit 0
done
echo "this repository has no base branch to compare with" >&2
exit 1`;

/** How long a question to GitHub may take. */
const GITHUB_TIMEOUT = 30_000;

/** Runs a program in a thread's folder, on its machine. A thread without a folder of its own has nothing to review. */
async function inFolder(thread: Thread, program: string, args: string[], timeout: number): Promise<string> {
  if (!thread.checkout) throw new Error("this thread has no folder of its own to review");
  const result = await exec(program, args, { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout });
  if (result.code !== 0) throw new Error(result.stderr.trim() || `${program} ended with code ${result.code}`);
  return result.stdout;
}

/** Asks GitHub's GraphQL API on the host of a pull request, as whoever `gh` is signed in as on the thread's machine. */
function askGitHub(thread: Thread, host: string, query: string, fields: readonly string[]): Promise<string> {
  const args = ["api", "graphql", "--hostname", host, "-f", `query=${query}`, ...fields];
  return inFolder(thread, "gh", args, GITHUB_TIMEOUT);
}

/** One layer of a thread's work against its base, read in the thread's folder. */
export async function readBranchDiff(thread: Thread, range: ReviewRange): Promise<BranchDiff> {
  const args = ["-c", DIFF, "sh", range.tip ?? FOLDER, ...range.bases];
  return parseBranchDiff(await inFolder(thread, "sh", args, DIFF_TIMEOUT));
}

/** The open discussions of a pull request on GitHub, read with `gh`. None without a pull request. */
export async function readDiscussions(thread: Thread, pull: Pull | null): Promise<Discussion[]> {
  const place = pull && placeOf(pull.url);
  if (!place) return [];
  const fields = [`owner=${place.owner}`, `name=${place.name}`, `number=${place.number}`];
  const answer = await askGitHub(
    thread,
    place.host,
    DISCUSSIONS_QUERY,
    fields.flatMap((field) => ["-F", field]),
  );
  return parseDiscussions(JSON.parse(answer));
}

/**
 * Posts an answer on GitHub as a reply in its discussion, in the name of
 * whoever `gh` is signed in as on the thread's machine. The body goes as it
 * is: `-f` takes it as text.
 */
export async function postReply(thread: Thread, pull: Pull, about: About, body: string): Promise<void> {
  const place = placeOf(pull.url);
  if (!place) throw new Error(`${pull.url} is not the URL of a pull request`);
  const fields = [`discussion=${about.discussion}`, `body=${body}`].flatMap((field) => ["-f", field]);
  try {
    await askGitHub(thread, place.host, REPLY_MUTATION, fields);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new Error(`GitHub did not take the reply to @${about.author}: ${reason}`);
  }
}
