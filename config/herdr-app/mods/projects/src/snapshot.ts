import { agents, focused, panes, shared, spaces, terminals } from "herdr";
import type { Status } from "herdr";
import { parseOrder } from "./projects";
import { buildScene, type Scene } from "./scene";
import { withReport } from "./status";
import { parseTerminal, type Terminal } from "./terminal";
import type { Snapshot } from "./threads";
import { parseViews, type Views } from "./views";

/** The shared keys of what the person chose: the projects' order, and each project's open thread. */
export const ORDER = "projects.order";
export const VIEWS = "projects.views";

function isPresent<T>(value: T | null): value is T {
  return value !== null;
}

/**
 * The status to show. The app's status wins over the core's raw word for an
 * agent it lists: it turns "done" into "idle" once the person has looked. Then
 * the thread's own report counts, for a thread that asked for the person.
 */
function shownStatus(terminal: Terminal, listed: ReadonlyMap<string, Status>): Terminal {
  const status = withReport(listed.get(terminal.address) ?? terminal.status, terminal.reported);
  return status === terminal.status ? terminal : { ...terminal, status };
}

export function readSnapshot(): Snapshot {
  const listed = agents();
  const statuses = new Map(listed.map((agent) => [agent.address, agent.status]));
  return {
    spaces: spaces(),
    panes: panes(),
    agents: listed,
    terminals: terminals()
      .map(parseTerminal)
      .filter(isPresent)
      .map((terminal) => shownStatus(terminal, statuses)),
    focused: focused()?.terminal ?? null,
  };
}

export function readViews(): Views {
  return parseViews(shared(VIEWS));
}

export function readScene(): Scene {
  return buildScene(readSnapshot(), parseOrder(shared(ORDER)));
}
