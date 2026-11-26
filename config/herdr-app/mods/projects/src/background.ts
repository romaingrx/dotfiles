import type { AsyncContext } from "gpui-kit";
import { checking, nextCommand, notify, setBadge } from "herdr";
import { openNewProjectDialog, reportFailure } from "./actions";
import { openNextWait, selectProject, showThreadList, stepProject } from "./navigation";
import { readScene } from "./snapshot";
import { waits, waitsToAnnounce, type Wait } from "./waits";

const MOD = "projects";
/** How often the waits are looked at. */
const LOOK_EVERY = 5_000;

/** `select-1` to `select-9` show the project at that place in the list, as a number key does for a tab. */
const SELECT = Object.fromEntries(
  Array.from({ length: 9 }, (_, index) => [`select-${index + 1}`, () => selectProject(index)] as const),
);

/** The mod's commands, for keys.json (`projects.<name>`) and the command palette. */
const COMMANDS: Readonly<Record<string, () => void>> = {
  ...SELECT,
  new: openNewProjectDialog,
  next: () => stepProject(1),
  prev: () => stepProject(-1),
  "next-waiting": openNextWait,
  threads: showThreadList,
};

async function runCommands(): Promise<void> {
  for (;;) {
    const name = await nextCommand();
    try {
      COMMANDS[name]?.();
    } catch (error) {
      reportFailure(`Could not run ${MOD}.${name}`, error);
    }
  }
}

function announce(wait: Wait): void {
  notify({
    title: `${wait.title ?? "The orchestrator"} needs you`,
    body: wait.project,
    level: "warning",
    action: { name: `${MOD}.next-waiting` },
  });
}

/**
 * Tells the person about the sessions that wait on them: their count on the
 * app's icon, and a notice for each new wait that Herdr does not announce.
 */
function watchWaits(cx: AsyncContext): void {
  let badge: string | null | undefined;
  let known: ReadonlySet<string> | null = null;
  const look = (): void => {
    const { snapshot, projects } = readScene();
    const all = waits(snapshot, projects);
    const count = all.length > 0 ? String(all.length) : null;
    if (count !== badge) setBadge(count);
    badge = count;
    // What waited before the mod started is no news.
    if (known) waitsToAnnounce(known, all, snapshot.focused).forEach(announce);
    known = new Set(all.map((wait) => wait.terminal));
  };
  look();
  cx.timer.every(LOOK_EVERY, look);
}

/**
 * What one copy of the mod does beside drawing. The project list's copy does
 * it: the sidebar is always there. `herdr-app check` loads the mod without an
 * app to act on.
 */
export function startBackground(cx: AsyncContext): void {
  if (checking()) return;
  cx.spawn(runCommands);
  watchWaits(cx);
}
