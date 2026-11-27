import { appHome, notify, openOverlay, window } from "herdr";
import { core, runCommand, runProgram } from "./host";
import { leadOf, type Project } from "./projects";
import { all, DONE, settle, type Outcome } from "./result";
import type { OwnTab, Thread } from "./threads";

const MOD = "projects";
/** Every label this setup puts on a terminal. */
const LABELS = ["project", "role", "task", "title", "state", "report", "report-turn", "handled", "resolved", "pulls"];
const MEMORY = ".claude/projects-memory";
/** The launcher checks the machine, copies its scripts there and starts Claude: give it time on a slow line. */
const START_TIMEOUT = 180_000;
/** Moves a project's memory folder `$2` to `$3` under `$HOME/$1`. It fails when `$3` is there already. */
const MOVE_MEMORY = `cd "$HOME/$1" 2>/dev/null || exit 0
[ -d "$2" ] || exit 0
if [ -e "$3" ]; then echo "a memory folder named $3 exists already: remove it or pick another name" >&2; exit 1; fi
mv -- "$2" "$3"`;

/** Tells the person of a failure, with a notice. A step that worked says nothing. */
export function reportFailure(title: string, outcome: Outcome): void {
  if (!outcome.ok) notify({ title, body: outcome.error, level: "error" });
}

/** Tells the person when work that goes on behind what they see fails. */
export function reportFailureOf(title: string, work: () => Promise<Outcome>): void {
  void settle(work).then((outcome) => reportFailure(title, outcome));
}

/** Herdr's own rename dialog, for a name that Herdr holds. */
function askName(title: string, value: string, command: string, args: Readonly<Record<string, string>>): void {
  openOverlay({ mod: "prompt", kind: "dialog", width: 420, props: { title, value, command: { name: command, args } } });
}

/** A thread is renamed where Herdr keeps its name: on the tab it owns, else on its pane. One without a pane has neither. */
export function canRename(thread: Thread): boolean {
  return thread.pane !== null;
}

export function renameThread(thread: Thread): void {
  if (thread.tab) askName("Rename thread", thread.title, "tab.rename", { id: thread.tab.id });
  else if (thread.pane) askName("Rename thread", thread.title, "pane.rename", { pane: thread.pane });
}

/** Herdr's own menu of a tab: rename, close. */
export function openThreadMenu(tab: OwnTab): void {
  openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: tab } });
}

/** Sets labels on a terminal: `name=value` each, and `name=` to remove one. */
function label(address: string, labels: readonly string[]): Promise<Outcome> {
  return core(["label", address, ...labels]);
}

/**
 * Puts a thread away, or brings it back. The `resolved` label on its terminal
 * is the one record: the orchestrator sets the same label, and `threads.sh`
 * reads it.
 */
export function setResolved(thread: Thread, resolved: boolean): void {
  reportFailureOf("Could not change the thread", () => label(thread.key, [`resolved=${resolved ? "true" : ""}`]));
}

export function openNewProjectDialog(): void {
  openOverlay({ mod: MOD, kind: "dialog", width: 440, props: { part: "new-project" } });
}

export function openRenameProjectDialog(project: string): void {
  openOverlay({ mod: MOD, kind: "dialog", width: 420, props: { part: "rename-project", project } });
}

export function openProjectMenu(project: string): void {
  openOverlay({ mod: MOD, kind: "popup", width: 220, height: 103, props: { part: "project-menu", project } });
}

/** Opens the review of a thread's branch, over most of the window. A click beside it does not close it. */
export function openReview(thread: string): void {
  openOverlay({ mod: MOD, kind: "dialog", modal: true, width: 0.92, height: 0.9, props: { part: "review", thread } });
}

/** Types a message into a thread's terminal and sends it. */
export function sendToThread(thread: string, message: string): Promise<Outcome> {
  return core(["send", thread, message]);
}

/** Starts the project's orchestrator in a space of its own. `machine` is null for this computer. */
export function startProject(name: string, machine: string | null, cwd: string): Promise<Outcome> {
  const args = ["orchestrator", name, "--cwd", cwd, ...(machine ? ["--on", machine] : [])];
  return runProgram(`${appHome()}/mods/${MOD}/agent/start.sh`, args, { timeout: START_TIMEOUT, name: "start.sh" });
}

/** Moves a project's memory folder on one machine to the folder of its new name. */
function moveMemory(on: string | null, from: string, to: string): Promise<Outcome> {
  const args = ["-c", MOVE_MEMORY, "sh", MEMORY, from, to];
  return runProgram("sh", args, { on, name: "the move of the memory folder" });
}

/** Gives the project another name: its sessions' label, its memory folder, and a word to its orchestrator. */
export async function renameProject(project: Project, name: string): Promise<Outcome> {
  // The memory moves first: a folder of the new name that is already there stops the rename.
  const moved = await all(project.machines.map((on) => moveMemory(on, project.name, name)));
  if (!moved.ok) return moved;
  const labelled = await all(project.members.map((member) => label(member.address, [`project=${name}`])));
  if (!labelled.ok) return labelled;
  const lead = leadOf(project);
  if (!lead) return DONE;
  return sendToThread(
    lead.address,
    `The person renamed this project to "${name}". Its memory folder has that name now.`,
  );
}

/**
 * Ends a project, once the person confirmed it: every session of it stops.
 * Its own space is closed, which ends the sessions there. `outside` are its
 * sessions elsewhere, which are ended one by one. Its memory folder stays.
 */
export async function closeProject(ownSpace: string | null, outside: readonly string[]): Promise<Outcome> {
  const closed = ownSpace ? runCommand("space.close", { id: ownSpace, confirmed: true }) : DONE;
  if (!closed.ok) return closed;
  return all(outside.map((address) => core(["kill", address])));
}

/** Takes a project apart and leaves its sessions running: they lose the labels of this setup. */
export function ungroupProject(project: Project): Promise<Outcome> {
  const cleared = LABELS.map((name) => `${name}=`);
  return all(project.members.map((member) => label(member.address, cleared)));
}

/** Opens a web page in the person's browser. */
export function openLink(url: string): void {
  const opener = window()?.platform === "macos" ? "open" : "xdg-open";
  reportFailureOf("Could not open the link", () => runProgram(opener, [url]));
}
