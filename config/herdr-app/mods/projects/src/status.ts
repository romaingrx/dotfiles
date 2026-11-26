import type { Status } from "herdr";

export type Group = "waiting" | "working" | "idle" | "resolved";

/** What a thread last told its orchestrator with `report.sh`. */
export type Reported = "done" | "needs-you";

export const GROUPS: readonly { readonly id: Group; readonly label: string }[] = [
  { id: "waiting", label: "Waiting on you" },
  { id: "working", label: "Working" },
  { id: "idle", label: "Idle" },
  { id: "resolved", label: "Resolved" },
];

const URGENCY: Readonly<Record<Status, number>> = { blocked: 3, done: 2, working: 1, idle: 0 };

function isStatus(word: unknown): word is Status {
  return typeof word === "string" && word in URGENCY;
}

/** Reads a status word from the core. An error needs the person, like a blocked agent. */
export function parseStatus(word: unknown): Status | null {
  if (word === "error") return "blocked";
  return isStatus(word) ? word : null;
}

export function parseReported(word: unknown): Reported | null {
  return word === "done" || word === "needs-you" ? word : null;
}

/**
 * A thread that asked for the person and ended its turn waits on them, though
 * its agent only says "done". Once it works again, its report is behind it.
 */
export function withReport(status: Status | null, reported: Reported | null): Status | null {
  return reported === "needs-you" && status !== "working" ? "blocked" : status;
}

export function mostUrgent(statuses: readonly (Status | null)[]): Status | null {
  let top: Status | null = null;
  for (const status of statuses) {
    if (status && (!top || URGENCY[status] > URGENCY[top])) top = status;
  }
  return top;
}

/** The status worth a mark on a project: idle says nothing there. */
export function attention(status: Status | null): Status | null {
  return status === "idle" ? null : status;
}

export function isBusy(status: Status | null): boolean {
  return status === "working" || status === "blocked";
}

export function groupOf(status: Status | null, resolved: boolean): Group {
  if (resolved) return "resolved";
  if (status === "blocked") return "waiting";
  if (status === "working") return "working";
  return "idle";
}
