import { anchorKey } from "./draft";
import { fileKey, type ReviewFile, type Row } from "./rows";

/** The rows of one file, with what they were built from. */
export interface Built {
  readonly signature: string;
  readonly rows: readonly Row[];
}

/** The rows of the files that are built so far, by the file's path. */
export type BuiltFiles = ReadonlyMap<string, Built>;

/**
 * What a file's rows are built from, as one word: the read of the diff they
 * are of (`round`), what is said about the file, and the width its cards are
 * cut to. A file without a card is the same at any width, so a change of the
 * width builds only the files that have one.
 */
export function builtFrom(entry: ReviewFile, columns: number, round: number): string {
  const said = entry.comments.map(
    (comment) => `${anchorKey(comment)} ${comment.start?.line} ${comment.about?.post} ${comment.body}`,
  );
  const cards = said.length + entry.discussions.length > 0;
  return JSON.stringify([round, cards ? columns : null, said, entry.discussions.length]);
}

/** The files whose rows are not built yet, or were built from something that changed since. */
export function staleFiles(
  files: readonly ReviewFile[],
  built: BuiltFiles,
  columns: number,
  round: number,
): ReviewFile[] {
  return files.filter((entry) => built.get(entry.file.path)?.signature !== builtFrom(entry, columns, round));
}

/**
 * The rows of a whole review: each file's opening row, then the rows it has
 * so far. A file that is not built yet has its opening row only; one that is
 * built again keeps its old rows until the new ones are there.
 */
export function assemble(files: readonly ReviewFile[], built: BuiltFiles): Row[] {
  return files.flatMap((entry): Row[] => [
    { kind: "file", key: fileKey(entry.file.path), entry },
    ...(built.get(entry.file.path)?.rows ?? []),
  ]);
}

/** Where each row starts in the list, from the rows' heights. */
export function offsets(heights: readonly number[]): number[] {
  let top = 0;
  return heights.map((height) => {
    const start = top;
    top += height;
    return start;
  });
}

/** Where a file opens in the list. */
export interface FileStart {
  readonly path: string;
  readonly top: number;
}

/** Where each file of the list opens, from the top down. */
export function fileStarts(rows: readonly Row[], tops: readonly number[]): FileStart[] {
  return rows.flatMap((row, index) =>
    row.kind === "file" ? [{ path: row.entry.file.path, top: tops[index] ?? 0 }] : [],
  );
}

/**
 * The file that is on show when the list is scrolled down by `scrolled`: the
 * last one that opens at or over that point. The first file before any scroll;
 * null for a review without a file.
 */
export function fileAt(starts: readonly FileStart[], scrolled: number): string | null {
  const [first] = starts;
  if (!first) return null;
  const over = starts.filter((start) => start.top <= scrolled);
  return (over[over.length - 1] ?? first).path;
}

/**
 * The row to ask the list for, to bring the row `head` to its top. The list
 * moves a row only as far as it must to show it: to its top edge when the row
 * is over what is on screen, to its bottom edge when it is under it, and not
 * at all when it is on screen. So for a head that is not over the screen, ask
 * for the last row that fits in one screen from the head's top: that row comes
 * to the bottom edge, and the head to the top.
 */
export function rowToReveal(
  tops: readonly number[],
  heights: readonly number[],
  head: number,
  scrolled: number,
  screen: number,
): number {
  const top = tops[head] ?? 0;
  if (top <= scrolled) return head;
  const fits = (row: number): boolean => (tops[row] ?? 0) + (heights[row] ?? 0) <= top + screen;
  let last = head;
  while (last + 1 < tops.length && fits(last + 1)) last++;
  return last;
}
