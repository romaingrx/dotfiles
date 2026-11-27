import type { AsyncContext } from "gpui-kit";
import { checking, nextCommand, setBadge, window } from "herdr";
import { openNewProjectDialog, openReview, reportFailure } from "./actions";
import { openNextWait, selectProject, showThreadList, stepProject } from "./navigation";
import { readPanel } from "./panel";
import { refreshPulls } from "./pull-reader";
import { readScene } from "./snapshot";
import { waits } from "./waits";

const MOD = "projects";
/** How often the waits are looked at. */
const LOOK_EVERY = 5_000;
/** How often the threads' pull requests are read again. */
const PULLS_EVERY = 120_000;

/** `select-1` to `select-9` show the project at that place in the list, as a number key does for a tab. */
const SELECT = Object.fromEntries(
  Array.from({ length: 9 }, (_, index) => [`select-${index + 1}`, () => selectProject(index)] as const),
);

/** Opens the review of the thread that is open in the panel. */
function reviewOpenThread(): void {
  const { thread } = readPanel();
  if (thread) openReview(thread);
}

/** The mod's commands, for keys.json (`projects.<name>`) and the command palette. */
const COMMANDS: Readonly<Record<string, () => void>> = {
  ...SELECT,
  new: openNewProjectDialog,
  next: () => stepProject(1),
  prev: () => stepProject(-1),
  "next-waiting": openNextWait,
  threads: showThreadList,
  review: reviewOpenThread,
};

/**
 * Runs the commands as they come. A build of the mod that was replaced still
 * waits here: the use of `cx` ends its loop before it runs a command twice.
 */
async function runCommands(cx: AsyncContext): Promise<void> {
  for (;;) {
    const name = await nextCommand();
    cx.notify();
    try {
      COMMANDS[name]?.();
    } catch (error) {
      reportFailure(`Could not run ${MOD}.${name}`, error);
    }
  }
}

/** Keeps the number of sessions that wait on the person on the app's icon. */
function watchWaits(cx: AsyncContext): void {
  let badge: string | null | undefined;
  const look = (): void => {
    const { snapshot, projects } = readScene();
    const amount = waits(snapshot, projects).length;
    const count = amount > 0 ? String(amount) : null;
    if (count !== badge) setBadge(count);
    badge = count;
  };
  look();
  cx.timer.every(LOOK_EVERY, look);
}

/** Keeps the threads' pull requests up to date while the window is on show. */
function watchPulls(cx: AsyncContext): void {
  const look = (): void => {
    if (window()?.visible) void refreshPulls();
  };
  look();
  cx.timer.every(PULLS_EVERY, look);
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
  watchPulls(cx);
}
