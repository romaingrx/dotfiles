import { appHome, exec, hc, notify, openOverlay, run, type ExecResult } from "herdr";
import { leadOf, type Project } from "./projects";
import type { OwnTab, Thread } from "./threads";

const MOD = "projects";
/** Every label this setup puts on a terminal. */
const LABELS = ["project", "role", "task", "title", "state", "report", "report-turn", "handled", "resolved"];
const MEMORY = ".claude/projects-memory";
/** The launcher checks the machine, copies its scripts there and starts Claude: give it time on a slow line. */
const START_TIMEOUT = 180_000;
/** Moves a project's memory folder `$2` to `$3` under `$HOME/$1`. It fails when `$3` is there already. */
const MOVE_MEMORY = `cd "$HOME/$1" 2>/dev/null || exit 0
[ -d "$2" ] || exit 0
if [ -e "$3" ]; then echo "a memory folder named $3 exists already: remove it or pick another name" >&2; exit 1; fi
mv -- "$2" "$3"`;

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export function reportFailure(title: string, error: unknown): void {
  notify({ title, body: messageOf(error), level: "error" });
}

/** Fails on a non-zero exit, with what the program wrote. */
function succeed(result: ExecResult, program: string): void {
  if (result.code !== 0) throw new Error(result.stderr.trim() || `${program} ended with code ${result.code}`);
}

async function core(args: string[]): Promise<void> {
  succeed(await hc(args), `hc ${args[0]}`);
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

/**
 * Puts a thread away, or brings it back. The `resolved` label on its terminal
 * is the one record: the orchestrator sets the same label, and `threads.sh`
 * reads it.
 */
export function setResolved(thread: Thread, resolved: boolean): void {
  core(["label", thread.key, `resolved=${resolved ? "true" : ""}`]).catch((error: unknown) =>
    reportFailure("Could not change the thread", error),
  );
}

export function openNewProjectDialog(): void {
  openOverlay({ mod: MOD, kind: "dialog", width: 440, props: { part: "new-project" } });
}

export function openRenameProjectDialog(project: string): void {
  openOverlay({ mod: MOD, kind: "dialog", width: 420, props: { part: "rename-project", project } });
}

export function openProjectMenu(project: string): void {
  openOverlay({ mod: MOD, kind: "popup", width: 220, height: 72, props: { part: "project-menu", project } });
}

/** Starts the project's orchestrator in a space of its own. `machine` is null for this computer. */
export async function startProject(name: string, machine: string | null, cwd: string): Promise<void> {
  const args = ["orchestrator", name, "--cwd", cwd, ...(machine ? ["--on", machine] : [])];
  succeed(await exec(`${appHome()}/mods/${MOD}/agent/start.sh`, args, { timeout: START_TIMEOUT }), "start.sh");
}

/** Gives the project another name: its sessions' label, its memory folder, and a word to its orchestrator. */
export async function renameProject(project: Project, name: string): Promise<void> {
  // The memory moves first: a folder of the new name that is already there stops the rename.
  const moves = await Promise.all(
    project.machines.map((on) => exec("sh", ["-c", MOVE_MEMORY, "sh", MEMORY, project.name, name], { on })),
  );
  for (const move of moves) succeed(move, "the move of the memory folder");
  await Promise.all(project.members.map((member) => core(["label", member.address, `project=${name}`])));
  const lead = leadOf(project);
  if (lead) await core(["send", lead.address, `The person renamed this project to "${name}". Its memory folder has that name now.`]);
}

/**
 * Ends a project, once the person confirmed it. Its own space is closed, which
 * ends the sessions there. `outside` are its sessions elsewhere: they lose
 * their labels and keep running.
 */
export async function deleteProject(ownSpace: string | null, outside: readonly string[]): Promise<void> {
  if (ownSpace) run("space.close", { id: ownSpace, confirmed: true });
  const cleared = LABELS.map((label) => `${label}=`);
  await Promise.all(outside.map((address) => core(["label", address, ...cleared])));
}
