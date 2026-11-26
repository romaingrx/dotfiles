import type { ReviewFile } from "./rows";

/** One row of the file tree: a folder, or a file of the review. */
export type TreeRow =
  | {
      readonly kind: "folder";
      /** The folder's whole path: what a fold is kept by. */
      readonly path: string;
      /** What the row shows: its own name, with the folders it is the only child of before it. */
      readonly name: string;
      readonly depth: number;
      readonly open: boolean;
    }
  | { readonly kind: "file"; readonly name: string; readonly depth: number; readonly entry: ReviewFile };

/** A folder while the tree is built. */
interface Folder {
  readonly path: string;
  readonly name: string;
  readonly folders: Map<string, Folder>;
  readonly files: { readonly name: string; readonly entry: ReviewFile }[];
}

function folder(path: string, name: string): Folder {
  return { path, name, folders: new Map(), files: [] };
}

/** Puts a file in the folder its path names, and makes the folders on the way. */
function place(root: Folder, entry: ReviewFile): void {
  const parts = entry.file.path.split("/");
  const name = parts.pop() ?? entry.file.path;
  let at = root;
  for (const part of parts) {
    const path = at.path ? `${at.path}/${part}` : part;
    const below = at.folders.get(part) ?? folder(path, part);
    at.folders.set(part, below);
    at = below;
  }
  at.files.push({ name, entry });
}

/** A folder that holds one folder and no file is shown with it, as `a/b`: a deep path takes one row. */
function joined(node: Folder): Folder {
  const [only] = node.folders.values();
  if (!only || node.folders.size > 1 || node.files.length > 0) return node;
  return joined({ ...only, name: `${node.name}/${only.name}` });
}

function rowsOf(node: Folder, depth: number, folded: ReadonlySet<string>): TreeRow[] {
  const folders = [...node.folders.values()].map(joined).sort((a, b) => a.name.localeCompare(b.name));
  const below = folders.flatMap((child): TreeRow[] => {
    const open = !folded.has(child.path);
    const head: TreeRow = { kind: "folder", path: child.path, name: child.name, depth, open };
    return open ? [head, ...rowsOf(child, depth + 1, folded)] : [head];
  });
  const files = node.files.map(({ name, entry }): TreeRow => ({ kind: "file", name, depth, entry }));
  return [...below, ...files];
}

/**
 * The files of a review as a tree: the folders of a folder first, then its
 * files, in the order they came in. A folded folder shows no row under it.
 */
export function fileTree(files: readonly ReviewFile[], folded: ReadonlySet<string>): TreeRow[] {
  const root = folder("", "");
  for (const entry of files) place(root, entry);
  return rowsOf(root, 0, folded);
}

/** The files whose path has what the person typed in the filter, in any case. All of them for no word. */
export function filterFiles(files: readonly ReviewFile[], typed: string): ReviewFile[] {
  const word = typed.trim().toLowerCase();
  return files.filter((entry) => entry.file.path.toLowerCase().includes(word));
}

/**
 * The files in the order the tree lists them from the top, whatever is folded.
 * The diff shows them in this order, so that the tree and the diff read alike.
 */
export function inTreeOrder(files: readonly ReviewFile[]): ReviewFile[] {
  return fileTree(files, new Set()).flatMap((row) => (row.kind === "file" ? [row.entry] : []));
}
