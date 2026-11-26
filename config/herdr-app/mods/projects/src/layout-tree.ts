/** A node of a layout file, with the fields this mod reads or sets. */
export interface LayoutNode {
  readonly id?: string;
  readonly type?: string;
  readonly hidden?: boolean;
  readonly active?: string;
  readonly content?: { readonly terminal?: string; readonly [field: string]: unknown };
  readonly children?: readonly LayoutNode[];
  readonly [field: string]: unknown;
}

/**
 * How deep an argument of an app command may nest when a mod sends it: Herdr
 * refuses more. `layout.set` takes the whole tree, so the tree must stay flat.
 */
export const HOST_NESTING_LIMIT = 16;

/** How many objects and arrays lie on the deepest path of a value. */
export function nesting(value: unknown): number {
  if (typeof value !== "object" || value === null) return 0;
  return 1 + Math.max(0, ...Object.values(value).map(nesting));
}

export const PANEL = "panel";
export const PANEL_STACK = "panel-body";
/** The child of the panel's stack that shows one thread: a header over its terminal. */
export const THREAD = "thread";
export const THREAD_TERMINAL = "thread-terminal";
/** The drawer under an open thread: Herdr's Files and Changes, which show the folder of the focused terminal. */
export const THREAD_DRAWER = "thread-drawer";
export type Drawer = "thread-files" | "thread-changes";
const THREAD_HEAD_HEIGHT = 36;

export function findNode(node: LayoutNode | undefined, id: string): LayoutNode | undefined {
  if (!node || node.id === id) return node;
  for (const child of node.children ?? []) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return undefined;
}

function threadView(terminal: string): LayoutNode {
  return {
    id: THREAD,
    type: "column",
    resizable: false,
    children: [
      {
        id: "thread-head",
        type: "block",
        size: { px: THREAD_HEAD_HEIGHT },
        content: { mod: "projects", props: { part: "thread-head" } },
      },
      { id: THREAD_TERMINAL, type: "block", size: { weight: 3 }, content: { terminal } },
      {
        id: THREAD_DRAWER,
        type: "stack",
        size: { weight: 2 },
        hidden: true,
        active: "thread-files",
        children: [
          { id: "thread-files", type: "block", content: { mod: "files" } },
          { id: "thread-changes", type: "block", content: { mod: "changes" } },
        ],
      },
    ],
  };
}

/**
 * The layout with the panel showing the thread of `terminal`, or without a
 * thread view for null. A layout file names the terminal of a block, so the tree
 * itself changes when another thread opens.
 */
export function withThread(node: LayoutNode, terminal: string | null): LayoutNode {
  if (!node.children) return node;
  const children = node.children.filter((child) => child.id !== THREAD).map((child) => withThread(child, terminal));
  if (node.id !== PANEL_STACK || terminal === null) return { ...node, children };
  return { ...node, children: [...children, threadView(terminal)] };
}
