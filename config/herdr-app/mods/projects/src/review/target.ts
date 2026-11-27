import { linesOf, type About, type Anchor, type Comment, type Span } from "./draft";
import { lineKey, type Row } from "./rows";

/** The lines the person writes a comment on. */
export interface Target {
  readonly anchor: Span;
  /** The line the person picked first: a Shift-click on another line makes a span from it. */
  readonly pivot: Anchor;
  /** The text of the lines. */
  readonly code: string;
  /** Set when the line has a comment already. */
  readonly written: boolean;
  /** The comment on GitHub that a comment on this line answers. */
  readonly about: About | null;
}

/** A row that a click opens a comment from: a line, or a card under one. */
export type Pickable = Extract<Row, { kind: "line" | "card" }>;

export function isPickable(row: Row | undefined): row is Pickable {
  return row?.kind === "line" || row?.kind === "card";
}

/** The text of a line of a file, from the file's rows: none for a line the diff does not show. */
function codeAt(rows: readonly Row[], anchor: Anchor): string {
  const row = rows.find((candidate) => candidate.key === lineKey(anchor));
  return row?.kind === "line" ? row.line.text : "";
}

/**
 * What a click on a line opens to write: the comment that ends on that line,
 * on the lines it was written on, else a new one on the line alone. `rows`
 * are the rows of the line's file.
 */
export function targetAt(
  rows: readonly Row[],
  anchor: Anchor,
  written: Comment | undefined,
  about: About | null,
): Target {
  if (written) return { anchor: written, pivot: anchor, code: written.code, written: true, about };
  const { path, side, line } = anchor;
  return {
    anchor: { path, side, line, start: null },
    pivot: anchor,
    code: codeAt(rows, anchor),
    written: false,
    about,
  };
}

function linesWord(span: Span): string {
  if (span.start) return `Lines ${linesOf(span)}`;
  return span.side === "old" ? `Line ${span.line}, which the branch removes` : `Line ${span.line}`;
}

/** Where a comment goes, in words. Several files are on show at once: the file's name says which one the lines are of. */
export function whereOf(target: Target): string {
  const { path } = target.anchor;
  const lines = `${path.slice(path.lastIndexOf("/") + 1)} · ${linesWord(target.anchor)}`;
  return target.about ? `${lines} · in answer to @${target.about.author} on GitHub` : lines;
}
