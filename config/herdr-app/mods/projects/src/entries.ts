import type { Status } from "herdr";
import { leadOf, LOCAL, type Project } from "./projects";
import { attention, groupOf, mostUrgent, type Group } from "./status";

/** One row of the project list. */
export interface Entry {
  readonly id: string;
  readonly name: string;
  /** Where the project runs. */
  readonly aside: string;
  /** Who in it waits on the person and who works, else how many threads it has. */
  readonly detail: string;
  readonly status: Status | null;
  readonly selected: boolean;
}

function count(amount: number, noun: string): string {
  return `${amount} ${noun}${amount === 1 ? "" : "s"}`;
}

function place(project: Project, offline: boolean): string {
  const [machine] = project.machines;
  const where = project.machines.length > 1 ? count(project.machines.length, "machine") : (machine ?? LOCAL);
  return offline ? `${where} · offline` : where;
}

function detail(project: Project, groups: readonly Group[]): string {
  const lead = leadOf(project);
  const open = groups.filter((group) => group !== "resolved");
  const amount = (group: Group) => open.filter((candidate) => candidate === group).length;
  const moves = [
    lead && groupOf(lead.status, lead.resolved) === "waiting" ? "orchestrator waits" : null,
    amount("review") > 0 ? `${amount("review")} to review` : null,
    amount("waiting") > 0 ? `${amount("waiting")} waiting` : null,
    amount("finished") > 0 ? `${amount("finished")} finished` : null,
    amount("working") > 0 ? `${amount("working")} working` : null,
  ].filter((move) => move !== null);
  if (moves.length > 0) return moves.join(" · ");
  return open.length > 0 ? count(open.length, "thread") : "No thread";
}

/** What a row is drawn from, beside the project itself. */
export interface EntryContext {
  readonly selected: boolean;
  /** True when a machine the project runs on cannot be reached: what the row shows is then old. */
  readonly offline: boolean;
  /** Whose move each thread of the project is. */
  readonly groups: readonly Group[];
}

export function projectEntry(project: Project, { selected, offline, groups }: EntryContext): Entry {
  return {
    id: `project-${project.name}`,
    name: project.name,
    aside: place(project, offline),
    detail: detail(project, groups),
    status: attention(mostUrgent(project.members.map((member) => member.status))),
    selected,
  };
}
