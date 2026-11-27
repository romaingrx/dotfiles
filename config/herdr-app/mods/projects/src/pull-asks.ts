import { parseJson } from "./parse";
import { parsePull, refKey, type Pull, type PullRef } from "./pulls";
import type { Result } from "./result";
import { machineOf } from "./terminal";
import type { Thread } from "./threads";

/** One question for `gh`: which pull request to read, and where. */
export interface PullAsk {
  /** The key of the answer in the cache. */
  readonly key: string;
  /** What follows `gh pr view`: the URL, or nothing for the folder's branch. */
  readonly args: readonly string[];
  /** The folder to ask in. A URL needs none. */
  readonly cwd: string | null;
  /** The machine to ask on; null for this computer. */
  readonly on: string | null;
}

/** What `gh` says when there is no such pull request. Any other failure tells nothing about it. */
const NO_PULL = /no pull requests found|Could not resolve to a PullRequest/;

/** The question a reference of a thread makes. None for the branch of a thread that has no folder of its own. */
function askOf(thread: Thread, ref: PullRef): PullAsk | null {
  const on = machineOf(thread.key);
  if (ref.kind === "declared") return { key: refKey(ref), args: [ref.url], cwd: null, on };
  return thread.checkout ? { key: refKey(ref), args: [], cwd: thread.checkout.folder, on } : null;
}

/** What to ask `gh` for some threads: each pull request once, also when two threads name it. */
export function pullAsks(threads: readonly Thread[]): PullAsk[] {
  const asks = threads.flatMap((thread) => thread.refs.map((ref) => askOf(thread, ref)));
  const byKey = new Map(asks.filter((ask) => ask !== null).map((ask) => [ask.key, ask]));
  return [...byKey.values()];
}

/**
 * The pull request that `gh pr view` answered with: null when `gh` says there
 * is none. A read that fails for another reason (the machine is away, `gh` is
 * signed out), or that prints no pull request, keeps what was known.
 */
export function pullAnswer(printed: Result<string>, known: Pull | null): Pull | null {
  if (!printed.ok) return NO_PULL.test(printed.error) ? null : known;
  const read = parseJson(printed.value);
  return (read.ok ? parsePull(read.value) : null) ?? known;
}
