import { exec, setShared } from "herdr";
import { parsePull, PULL_FIELDS, type Pull } from "./pulls";
import { PULLS, readScene } from "./snapshot";
import { machineOf } from "./terminal";
import { projectThreads, type Thread } from "./threads";

/** How long one read of a pull request may take. */
const PULL_TIMEOUT = 20_000;

/** The pull request of the branch in a thread's folder, read there with `gh`. Null when it has none. */
async function readPull(thread: Thread): Promise<Pull | null> {
  if (!thread.checkout) return null;
  try {
    const options = { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout: PULL_TIMEOUT };
    const result = await exec("gh", ["pr", "view", "--json", PULL_FIELDS], options);
    return result.code === 0 ? parsePull(JSON.parse(result.stdout)) : null;
  } catch {
    return null;
  }
}

/** Reads the pull request of every open thread, and stores them when one changed. */
export async function refreshPulls(): Promise<void> {
  const { snapshot, projects } = readScene();
  const open = projects.flatMap((project) => projectThreads(snapshot, project)).filter((thread) => !thread.resolved);
  const read = await Promise.all(open.map(async (thread) => [thread.key, await readPull(thread)] as const));
  const pulls = Object.fromEntries(read.filter(([, pull]) => pull !== null));
  if (JSON.stringify(pulls) !== JSON.stringify(snapshot.pulls)) setShared(PULLS, pulls);
}
