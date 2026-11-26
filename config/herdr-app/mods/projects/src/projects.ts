import { groupOf } from "./status";
import type { Terminal } from "./terminal";

export const ORCHESTRATOR = "orchestrator";
export const LOCAL = "local";

/** A project's name is a terminal name, a label and a file name. */
const NAME = /^[a-z0-9][a-z0-9-]{0,15}$/;
/** The rule of `NAME`, in words. `start.sh` enforces the same one. */
const NAME_RULE = "Use lowercase letters, digits and hyphens, 16 characters at most.";

/** Every live terminal that carries the same `project` label, on any machine. */
export interface Project {
  readonly name: string;
  /** The orchestrator first, when the project has one. */
  readonly members: readonly Terminal[];
  /** Where its sessions run: null is this computer. */
  readonly machines: readonly (string | null)[];
}

function isLead(member: Terminal): boolean {
  return member.role === ORCHESTRATOR;
}

/** The project's orchestrator: the session that hands its work out. */
export function leadOf(project: Project): Terminal | undefined {
  return project.members.find(isLead);
}

/** The sessions that do the project's work, without the orchestrators that hand it out. */
export function threadsOf(project: Project): Terminal[] {
  return project.members.filter((member) => !isLead(member));
}

/** How many of the project's threads wait on the person. */
export function waitingOn(project: Project): number {
  return threadsOf(project).filter((member) => groupOf(member.status, member.resolved) === "waiting").length;
}

export function isProjectName(name: string): boolean {
  return NAME.test(name);
}

/** What is wrong with a name for a project, given the names the other projects have. */
export function nameProblem(name: string, others: readonly string[]): string | null {
  if (!isProjectName(name)) return NAME_RULE;
  return others.includes(name) ? `A project named ${name} exists already.` : null;
}

export function projectsOf(terminals: readonly Terminal[]): Project[] {
  const byName = new Map<string, Terminal[]>();
  for (const terminal of terminals) {
    if (!terminal.project) continue;
    byName.set(terminal.project, [...(byName.get(terminal.project) ?? []), terminal]);
  }
  return [...byName.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([name, members]) => ({
      name,
      members: [...members.filter(isLead), ...members.filter((member) => !isLead(member))],
      machines: [...new Set(members.map((member) => member.machine))],
    }));
}

/** The project the thread list shows: the one of the terminal that has the keyboard, else none. */
export function shownProject(projects: readonly Project[], focused: string | null): Project | null {
  if (focused === null) return null;
  return projects.find((project) => project.members.some((member) => member.address === focused)) ?? null;
}

/** Reads a stored list of project names; anything else is an empty list. */
export function parseOrder(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((name): name is string => typeof name === "string") : [];
}

/** The projects in the person's order. One the order does not name comes after, by name. */
export function orderProjects(projects: readonly Project[], order: readonly string[]): Project[] {
  const place = new Map(order.map((name, index) => [name, index]));
  const rank = (project: Project) => place.get(project.name) ?? order.length;
  return [...projects].sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name));
}

/** The order after `moved` is dropped on `target`: it takes that place, and the rest keeps its order. */
export function moveProject(names: readonly string[], moved: string, target: string): string[] {
  const rest = names.filter((name) => name !== moved);
  const at = rest.indexOf(target);
  if (at < 0 || !names.includes(moved)) return [...names];
  // Dropped on a project below it, it lands after that project; on one above, before it.
  const after = names.indexOf(moved) < names.indexOf(target);
  return [...rest.slice(0, at + (after ? 1 : 0)), moved, ...rest.slice(at + (after ? 1 : 0))];
}
