import { exec } from "herdr";
import { machineOf } from "../terminal";
import type { Thread } from "../threads";
import { baseRefs, parseBranchDiff, type BranchDiff } from "./diff";

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

/** The whole branch of a thread against its base, read in the thread's folder on its machine. */
export async function readBranchDiff(thread: Thread): Promise<BranchDiff> {
  if (!thread.checkout) throw new Error("this thread has no folder of its own to review");
  const options = { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout: DIFF_TIMEOUT };
  const result = await exec("sh", ["-c", DIFF, "sh", ...baseRefs(thread.pull?.base ?? null)], options);
  if (result.code !== 0) throw new Error(result.stderr.trim() || `git ended with code ${result.code}`);
  return parseBranchDiff(result.stdout);
}
