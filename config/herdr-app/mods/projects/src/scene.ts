import { orderProjects, projectsOf, shownProject, type Project } from "./projects";
import type { Snapshot } from "./threads";

/** What every part of the mod draws from, built once per render. */
export interface Scene {
  readonly snapshot: Snapshot;
  /** Every project, in the person's order. */
  readonly projects: readonly Project[];
  /** The project whose threads show, if any. */
  readonly shown: Project | null;
}

export function buildScene(snapshot: Snapshot, order: readonly string[]): Scene {
  const projects = orderProjects(projectsOf(snapshot.terminals), order);
  return { snapshot, projects, shown: shownProject(projects, snapshot.focused) };
}

/** A folder to offer for a new project on a machine: where its first space works. Null names this computer. */
export function usualFolder(snapshot: Snapshot, machine: string | null): string | null {
  const space = snapshot.spaces.find((candidate) => candidate.machine === machine);
  if (!space) return null;
  const tabs = new Set(space.tabs.map((tab) => tab.id));
  const live = snapshot.panes.find((pane) => tabs.has(pane.tab) && pane.cwd)?.cwd;
  return live ?? (space.folder || null);
}
