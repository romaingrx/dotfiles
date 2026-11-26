import type { DiffFile, DiffLine } from "./diff";
import { anchorKey, anchorOf, type Anchor, type Comment, type Span } from "./draft";

/** A file of the review: one the branch changed, with the comments on it. */
export interface ReviewFile {
  readonly file: DiffFile;
  readonly comments: readonly Comment[];
  /** Set for a file that has comments and is no longer in the diff. */
  readonly gone: boolean;
}

/** One row of a file's diff, as the list draws it. */
export type Row =
  | { readonly kind: "hunk"; readonly key: string; readonly text: string }
  | { readonly kind: "note"; readonly key: string; readonly text: string }
  | {
      readonly kind: "line";
      readonly key: string;
      readonly anchor: Anchor;
      readonly line: DiffLine;
      readonly text: string;
      readonly commented: boolean;
    }
  | {
      readonly kind: "comment";
      readonly key: string;
      readonly anchor: Anchor;
      /** The comment's words, cut into the lines the row shows. */
      readonly lines: readonly string[];
      /** Set for a comment on a line that is no longer in the diff. */
      readonly stale: boolean;
    };

/** How many lines of one file's diff are drawn. */
export const MAX_LINES = 5000;
const TAB = 4;

/** Text draws a tab as nothing: each one is padded to the next tab stop. */
export function untab(text: string): string {
  return text.replace(/[^\t]*\t/g, (run) => {
    const width = run.length - 1;
    return run.slice(0, -1).padEnd(width - (width % TAB) + TAB);
  });
}

/** Cuts one line of text into lines of `columns` characters at most, between words where it can. */
function wrapLine(line: string, columns: number): string[] {
  const lines: string[] = [];
  let rest = line;
  while (rest.length > columns) {
    const space = rest.lastIndexOf(" ", columns);
    const cut = space > 0 ? space : columns;
    lines.push(rest.slice(0, cut));
    rest = rest.slice(cut).trimStart();
  }
  return [...lines, rest];
}

/** Cuts a text into the lines that fit `columns` characters. The text's own line breaks stay. */
export function wrap(text: string, columns: number): string[] {
  const width = Math.max(1, Math.floor(columns));
  return text.split("\n").flatMap((line) => wrapLine(untab(line), width));
}

function gone(path: string): DiffFile {
  return { path, from: null, change: "modified", binary: false, hunks: [], added: 0, removed: 0 };
}

/** The files of the review: those of the diff, then those that only have comments left. */
export function reviewFiles(files: readonly DiffFile[], comments: readonly Comment[]): ReviewFile[] {
  const on = (path: string) => comments.filter((comment) => comment.path === path);
  const changed = new Set(files.map((file) => file.path));
  const left = [...new Set(comments.map((comment) => comment.path))].filter((path) => !changed.has(path));
  return [
    ...files.map((file) => ({ file, comments: on(file.path), gone: false })),
    ...left.map((path) => ({ file: gone(path), comments: on(path), gone: true })),
  ];
}

/** The key of the row of a line. */
export function lineKey(anchor: Anchor): string {
  return `line:${anchorKey(anchor)}`;
}

function commentRow(comment: Comment, columns: number, stale: boolean): Row {
  const where = stale ? `Line ${comment.line}, which is no longer in the diff:\n` : "";
  return {
    kind: "comment",
    key: `comment:${anchorKey(comment)}`,
    anchor: comment,
    lines: wrap(where + comment.body, columns),
    stale,
  };
}

/** What stands in place of the lines of a file that has none to show. */
function emptyText(entry: ReviewFile): string | null {
  if (entry.gone) return "This file is no longer in the diff.";
  if (entry.file.binary) return "A binary file: it has no text to show.";
  return entry.file.hunks.length === 0 ? "No line of this file changed." : null;
}

/**
 * The rows of one file: each hunk's header and lines, with a comment under its
 * line. A comment whose line the diff no longer has comes first. `columns` is
 * how many characters of a comment fit on one line.
 */
export function fileRows(entry: ReviewFile, columns: number): Row[] {
  const { file, comments } = entry;
  const byLine = new Map(comments.map((comment) => [anchorKey(comment), comment]));
  const lines = file.hunks.flatMap((hunk) => hunk.lines);
  const shown = new Set(lines.map((line) => anchorKey(anchorOf(file.path, line))));
  const stale = comments.filter((comment) => !shown.has(anchorKey(comment)));
  const rows: Row[] = stale.map((comment) => commentRow(comment, columns, true));
  const empty = emptyText(entry);
  if (empty) return [...rows, { kind: "note", key: "note:empty", text: empty }];
  let drawn = 0;
  for (const [index, hunk] of file.hunks.entries()) {
    if (drawn >= MAX_LINES) break;
    rows.push({ kind: "hunk", key: `hunk:${index}`, text: hunk.header });
    for (const line of hunk.lines.slice(0, MAX_LINES - drawn)) {
      const anchor = anchorOf(file.path, line);
      const comment = byLine.get(anchorKey(anchor));
      rows.push({
        kind: "line",
        key: lineKey(anchor),
        anchor,
        line,
        text: untab(line.text),
        commented: Boolean(comment),
      });
      if (comment) rows.push(commentRow(comment, columns, false));
    }
    drawn += hunk.lines.length;
  }
  if (lines.length > MAX_LINES) {
    rows.push({ kind: "note", key: "note:cut", text: `This diff is long: only its first ${MAX_LINES} lines show.` });
  }
  // A comment on several lines marks each of them, not only the last one.
  const covered = new Set(comments.flatMap((comment) => spanRows(rows, comment).map((row) => row.key)));
  return rows.map((row) => (row.kind === "line" && covered.has(row.key) ? { ...row, commented: true } : row));
}

export type LineRow = Extract<Row, { kind: "line" }>;

function lineRows(rows: readonly Row[]): LineRow[] {
  return rows.filter((row) => row.kind === "line");
}

/**
 * The lines a span covers, from its first one to its last one as the diff
 * lists them. A span whose first line the diff does not show covers its last
 * line; one whose last line is not shown covers none.
 */
export function spanRows(rows: readonly Row[], span: Span): LineRow[] {
  const lines = lineRows(rows);
  const last = lines.findIndex((row) => row.key === lineKey(span));
  if (last < 0) return [];
  const from = span.start ? lineKey({ path: span.path, ...span.start }) : null;
  const first = lines.findIndex((row) => row.key === from);
  return lines.slice(first < 0 || first > last ? last : first, last + 1);
}

/** The span from one line of a file to another one, whichever the diff lists first. */
export function spanBetween(rows: readonly Row[], a: Anchor, b: Anchor): Span {
  const lines = lineRows(rows);
  const at = (anchor: Anchor) => lines.findIndex((row) => row.key === lineKey(anchor));
  const [first, last] = at(a) <= at(b) ? [a, b] : [b, a];
  const start = anchorKey(first) === anchorKey(last) ? null : { side: first.side, line: first.line };
  return { path: last.path, side: last.side, line: last.line, start };
}

/** How many lines of a span are quoted to the thread. */
const MAX_QUOTE = 12;

/** The text of some lines, as a comment on them quotes it: the first ones of a long span. */
export function quoteOf(lines: readonly LineRow[]): string {
  const texts = lines.slice(0, MAX_QUOTE).map((row) => row.line.text);
  return [...texts, ...(lines.length > MAX_QUOTE ? ["…"] : [])].join("\n");
}

/** The longest line of the rows, in characters: how wide the diff is. */
export function widest(rows: readonly Row[]): number {
  return Math.max(0, ...rows.map((row) => (row.kind === "line" || row.kind === "hunk" ? row.text.length : 0)));
}
