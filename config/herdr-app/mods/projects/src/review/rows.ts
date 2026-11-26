import type { DiffFile, DiffLine } from "./diff";
import type { Discussion, Remark } from "./discussions";
import { anchorKey, anchorOf, linesOf, type Anchor, type Comment, type Posting, type Span } from "./draft";

/** A file of the review: one the branch changed, with what is said about it. */
export interface ReviewFile {
  readonly file: DiffFile;
  /** The person's comments, not sent yet. */
  readonly comments: readonly Comment[];
  /** The open discussions on GitHub. */
  readonly discussions: readonly Discussion[];
  /** Set for a file that is no longer in the diff, and still has comments or discussions. */
  readonly gone: boolean;
}

/** One line of a card. A head line names who speaks, or where. */
export interface CardLine {
  readonly text: string;
  readonly head: boolean;
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
      /** Set for a line that a comment of the person is on. */
      readonly commented: boolean;
      /** Set for a line that a discussion on GitHub is on. */
      readonly discussed: boolean;
    }
  | {
      /** A card under a line: the person's comment, or a discussion on GitHub. */
      readonly kind: "card";
      readonly key: string;
      readonly anchor: Anchor;
      readonly from: "draft" | "github";
      readonly lines: readonly CardLine[];
      /** Set for a card on a line that is not in the diff. */
      readonly stale: boolean;
    };

export type Card = Extract<Row, { kind: "card" }>;

/** How many lines of one file's diff are drawn. */
export const MAX_LINES = 5000;
/** How many lines of one comment on GitHub are drawn. */
export const MAX_REMARK_LINES = 12;
const TAB = 4;

/**
 * Text draws a tab as nothing: each one is padded to the next tab stop. This
 * runs for every line of a diff, so it reads a line once and does not use a
 * regular expression: one that looks for a tab from each place of a line
 * without one is slow enough on long lines for the app to stop the render.
 */
export function untab(text: string): string {
  if (!text.includes("\t")) return text;
  const parts = text.split("\t");
  const last = parts.pop() ?? "";
  let padded = "";
  for (const part of parts) {
    padded += part;
    padded += " ".repeat(TAB - (padded.length % TAB));
  }
  return padded + last;
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

/** The files of the review: those of the diff, then those that only have comments or discussions left. */
export function reviewFiles(
  files: readonly DiffFile[],
  comments: readonly Comment[],
  discussions: readonly Discussion[],
): ReviewFile[] {
  const entry = (file: DiffFile, isGone: boolean): ReviewFile => ({
    file,
    comments: comments.filter((comment) => comment.path === file.path),
    discussions: discussions.filter((discussion) => discussion.path === file.path),
    gone: isGone,
  });
  const changed = new Set(files.map((file) => file.path));
  const spoken = [...comments, ...discussions].map((anchor) => anchor.path);
  const left = [...new Set(spoken)].filter((path) => !changed.has(path));
  return [...files.map((file) => entry(file, false)), ...left.map((path) => entry(gone(path), true))];
}

/** The key of the row of a line. */
export function lineKey(anchor: Anchor): string {
  return `line:${anchorKey(anchor)}`;
}

function body(text: string, columns: number): CardLine[] {
  return wrap(text, columns).map((line) => ({ text: line, head: false }));
}

/** Says where a card belongs, for one whose line the diff does not show. */
function whereLine(anchor: Anchor, stale: boolean): CardLine[] {
  return stale ? [{ text: `Line ${anchor.line}, which is not in the diff:`, head: true }] : [];
}

/** What a card says over an answer that is a reply on GitHub too. */
const POSTING: Readonly<Record<Posting, string | null>> = {
  none: null,
  due: "A reply on GitHub too, when you send the review:",
  done: "Posted on GitHub:",
};

function postingLine(comment: Comment): CardLine[] {
  const text = POSTING[comment.about?.post ?? "none"];
  return text ? [{ text, head: true }] : [];
}

function commentCard(comment: Comment, columns: number, stale: boolean): Card {
  const lines = [...whereLine(comment, stale), ...postingLine(comment), ...body(comment.body, columns)];
  return { kind: "card", key: `comment:${anchorKey(comment)}`, anchor: comment, from: "draft", lines, stale };
}

/** A comment on GitHub: who wrote it, then the start of what they wrote. */
function remarkLines(remark: Remark, columns: number): CardLine[] {
  const lines = body(remark.body.trim(), columns);
  const cut: CardLine[] = lines.length > MAX_REMARK_LINES ? [{ text: "…", head: false }] : [];
  return [{ text: `@${remark.author} on GitHub`, head: true }, ...lines.slice(0, MAX_REMARK_LINES), ...cut];
}

function discussionCard(discussion: Discussion, index: number, columns: number, stale: boolean): Card {
  // One on several lines says which: the card is under the last one only.
  const span: CardLine[] = discussion.start && !stale ? [{ text: `On lines ${linesOf(discussion)}:`, head: true }] : [];
  const lines = [
    ...whereLine(discussion, stale),
    ...span,
    ...discussion.remarks.flatMap((remark) => remarkLines(remark, columns)),
  ];
  return { kind: "card", key: `discussion:${index}`, anchor: discussion, from: "github", lines, stale };
}

/** What stands in place of the lines of a file that has none to show. */
function emptyText(entry: ReviewFile): string | null {
  if (entry.gone) return "This file is no longer in the diff.";
  if (entry.file.binary) return "A binary file: it has no text to show.";
  return entry.file.hunks.length === 0 ? "No line of this file changed." : null;
}

/**
 * The cards of a file by the line they are on, in the order they show: the
 * discussions on GitHub, then the person's comment. `stale` builds the card of
 * a line the diff does not show.
 */
function cardsOf(entry: ReviewFile, columns: number, stale: boolean): Map<string, Card[]> {
  const cards = new Map<string, Card[]>();
  const add = (anchor: Anchor, card: Card): void => {
    const key = anchorKey(anchor);
    cards.set(key, [...(cards.get(key) ?? []), card]);
  };
  entry.discussions.forEach((discussion, index) => add(discussion, discussionCard(discussion, index, columns, stale)));
  for (const comment of entry.comments) add(comment, commentCard(comment, columns, stale));
  return cards;
}

/**
 * The rows of one file: each hunk's header and lines, with the cards of a line
 * under it. The cards of a line the diff does not show come first. `columns`
 * is how many characters of a card fit on one line.
 */
export function fileRows(entry: ReviewFile, columns: number): Row[] {
  const { file } = entry;
  const lines = file.hunks.flatMap((hunk) => hunk.lines);
  const shown = new Set(lines.map((line) => anchorKey(anchorOf(file.path, line))));
  const cards = cardsOf(entry, columns, false);
  const stale = [...cardsOf(entry, columns, true)].filter(([key]) => !shown.has(key));
  const rows: Row[] = stale.flatMap(([, rowsOfLine]) => rowsOfLine);
  const empty = emptyText(entry);
  if (empty) return [...rows, { kind: "note", key: "note:empty", text: empty }];
  let drawn = 0;
  for (const [index, hunk] of file.hunks.entries()) {
    if (drawn >= MAX_LINES) break;
    rows.push({ kind: "hunk", key: `hunk:${index}`, text: hunk.header });
    for (const line of hunk.lines.slice(0, MAX_LINES - drawn)) {
      const anchor = anchorOf(file.path, line);
      const under = cards.get(anchorKey(anchor)) ?? [];
      const mark = { commented: false, discussed: false };
      rows.push({ kind: "line", key: lineKey(anchor), anchor, line, text: untab(line.text), ...mark }, ...under);
    }
    drawn += hunk.lines.length;
  }
  if (lines.length > MAX_LINES) {
    rows.push({ kind: "note", key: "note:cut", text: `This diff is long: only its first ${MAX_LINES} lines show.` });
  }
  // What is said about several lines marks each of them, not only the last one.
  const covered = (spans: readonly Span[]) =>
    new Set(spans.flatMap((span) => spanRows(rows, span).map((row) => row.key)));
  const commented = covered(entry.comments);
  const discussed = covered(entry.discussions);
  return rows.map((row) =>
    row.kind === "line" ? { ...row, commented: commented.has(row.key), discussed: discussed.has(row.key) } : row,
  );
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
