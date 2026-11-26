import { isRecord, text } from "../parse";
import type { DiffLine } from "./diff";

/** The side of a diff a line is on: the base's file, or the branch's. */
export type Side = "old" | "new";

/** A line of a file, as a comment points at it. */
export interface Anchor {
  readonly path: string;
  readonly side: Side;
  readonly line: number;
}

/** One comment of a review. A line has one comment at most. */
export interface Comment extends Anchor {
  /** The text of the line, quoted to the thread. */
  readonly code: string;
  readonly body: string;
}

/** A review the person writes and has not sent yet. */
export interface Draft {
  /** A word on the whole branch, sent before the comments. */
  readonly note: string;
  readonly comments: readonly Comment[];
}

/** The drafts of the threads that have one, by the thread's terminal address. */
export type Drafts = Readonly<Record<string, Draft>>;

export const NO_DRAFT: Draft = { note: "", comments: [] };

export function anchorKey(anchor: Anchor): string {
  return `${anchor.side}:${anchor.line}:${anchor.path}`;
}

/** Where a comment on a line of a diff points. A line the branch removes is only in the base's file. */
export function anchorOf(path: string, line: DiffLine): Anchor {
  return line.now === null ? { path, side: "old", line: line.old ?? 0 } : { path, side: "new", line: line.now };
}

function parseComment(value: unknown): Comment | null {
  if (!isRecord(value)) return null;
  const { side, line, code } = value;
  const path = text(value.path);
  const body = text(value.body);
  if (!path || !body || (side !== "old" && side !== "new")) return null;
  if (typeof line !== "number" || typeof code !== "string") return null;
  return { path, side, line, code, body };
}

function parseDraft(value: unknown): Draft {
  if (!isRecord(value)) return NO_DRAFT;
  const comments = Array.isArray(value.comments) ? value.comments.map(parseComment) : [];
  return {
    note: typeof value.note === "string" ? value.note : "",
    comments: comments.filter((comment): comment is Comment => comment !== null),
  };
}

export function isEmpty(draft: Draft): boolean {
  return draft.comments.length === 0 && draft.note.trim() === "";
}

/** Reads the stored drafts; anything that is not one is dropped. */
export function parseDrafts(value: unknown): Drafts {
  if (!isRecord(value)) return {};
  const drafts = Object.entries(value).map(([thread, draft]) => [thread, parseDraft(draft)] as const);
  return Object.fromEntries(drafts.filter(([, draft]) => !isEmpty(draft)));
}

/** The drafts with the one of `thread` set. An empty draft is not kept. */
export function withDraft(drafts: Drafts, thread: string, draft: Draft): Drafts {
  const kept = Object.entries({ ...drafts, [thread]: draft });
  return Object.fromEntries(kept.filter(([, value]) => !isEmpty(value)));
}

export function commentAt(draft: Draft, anchor: Anchor): Comment | undefined {
  const key = anchorKey(anchor);
  return draft.comments.find((comment) => anchorKey(comment) === key);
}

export function withoutComment(draft: Draft, anchor: Anchor): Draft {
  const key = anchorKey(anchor);
  return { ...draft, comments: draft.comments.filter((comment) => anchorKey(comment) !== key) };
}

/** The draft with the comment of a line set to `body`. A body without words removes the comment. */
export function withComment(draft: Draft, anchor: Anchor, code: string, body: string): Draft {
  const rest = withoutComment(draft, anchor);
  const words = body.trim();
  return words ? { ...rest, comments: [...rest.comments, { ...anchor, code, body: words }] } : rest;
}

export function withNote(draft: Draft, note: string): Draft {
  return { ...draft, note };
}

/** The comments as a reader goes through the diff: file by file in the order of `paths`, then down each file. */
export function inOrder(comments: readonly Comment[], paths: readonly string[]): Comment[] {
  const place = (comment: Comment): number => {
    const index = paths.indexOf(comment.path);
    return index < 0 ? paths.length : index;
  };
  return [...comments].sort(
    (a, b) => place(a) - place(b) || a.path.localeCompare(b.path) || a.line - b.line || a.side.localeCompare(b.side),
  );
}

const INDENT = "   ";

function indent(text: string): string {
  return text
    .split("\n")
    .map((line) => (line ? INDENT + line : ""))
    .join("\n");
}

function commentText(comment: Comment, index: number): string {
  const where = `${comment.path}:${comment.line}${comment.side === "old" ? " (a line the branch removes)" : ""}`;
  const quote = comment.code.trim() ? [`${INDENT}> ${comment.code.trim()}`] : [];
  return [`${index + 1}. ${where}`, ...quote, indent(comment.body)].join("\n");
}

function countOf(comments: number): string {
  return comments === 1 ? "1 comment" : `${comments} comments`;
}

/** The review as one message for the thread: the note, then each comment with its file, its line and the line's text. */
export function reviewMessage(draft: Draft, paths: readonly string[]): string {
  const comments = inOrder(draft.comments, paths);
  const head = comments.length ? `Review of your branch: ${countOf(comments.length)}.` : "Review of your branch.";
  const note = draft.note.trim();
  return [head, ...(note ? [note] : []), ...comments.map(commentText)].join("\n\n");
}
