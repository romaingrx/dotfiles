import type { Status } from "herdr";
import { asRecord, text, type Raw } from "./parse";
import { parseDeclared } from "./pulls";
import { parseReported, parseStatus, type Reported } from "./status";

/** A live core terminal, with the fields this mod reads. */
export interface Terminal {
  readonly address: string;
  readonly machine: string | null;
  readonly name: string | null;
  /** What the program wrote as the terminal's title. */
  readonly title: string;
  readonly status: Status | null;
  readonly activity: string | null;
  /** When its status last changed, in ms since the epoch. */
  readonly since: number | null;
  readonly agent: boolean;
  readonly project: string | null;
  readonly role: string | null;
  /** The thread's name for the person: its `title` label, else its `task` label. */
  readonly heading: string | null;
  readonly reported: Reported | null;
  /** Put away by the person or the orchestrator. */
  readonly resolved: boolean;
  /** The URLs of the pull requests its thread declared, from its `pulls` label. */
  readonly declared: readonly string[];
}

/**
 * What the thread last reported, while that report is about its current turn.
 * `report.sh` stores the turn it ran in: once the person answers, the agent
 * is in a later turn and the report is behind it.
 */
function currentReport(labels: Raw, turn: unknown): Reported | null {
  return String(labels["report-turn"]) === String(turn) ? parseReported(labels.state) : null;
}

/** `vps/t7` runs on `vps`; a bare `t7` runs on this computer. */
export function machineOf(address: string): string | null {
  const slash = address.indexOf("/");
  return slash < 0 ? null : address.slice(0, slash);
}

/** Null for a terminal that ended or has no address. */
export function parseTerminal(raw: Raw): Terminal | null {
  const address = text(raw.address);
  if (!address || raw.state !== "live") return null;
  const labels = asRecord(raw.labels);
  return {
    address,
    machine: machineOf(address),
    name: text(raw.name),
    title: text(raw.title) ?? "",
    status: parseStatus(raw.status),
    activity: text(asRecord(raw.report).msg),
    since: typeof raw.status_ms === "number" ? raw.status_ms : null,
    agent: asRecord(raw.program).agent === true,
    project: text(labels.project),
    role: text(labels.role),
    heading: text(labels.title) ?? text(labels.task),
    reported: currentReport(labels, raw.turn),
    resolved: labels.resolved === "true",
    declared: parseDeclared(labels.pulls),
  };
}
