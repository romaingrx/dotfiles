import { notify, run, setShared } from "herdr";
import { reportFailure } from "./actions";
import { selectPanel, showThreadInPanel } from "./panel";
import { moveProject, type Project } from "./projects";
import type { Scene } from "./scene";
import { ORDER, readScene, readViews, VIEWS } from "./snapshot";
import { projectHome, projectThreads, threadAt, type Thread } from "./threads";
import { rememberedThread, withView } from "./views";
import { nextWait, waits } from "./waits";

/** Records what a project has open in the panel: a thread, or null for its list. */
function remember(project: string | undefined, thread: string | null): void {
  const views = readViews();
  if (project === undefined || (views[project] ?? null) === thread) return;
  setShared(VIEWS, withView(views, project, thread));
}

function focusTerminal(terminal: string): void {
  run("pane.focus", { terminal });
}

function showInPanel(terminal: string, focus: boolean): void {
  try {
    showThreadInPanel(terminal, focus);
  } catch (error) {
    reportFailure("Could not open the thread", error);
  }
}

/** Opens a thread where it shows. One that opens in the panel is what its project has open from then on. */
export function openThread(thread: Thread): void {
  if (thread.opens === "pane") {
    focusTerminal(thread.key);
    return;
  }
  remember(thread.project, thread.key);
  showInPanel(thread.key, true);
}

/** Goes back to the list of threads, and remembers that for the project on show. */
export function showThreadList(): void {
  remember(readScene().shown?.name, null);
  selectPanel("threads");
}

/**
 * Shows a project as the person left it: its orchestrator in the middle, and
 * in the panel the thread it had open, else its list of threads.
 */
export function openProject(scene: Scene, project: Project): void {
  const home = projectHome(scene.snapshot, project);
  const inPanel = projectThreads(scene.snapshot, project).filter((thread) => thread.opens === "panel");
  const thread = rememberedThread(
    readViews(),
    project.name,
    inPanel.map((candidate) => candidate.key),
  );
  if (home === null) {
    // Without a pane to focus, one of its sessions takes the panel and the keyboard: the list follows the keyboard.
    const session = thread ?? project.members[0]?.address;
    if (session) showInPanel(session, true);
    return;
  }
  if (thread) showInPanel(thread, false);
  else selectPanel("threads");
  focusTerminal(home);
}

/** Puts a dragged project where it was dropped. */
export function dropProject(scene: Scene, moved: string, target: string): void {
  setShared(
    ORDER,
    moveProject(
      scene.projects.map((project) => project.name),
      moved,
      target,
    ),
  );
}

/** Goes to the project after the one on show in the list, or to the one before it; around the ends. */
export function stepProject(step: 1 | -1): void {
  const scene = readScene();
  const count = scene.projects.length;
  const shown = scene.shown ? scene.projects.indexOf(scene.shown) : null;
  const from = shown ?? (step === 1 ? -1 : 0);
  const next = scene.projects[(from + step + count) % count];
  if (next) openProject(scene, next);
}

/**
 * Goes to the session that waits on the person next: its project's
 * orchestrator in the middle, and the thread that waits in the panel.
 */
export function openNextWait(): void {
  const scene = readScene();
  const wait = nextWait(waits(scene.snapshot, scene.projects), scene.snapshot.focused);
  const project = scene.projects.find((candidate) => candidate.name === wait?.project);
  if (!wait || !project) {
    notify({ title: "No session waits on you", level: "info" });
    return;
  }
  const thread = threadAt(scene.snapshot, [project], wait.terminal);
  if (!thread) {
    // The orchestrator itself waits.
    openProject(scene, project);
    return;
  }
  const home = projectHome(scene.snapshot, project);
  if (home && thread.opens === "panel") focusTerminal(home);
  openThread(thread);
}
