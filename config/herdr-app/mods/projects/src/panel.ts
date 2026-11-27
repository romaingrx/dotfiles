import { appHome, layout, run, setShared, shared } from "herdr";
import { readText, runCommand } from "./host";
import {
  findNode,
  PANEL,
  PANEL_STACK,
  THREAD,
  THREAD_DRAWER,
  THREAD_TERMINAL,
  withThread,
  type Drawer,
  type LayoutNode,
} from "./layout-tree";
import { isRecord, parseJson } from "./parse";
import { DONE, fail, ok, type Outcome, type Result } from "./result";

/** What the right panel of the `projects` layout can show, by the id of its block. */
export type Panel = "threads" | "files" | "changes" | typeof THREAD;

const LAYOUT = "projects";
/** The layout's tree as the mod ships it. The app's copy, `layouts/projects.json`, is made from it. */
const BASE = "mods/projects/layout.json";
/** The base the app's copy was last made from, to see when the base changed. */
const APPLIED = "projects.layout";

export interface PanelState {
  readonly hidden: boolean;
  /** The block the panel shows, also while it is hidden. */
  readonly active: string | null;
  /** The terminal of the open thread, if one is open. */
  readonly thread: string | null;
  /** What the drawer under the open thread shows, or null while it is closed. */
  readonly drawer: string | null;
}

/** A layout tree is an object; what its nodes hold is read field by field. */
function asNode(value: unknown): LayoutNode | undefined {
  return isRecord(value) ? (value as LayoutNode) : undefined;
}

/** The app's copy of this mod's layout, while it is the layout on show. */
function shownLayout(): LayoutNode | undefined {
  return shared("layout") === LAYOUT ? asNode(layout()) : undefined;
}

/** A node is on show unless it says otherwise; one the layout does not have is not. */
function isHidden(node: LayoutNode | undefined): boolean {
  return node === undefined || node.hidden === true;
}

function shownDrawer(drawer: LayoutNode | undefined): string | null {
  return isHidden(drawer) ? null : (drawer?.active ?? null);
}

export function readPanel(): PanelState {
  const root = shownLayout();
  return {
    hidden: isHidden(findNode(root, PANEL)),
    active: findNode(root, PANEL_STACK)?.active ?? null,
    thread: findNode(root, THREAD_TERMINAL)?.content?.terminal ?? null,
    drawer: shownDrawer(findNode(root, THREAD_DRAWER)),
  };
}

export function selectPanel(panel: Panel): void {
  run("layout.select", { stack: PANEL_STACK, child: panel });
}

export function togglePanel(): void {
  run("layout.toggle", { id: PANEL });
}

/** Opens the drawer under the open thread on one of its panels, or closes it when that panel shows. */
export function toggleDrawer(drawer: Drawer): void {
  if (readPanel().drawer === drawer) {
    run("layout.hide", { id: THREAD_DRAWER });
    return;
  }
  run("layout.select", { stack: THREAD_DRAWER, child: drawer });
  run("layout.show", { id: THREAD_DRAWER });
}

/** Replaces the shown layout by `tree`, with the panel holding the thread of `thread`. */
function setLayout(tree: LayoutNode, thread: string | null): Outcome {
  return runCommand("layout.set", { layout: withThread(tree, thread) });
}

/**
 * Opens a thread's terminal in the panel, in place of the thread list. The
 * rest of the layout stays as the person left it. With `focus`, the keyboard
 * goes to the thread: a terminal that was never shown takes the size of its
 * block only once it has the focus.
 */
export function showThreadInPanel(terminal: string, focus: boolean): Outcome {
  const shown = shownLayout();
  if (!shown) return DONE;
  const set = setLayout(shown, terminal);
  if (!set.ok) return set;
  selectPanel(THREAD);
  return focus ? runCommand("pane.focus", { terminal }) : DONE;
}

/** The tree that the text of the mod's layout file holds. */
function parseBase(base: string): Result<LayoutNode> {
  const read = parseJson(base);
  if (!read.ok) return read;
  const tree = asNode(read.value);
  return tree ? ok(tree) : fail(`${BASE} does not hold a layout`);
}

/** Makes the app's copy of the layout again when the base changed, keeping the open thread. */
export async function syncLayout(): Promise<Outcome> {
  const base = await readText(`${appHome()}/${BASE}`);
  if (!base.ok) return base;
  if (base.value === null) return fail(`${BASE} is missing`);
  if (shared(APPLIED) === base.value || !shownLayout()) return DONE;
  const tree = parseBase(base.value);
  if (!tree.ok) return tree;
  const set = setLayout(tree.value, readPanel().thread);
  if (set.ok) setShared(APPLIED, base.value);
  return set;
}
