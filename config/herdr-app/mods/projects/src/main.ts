// The `projects` mod: the project list, the thread panel and their dialogs.
// A layout block or an overlay picks one of them with `props.part`.

import { View, div, type AsyncContext, type Context, type Element } from "gpui-kit";
import { props } from "herdr";
import { asRecord, text } from "./parse";
import { NewProjectDialog } from "./parts/new-project";
import { panelTabs } from "./parts/panel-tabs";
import type { Part } from "./parts/part";
import { ProjectList } from "./parts/project-list";
import { projectMenu } from "./parts/project-menu";
import { RenameProjectDialog } from "./parts/rename-project";
import { threadHead } from "./parts/thread-head";
import { ThreadPanel } from "./parts/thread-panel";
import { topBar } from "./parts/top-bar";

/** What a layout block or an overlay gave this copy of the mod. */
interface Given {
  readonly part: string;
  /** The overlay to close, for a part that is one. */
  readonly overlay: string | null;
  /** The project a menu or a dialog is about. */
  readonly project: string | null;
}

type Factory = (given: Given, cx: AsyncContext) => Part;

/** The part of a copy that names none, as `herdr-app check` loads the mod. A name that is wrong still fails. */
const MAIN = "projects";

function readGiven(): Given {
  const given = asRecord(props());
  return { part: text(given.part) ?? MAIN, overlay: text(given.overlay), project: text(given.project) };
}

/** A part that needs something the layout or the opener did not give. */
function need<T>(value: T | null, what: string): T {
  if (value === null) throw new Error(`the projects mod needs ${what} for this part`);
  return value;
}

const PARTS: Readonly<Record<string, Factory>> = {
  top: () => topBar,
  projects: () => new ProjectList(),
  tabs: () => panelTabs,
  threads: (_given, cx) => new ThreadPanel(cx),
  "thread-head": () => threadHead,
  "new-project": (given, cx) => new NewProjectDialog(need(given.overlay, "its overlay"), cx),
  "rename-project": (given, cx) =>
    new RenameProjectDialog(need(given.overlay, "its overlay"), need(given.project, "a project"), cx),
  "project-menu": (given) => projectMenu(need(given.overlay, "its overlay"), need(given.project, "a project")),
};

function createPart(given: Given, cx: AsyncContext): Part {
  const factory = PARTS[given.part];
  if (!factory) throw new Error(`the projects mod has no part "${given.part}"`);
  return factory(given, cx);
}

export default class Projects extends View {
  private part: Part | undefined;

  override init(_props: unknown, cx: AsyncContext): void {
    this.part = createPart(readGiven(), cx);
  }

  render(cx: Context): Element {
    return this.part?.render(cx) ?? div();
  }
}
