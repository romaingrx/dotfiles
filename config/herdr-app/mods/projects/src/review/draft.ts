import { isRecord, text } from "../parse";
import type { Pull } from "../pulls";
import type { DiffLine } from "./diff";

/** The side of a diff a line is on: the base's file, or the branch's. */
export type Side = "old" | "new";

/** A line of a file, as a comment points at it. */
export interface Anchor {
  readonly path: string;
  readonly side: Side;
  readonly line: number;
}

/** What a comment of the review answers: a comment someone left on GitHub. */
export interface About {
  readonly author: string;
  readonly url: string;
  /** The start of what they wrote. */
  readonly quote: string;
  /** The discussion they wrote it in, as GitHub calls it. */
  readonly discussion: string;
  readonly post: Posting;
}

/**
 * Whether an answer is a reply on GitHub too, in the person's name: not at
 * all, when the review is sent, or already. One that is posted is not posted
 * again when a send is tried once more.
 */
export type Posting = "none" | "due" | "done";

/** A line of a file's diff, without the file. */
export type Mark = Pick<Anchor, "side" | "line">;

/** One line, or several in a row. It is anchored on its last line: what is said about it shows under that one. */
export interface Span extends Anchor {
  /** Its first line, when it has more than one. */
  readonly start: Mark | null;
}

/** One comment of a review. A line is the last one of one comment at most. */
export interface Comment extends Span {
  /** The text of its lines, quoted to the thread. */
  readonly code: string;
  readonly body: string;
  /** Set for a comment on a line that has a discussion on GitHub. */
  readonly about: About | null;
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

function isSide(value: unknown): value is Side {
  return value === "old" || value === "new";
}

function parseMark(value: unknown): Mark | null {
  if (!isRecord(value) || !isSide(value.side) || typeof value.line !== "number") return null;
  return { side: value.side, line: value.line };
}

function parsePosting(value: unknown): Posting {
  return value === "due" || value === "done" ? value : "none";
}

function parseAbout(value: unknown): About | null {
  if (!isRecord(value)) return null;
  const author = text(value.author);
  const url = text(value.url);
  const discussion = text(value.discussion);
  if (!author || !url || !discussion || typeof value.quote !== "string") return null;
  return { author, url, quote: value.quote, discussion, post: parsePosting(value.post) };
}

function parseComment(value: unknown): Comment | null {
  if (!isRecord(value)) return null;
  const path = text(value.path);
  const body = text(value.body);
  const last = parseMark(value);
  if (!path || !body || !last || typeof value.code !== "string") return null;
  const start = parseMark(value.start);
  return { path, ...last, start, code: value.code, body, about: parseAbout(value.about) };
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

/** A comment as the person writes it on some lines: the lines' text, their words, and what they answer. */
export type Written = Pick<Comment, "code" | "body" | "about">;

/** The draft with the comment of some lines set. A body without words removes the comment. */
export function withComment(draft: Draft, span: Span, written: Written): Draft {
  const rest = withoutComment(draft, span);
  const { path, side, line, start } = span;
  const body = written.body.trim();
  return body ? { ...rest, comments: [...rest.comments, { path, side, line, start, ...written, body }] } : rest;
}

export function withNote(draft: Draft, note: string): Draft {
  return { ...draft, note };
}

/** The comments that are still to be posted on GitHub as replies. */
export function duePosts(draft: Draft): Comment[] {
  return draft.comments.filter((comment) => comment.about?.post === "due");
}

/** The draft with the answer on a line marked as posted on GitHub. */
export function withPosted(draft: Draft, anchor: Anchor): Draft {
  const key = anchorKey(anchor);
  const posted = (comment: Comment): Comment =>
    anchorKey(comment) === key && comment.about ? { ...comment, about: { ...comment.about, post: "done" } } : comment;
  return { ...draft, comments: draft.comments.map(posted) };
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

/** The lines of a span as a reader names them: `12`, or `12-15`. */
export function linesOf(span: Span): string {
  return span.start ? `${span.start.line}-${span.line}` : String(span.line);
}

/** The text of the lines a comment is on, each one quoted. */
function quoted(code: string): string[] {
  if (!code.trim()) return [];
  return [
    indent(
      code
        .split("\n")
        .map((line) => `> ${line.trim()}`)
        .join("\n"),
    ),
  ];
}

/** Says which comment on GitHub an answer is to, and that the answer is there too when it was posted. */
function answerText(about: About): string {
  const posted = about.post === "done" ? ", where this answer is posted too" : "";
  return `In answer to @${about.author} on GitHub (${about.url})${posted}:\n> ${about.quote}`;
}

function commentText(comment: Comment, index: number): string {
  const removed = comment.side === "old" ? " (a line the branch removes)" : "";
  const answers = comment.about ? [indent(answerText(comment.about))] : [];
  return [
    `${index + 1}. ${comment.path}:${linesOf(comment)}${removed}`,
    ...quoted(comment.code),
    ...answers,
    indent(comment.body),
  ].join("\n");
}

function countOf(comments: number): string {
  return comments === 1 ? "1 comment" : `${comments} comments`;
}

/** The key of a thread's draft. Each pull request has its own: the lines of two layers of a stack have other numbers. */
export function draftKey(thread: string, pull: Pull | null): string {
  return pull ? `${thread}#${pull.number}` : thread;
}

/**
 * The review as one message for the thread: what it is of, the note, then
 * each comment with its file, its line and the line's text.
 */
export function reviewMessage(draft: Draft, paths: readonly string[], pull: Pull | null): string {
  const comments = inOrder(draft.comments, paths);
  const what = pull ? `pull request #${pull.number} (${pull.url})` : "your branch";
  const head = comments.length ? `Review of ${what}: ${countOf(comments.length)}.` : `Review of ${what}.`;
  const note = draft.note.trim();
  return [head, ...(note ? [note] : []), ...comments.map(commentText)].join("\n\n");
}
