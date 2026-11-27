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
      const threads = new Map(projectThreads(snapshot, project).map((thread) => [thread.key, thread]));
      return waiting.map((member) => {
        const thread = threads.get(member.address);
        return {
          terminal: member.address,
          project: project.name,
          title: thread?.title ?? null,
          // The time the thread list sorts by, so that both give the same order.
          since: thread ? thread.since : member.since,
        };
      });
    })
    .sort(longestFirst);
}

/** The wait to go to next: the one after the session that has the keyboard, else the longest one. */
export function nextWait(all: readonly Wait[], focused: string | null): Wait | undefined {
  const at = all.findIndex((wait) => wait.terminal === focused);
  return all[(at + 1) % all.length];
}
