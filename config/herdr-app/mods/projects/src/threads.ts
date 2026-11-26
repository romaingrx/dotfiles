import type { AgentInfo, PaneInfo, SpaceInfo, Status, TabInfo } from "herdr";
import { leadOf, LOCAL, threadsOf, type Project } from "./projects";
import { GROUPS, groupOf, isBusy, type Group } from "./status";
import type { Terminal } from "./terminal";
import { stripGlyph } from "./text";

/** What the app reports, read once per render. */
export interface Snapshot {
  readonly spaces: readonly SpaceInfo[];
  readonly panes: readonly PaneInfo[];
  readonly agents: readonly AgentInfo[];
  readonly terminals: readonly Terminal[];
  /** The address of the terminal that has the keyboard. */
  readonly focused: string | null;
}

/** A tab that one session owns: Herdr's rename, close and settle apply to it. */
export interface OwnTab {
  readonly id: string;
  readonly space: string;
}

/** One row of the thread list: a session that does a project's work. */
export interface Thread {
  /** Its terminal's address. */
  readonly key: string;
  readonly title: string;
  readonly status: Status | null;
  readonly agent: boolean;
  readonly active: boolean;
  readonly resolved: boolean;
  /** Its pane, when it has one. */
  readonly pane: string | null;
  /** The tab it owns, when it leads one. */
  readonly tab: OwnTab | null;
  /** What a working or blocked agent says it is doing. */
  readonly note: string | null;
  /** Where it runs, when its project is on more than one machine. */
  readonly aside: string | null;
  /** When its status last changed, in ms since the epoch. */
  readonly since: number | null;
  /** Where a click shows it: in its own pane in the middle, or in the right panel. */
  readonly opens: "pane" | "panel";
}

export interface ThreadGroup {
  readonly id: Group;
  readonly label: string;
  readonly threads: readonly Thread[];
}

/** Where a session sits in the app: its pane, and its tab when it leads that tab. */
interface Seat {
  readonly pane: PaneInfo;
  readonly home: { readonly tab: TabInfo; readonly space: SpaceInfo } | null;
}

function note(terminal: Terminal): string | null {
  if (!terminal.activity || !isBusy(terminal.status)) return null;
  return stripGlyph(terminal.activity) || null;
}

/** A tab's first agent pane, else its first terminal pane. */
function leadPanes(panes: readonly PaneInfo[]): Map<string, PaneInfo> {
  const leads = new Map<string, PaneInfo>();
  for (const pane of panes) {
    if (!pane.terminal) continue;
    const current = leads.get(pane.tab);
    if (!current || (!current.program.agent && pane.program.agent)) leads.set(pane.tab, pane);
  }
  return leads;
}

function seats(snapshot: Snapshot): Map<string, Seat> {
  const leads = leadPanes(snapshot.panes);
  const homes = new Map(snapshot.spaces.flatMap((space) => space.tabs.map((tab) => [tab.id, { tab, space }] as const)));
  const seated = new Map<string, Seat>();
  for (const pane of snapshot.panes) {
    if (!pane.terminal) continue;
    const home = leads.get(pane.tab) === pane ? homes.get(pane.tab) : undefined;
    seated.set(pane.terminal, { pane, home: home ?? null });
  }
  return seated;
}

/**
 * The name of a session, for every place that shows one. Names given in Herdr
 * win: the pane's name, then the name of the tab it owns. Then the title its
 * orchestrator gave it, then what the terminal itself says.
 */
function sessionTitle(terminal: Terminal, seat: Seat | undefined): string {
  if (seat?.pane.name) return seat.pane.name;
  // Herdr names a new tab after the program it starts: that is not a name someone gave.
  const tab = seat?.home?.tab;
  if (tab?.named && tab.name !== seat?.pane.program.name) return tab.name;
  return terminal.heading ?? terminal.name ?? (stripGlyph(terminal.title) || terminal.address);
}

/** The threads of a project. Its orchestrator is not one of them: it is the project's own session. */
export function projectThreads(snapshot: Snapshot, project: Project): Thread[] {
  const seated = seats(snapshot);
  const spread = project.machines.length > 1;
  // With the orchestrator in the middle, a thread opens beside it; without one, in its own pane.
  const lead = leadOf(project);
  const beside = lead !== undefined && seated.has(lead.address);
  return threadsOf(project).map((member) => {
    const seat = seated.get(member.address);
    return {
      key: member.address,
      title: sessionTitle(member, seat),
      status: member.status,
      agent: member.agent || member.status !== null,
      active: member.address === snapshot.focused,
      resolved: member.resolved,
      pane: seat?.pane.pane ?? null,
      tab: seat?.home ? { id: seat.home.tab.id, space: seat.home.space.id } : null,
      note: note(member),
      aside: spread ? (member.machine ?? LOCAL) : null,
      since: seat?.home?.tab.changed_at ?? member.since,
      opens: seat && !beside ? "pane" : "panel",
    };
  });
}

/** The thread of a terminal, whatever project is on show. Undefined for a terminal that is no thread. */
export function threadAt(snapshot: Snapshot, projects: readonly Project[], address: string | null): Thread | undefined {
  const owner = projects.find((project) => project.members.some((member) => member.address === address));
  return owner && projectThreads(snapshot, owner).find((thread) => thread.key === address);
}

/** The terminal a click on a project goes to: its orchestrator, else its first session, when that one has a pane. */
export function projectHome(snapshot: Snapshot, project: Project): string | null {
  const seated = seats(snapshot);
  return project.members.find((member) => seated.has(member.address))?.address ?? null;
}

/** Where a project's sessions are, for ending it. */
export interface Footprint {
  /**
   * The space that is the project's own: its orchestrator leads a tab there, and
   * every tab there is led by one of the project's sessions. Closing it ends
   * those sessions and nothing else.
   */
  readonly space: string | null;
  /** The addresses of its sessions that are not in that space. */
  readonly outside: readonly string[];
}

export function projectFootprint(snapshot: Snapshot, project: Project): Footprint {
  const seated = seats(snapshot);
  const lead = leadOf(project);
  const home = lead ? seated.get(lead.address)?.home?.space : null;
  const owned = new Set(project.members.map((member) => seated.get(member.address)?.home?.tab.id));
  const space = home?.tabs.every((tab) => owned.has(tab.id)) ? home.id : null;
  const inside = (address: string) => space !== null && seated.get(address)?.home?.space.id === space;
  const outside = project.members.map((member) => member.address).filter((address) => !inside(address));
  return { space, outside };
}

/** The groups that have threads, in the order a person acts on them. */
export function groupThreads(threads: readonly Thread[]): ThreadGroup[] {
  return GROUPS.map((group) => ({
    ...group,
    threads: threads.filter((thread) => groupOf(thread.status, thread.resolved) === group.id),
  })).filter((group) => group.threads.length > 0);
}

/** Agent addresses in the order the list shows them; agents the list leaves out keep their order after. */
export function agentOrder(agents: readonly AgentInfo[], shown: readonly Thread[]): string[] {
  const place = new Map(shown.map((thread, index) => [thread.key, index]));
  const rank = (agent: AgentInfo) => place.get(agent.address) ?? Number.POSITIVE_INFINITY;
  return [...agents].sort((a, b) => rank(a) - rank(b)).map((agent) => agent.address);
}
