import { setShared } from "herdr";
import { runProgram } from "./host";
import { pullAnswer, pullAsks, type PullAsk } from "./pull-asks";
import { PULL_FIELDS, type Pull, type Pulls } from "./pulls";
import { attempt } from "./result";
import { PULLS, readScene } from "./snapshot";
import { projectThreads } from "./threads";

/** How long one read of a pull request may take. */
const PULL_TIMEOUT = 20_000;

/**
 * One pull request, read with `gh`: null when there is none. A read that
 * fails keeps what was known, and so does a bug in the reading of one: the
 * other pull requests of the round are still stored.
 */
async function readPull(ask: PullAsk, known: Pulls): Promise<Pull | null> {
  const kept = known[ask.key] ?? null;
  const read = await attempt(async () => {
    const options = { ...(ask.cwd !== null && { cwd: ask.cwd }), on: ask.on, timeout: PULL_TIMEOUT };
    const printed = await runProgram("gh", ["pr", "view", ...ask.args, "--json", PULL_FIELDS], options);
    return pullAnswer(printed, kept);
  });
  return read.ok ? read.value : kept;
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
