import type { Project } from "./projects";
import { groupOf } from "./status";
import type { Terminal } from "./terminal";
import { longestFirst, projectThreads, type Snapshot } from "./threads";

/** A session that waits on the person. */
export interface Wait {
  readonly terminal: string;
  readonly project: string;
  /** The thread's title, or null for the project's orchestrator. */
  readonly title: string | null;
  readonly since: number | null;
  /** True when the session asked with a report: Herdr itself only knows that its turn ended. */
  readonly asked: boolean;
}

function isWaiting(member: Terminal): boolean {
  return groupOf(member.status, member.resolved) === "waiting";
}

/** Every session that waits on the person, in every project, the one that waits longest first. */
export function waits(snapshot: Snapshot, projects: readonly Project[]): Wait[] {
  return projects
    .flatMap((project) => {
      const waiting = project.members.filter(isWaiting);
      if (waiting.length === 0) return [];
      const titles = new Map(projectThreads(snapshot, project).map((thread) => [thread.key, thread.title]));
      return waiting.map((member) => ({
        terminal: member.address,
        project: project.name,
        title: titles.get(member.address) ?? null,
        since: member.since,
        asked: member.reported === "needs-you",
      }));
    })
    .sort(longestFirst);
}

/** The wait to go to next: the one after the session that has the keyboard, else the longest one. */
export function nextWait(all: readonly Wait[], focused: string | null): Wait | undefined {
  const at = all.findIndex((wait) => wait.terminal === focused);
  return all[(at + 1) % all.length];
}


/**
 * The waits to tell the person about: those that began since the last look
 * with a report, which Herdr does not announce, and not the one of the
 * session the person is in.
 */
export function waitsToAnnounce(before: ReadonlySet<string>, all: readonly Wait[], focused: string | null): Wait[] {
  return all.filter((wait) => wait.asked && !before.has(wait.terminal) && wait.terminal !== focused);
}
