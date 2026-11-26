import { run, setShared } from "herdr";
import { reportFailure } from "./actions";
import { selectPanel, showThreadInPanel } from "./panel";
import { moveProject, type Project } from "./projects";
import type { Scene } from "./scene";
import { ORDER, readScene, readViews, VIEWS } from "./snapshot";
import { projectHome, projectThreads, type Thread } from "./threads";
import { rememberedThread, withView } from "./views";

/** Records what the project on show has open in the panel: a thread, or null for its list. */
function remember(thread: string | null): void {
  const project = readScene().shown?.name;
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
  remember(thread.key);
  showInPanel(thread.key, true);
}

/** Goes back to the list of threads, and remembers that for the project on show. */
export function showThreadList(): void {
  remember(null);
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
