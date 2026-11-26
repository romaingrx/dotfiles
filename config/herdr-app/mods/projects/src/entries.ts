import type { Status } from "herdr";
import { LOCAL, threadsOf, type Project } from "./projects";
import { attention, mostUrgent } from "./status";

/** One row of the project list. */
export interface Entry {
  readonly id: string;
  readonly name: string;
  /** Where the project runs. */
  readonly aside: string;
  readonly detail: string;
  readonly status: Status | null;
  readonly selected: boolean;
}

function count(amount: number, noun: string): string {
  return `${amount} ${noun}${amount === 1 ? "" : "s"}`;
}

export function projectEntry(project: Project, selected: boolean): Entry {
  const [machine] = project.machines;
  const spread = project.machines.length > 1;
  return {
    id: `project-${project.name}`,
    name: project.name,
    aside: spread ? count(project.machines.length, "machine") : (machine ?? LOCAL),
    detail: count(threadsOf(project).length, "thread"),
    status: attention(mostUrgent(project.members.map((member) => member.status))),
    selected,
  };
}
