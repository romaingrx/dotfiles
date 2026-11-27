import { exec, setShared } from "herdr";
import { pullAsks, type PullAsk } from "./pull-asks";
import { parsePull, PULL_FIELDS, type Pull, type Pulls } from "./pulls";
import { PULLS, readScene } from "./snapshot";
import { projectThreads } from "./threads";

/** How long one read of a pull request may take. */
const PULL_TIMEOUT = 20_000;

/** What `gh` says when there is no such pull request. Any other failure tells nothing about it. */
const NO_PULL = /no pull requests found|Could not resolve to a PullRequest/;

/**
 * One pull request, read with `gh`: null when there is none. A read that
 * fails (the machine is away, `gh` is signed out) keeps what was known.
 */
async function readPull(ask: PullAsk, known: Pulls): Promise<Pull | null> {
  const before = known[ask.key] ?? null;
  try {
    const options = { ...(ask.cwd !== null && { cwd: ask.cwd }), on: ask.on, timeout: PULL_TIMEOUT };
    const result = await exec("gh", ["pr", "view", ...ask.args, "--json", PULL_FIELDS], options);
    if (result.code === 0) return parsePull(JSON.parse(result.stdout)) ?? before;
    return NO_PULL.test(result.stderr) ? null : before;
  } catch {
    return before;
  }
}

/**
 * Reads the pull requests of every open thread, and stores them when one
 * changed. The cache is built from those reads alone, so what a resolved or
 * ended thread had leaves it.
 */
export async function refreshPulls(): Promise<void> {
  const { snapshot, projects } = readScene();
  const open = projects.flatMap((project) => projectThreads(snapshot, project)).filter((thread) => !thread.resolved);
  const read = await Promise.all(
    pullAsks(open).map(async (ask) => [ask.key, await readPull(ask, snapshot.pulls)] as const),
  );
  const pulls = Object.fromEntries(read.filter(([, pull]) => pull !== null));
  if (JSON.stringify(pulls) !== JSON.stringify(snapshot.pulls)) setShared(PULLS, pulls);
}
