import type { AsyncContext, Context, Element, FocusHandle } from "gpui-kit";
import { h_flex, InputState, TextareaState, v_flex, VirtualListScrollHandle } from "gpui-base";
import { closeOverlay } from "herdr";
import { messageOf, sendToThread } from "../actions";
import type { BranchDiff } from "../review/diff";
import {
  anchorKey,
  commentAt,
  isEmpty,
  linesOf,
  NO_DRAFT,
  reviewMessage,
  withComment,
  withNote,
  withoutComment,
  type Anchor,
  type Span,
} from "../review/draft";
import { readBranchDiff } from "../review/reader";
import {
  fileRows,
  quoteOf,
  reviewFiles,
  spanBetween,
  spanRows,
  widest,
  type ReviewFile,
  type Row,
} from "../review/rows";
import { fileTree, firstFile } from "../review/tree";
import { readDraft, saveDraft } from "../review/store";
import {
  commentColumns,
  composer,
  diffPane,
  fileHead,
  fileList,
  readType,
  reviewFoot,
  reviewHead,
  type Type,
} from "../review/view";
import { readScene } from "../snapshot";
import { threadAt, type Thread } from "../threads";
import { readTheme, type TextButton, type Theme } from "../ui";
import type { Part } from "./part";

/** The lines the person writes a comment on. */
interface Target {
  readonly anchor: Span;
  /** The line the person picked first: a Shift-click on another line makes a span from it. */
  readonly pivot: Anchor;
  /** The text of the lines. */
  readonly code: string;
  /** Set when the line has a comment already. */
  readonly written: boolean;
}

/** The rows of the file on show, kept until the file, its comments or the width change. */
interface Drawn {
  readonly signature: string;
  readonly rows: readonly Row[];
  readonly widest: number;
}

/** The width the diff is taken to have before the app says how wide it is. */
const FIRST_WIDTH = 900;

function whereOf(span: Span): string {
  if (span.start) return `Lines ${linesOf(span)}`;
  return span.side === "old" ? `Line ${span.line}, which the branch removes` : `Line ${span.line}`;
}

/**
 * The review of one thread: the files its branch changed, the diff of one of
 * them, and the comments the person writes on its lines. The comments are a
 * draft until they are sent to the thread, in one message.
 */
export class ReviewDialog implements Part {
  private readonly field = TextareaState.new({
    placeholder: "Write a comment. Shift-click another line to comment on all the lines between.",
    rows: 4,
  });
  private readonly note: InputState;
  private readonly scroll = VirtualListScrollHandle.new();
  private readonly handle: FocusHandle;
  private diff: BranchDiff | null = null;
  /** Set once the branch was asked for. The app can show the review before it knows the thread. */
  private asked = false;
  private loading = false;
  /** Why the branch could not be read, or the review not sent. */
  private error: string | null = null;
  private sending = false;
  /** Set once the review went to the thread: nothing of it is kept then. */
  private sent = false;
  /** The path of the file on show; the first file while null. */
  private open: string | null = null;
  /** The folders of the file tree that the person folded. */
  private readonly folded = new Set<string>();
  private target: Target | null = null;
  /** Whether Shift was held at the last press on the diff. */
  private shift = false;
  private width = FIRST_WIDTH;
  private drawn: Drawn | null = null;

  constructor(
    private readonly overlay: string,
    private readonly thread: string,
    cx: AsyncContext,
  ) {
    this.handle = cx.focus_handle();
    this.note = InputState.new({ placeholder: "A word on the whole branch (optional)", value: readDraft(thread).note });
    this.note.on("change", (_event, change) => change.notify());
    this.note.on("blur", () => this.keepNote());
    // Enter alone is a new line of the comment.
    this.field.on("submit", (event, submit) => {
      if (event.secondary) this.keepComment(submit);
    });
  }

  render(cx: Context): Element {
    const colors = readTheme();
    const type = readType();
    const thread = this.find();
    if (thread && !this.asked) this.load(cx);
    const draft = readDraft(this.thread);
    const files = reviewFiles(this.diff?.files ?? [], draft.comments);
    const shown = files.find((entry) => entry.file.path === this.open) ?? firstFile(files);
    const range = thread?.checkout && this.diff ? `${thread.checkout.branch} → ${this.diff.base}` : null;
    return v_flex()
      .id("review")
      .size_full()
      .bg(colors.popover)
      .text_color(colors.foreground)
      .track_focus(this.handle)
      .child(
        reviewHead(colors, {
          title: thread?.title ?? "This thread has ended.",
          range,
          files: this.diff?.files ?? [],
          loading: this.loading,
          onRefresh: (cx) => this.load(cx),
          onClose: () => closeOverlay(this.overlay),
        }),
      )
      .child(
        h_flex()
          .flex_1()
          .min_h(0)
          .items_start()
          .child(
            fileList(colors, {
              rows: fileTree(files, this.folded),
              onFold: (path, cx) => this.fold(path, cx),
              open: shown?.file.path ?? null,
              empty: this.emptyText(),
              onOpen: (path, cx) => this.show(path, cx),
            }),
          )
          .child(this.file(colors, type, shown)),
      )
      .child(
        reviewFoot(colors, {
          note: this.note,
          // Before the first diff, the file list says what went wrong.
          error: this.diff ? this.error : null,
          send: this.sendButton(thread, draft.comments.length),
        }),
      );
  }

  /** Called once when the dialog goes: what the person was writing stays in the draft. */
  close(): void {
    if (this.sent) return;
    this.keepTyped();
    this.keepNote();
  }

  private find(): Thread | undefined {
    const { snapshot, projects } = readScene();
    return threadAt(snapshot, projects, this.thread);
  }

  private emptyText(): string {
    if (this.error && !this.diff) return this.error;
    if (!this.diff) return this.loading ? "Reading the branch…" : "No branch to review.";
    return `Nothing changed against ${this.diff.base}.`;
  }

  /** The right side: the diff of the file on show, and the comment being written under it. */
  private file(colors: Theme, type: Type, shown: ReviewFile | undefined): Element {
    const side = v_flex().flex_1().min_w(0).h_full();
    if (!shown) return side;
    const columns = commentColumns(this.width, type);
    const drawn = this.rowsOf(shown, columns);
    const target = this.target?.anchor.path === shown.file.path ? this.target : null;
    const pane = side.child(fileHead(colors, type, shown.file)).child(
      diffPane(colors, {
        rows: drawn.rows,
        widest: drawn.widest,
        type,
        columns,
        scroll: this.scroll,
        active: new Set(target ? spanRows(drawn.rows, target.anchor).map((row) => row.key) : []),
        onPress: (shift) => {
          this.shift = shift;
        },
        onPick: (key, cx) => this.pick(drawn.rows, key, cx),
        onWidth: (width, cx) => this.resize(width, cx),
      }),
    );
    if (!target) return pane;
    return pane.child(
      composer(colors, {
        where: whereOf(target.anchor),
        code: target.code.split("\n")[0] ?? "",
        type,
        field: this.field,
        buttons: this.composerButtons(target),
      }),
    );
  }

  private composerButtons(target: Target): TextButton[] {
    const remove: TextButton = {
      id: "review-delete",
      label: "Delete",
      onClick: (cx) => this.removeComment(target.anchor, cx),
    };
    return [
      ...(target.written ? [remove] : []),
      { id: "review-cancel", label: "Cancel", onClick: (cx) => this.closeComposer(cx) },
      {
        id: "review-keep",
        label: target.written ? "Save" : "Comment",
        primary: true,
        onClick: (cx) => this.keepComment(cx),
      },
    ];
  }

  private sendButton(thread: Thread | undefined, comments: number): TextButton {
    const empty = comments === 0 && this.note.value().trim() === "";
    return {
      id: "review-send",
      label: this.sending ? "Sending…" : comments > 0 ? `Send review · ${comments}` : "Send review",
      primary: true,
      disabled: empty || this.sending || !thread,
      onClick: (cx) => this.send(cx),
    };
  }

  private rowsOf(entry: ReviewFile, columns: number): Drawn {
    const words = entry.comments.map((comment) => `${anchorKey(comment)} ${comment.body}`);
    const signature = JSON.stringify([entry.file.path, columns, words]);
    if (this.drawn?.signature === signature) return this.drawn;
    const rows = fileRows(entry, columns);
    this.drawn = { signature, rows, widest: widest(rows) };
    return this.drawn;
  }

  private load(cx: Context): void {
    const thread = this.find();
    if (!thread || this.loading) return;
    this.asked = true;
    this.loading = true;
    cx.spawn(async (task) => {
      try {
        this.diff = await readBranchDiff(thread);
        this.drawn = null;
        this.error = null;
      } catch (error) {
        this.error = messageOf(error);
      } finally {
        this.loading = false;
        task.notify();
      }
    });
  }

  private show(path: string, cx: Context): void {
    this.keepTyped();
    this.target = null;
    this.open = path;
    this.scroll.scroll_to_item(0);
    cx.notify();
  }

  private resize(width: number, cx: Context): void {
    if (Math.abs(width - this.width) < 1) return;
    this.width = width;
    cx.notify();
  }

  /** A click on a line, or on its comment, opens that line's comment to write. */
  private pick(rows: readonly Row[], key: string, cx: Context): void {
    const row = rows.find((candidate) => candidate.key === key);
    if (row?.kind !== "line" && row?.kind !== "comment") return;
    if (this.shift && row.kind === "line" && this.extend(rows, row.anchor, cx)) return;
    this.keepTyped();
    const written = commentAt(readDraft(this.thread), row.anchor);
    this.target = {
      anchor: written ?? { ...row.anchor, start: null },
      pivot: row.anchor,
      code: written?.code ?? (row.kind === "line" ? row.line.text : ""),
      written: Boolean(written),
    };
    this.field.set_value(written?.body ?? "");
    this.field.focus();
    cx.notify();
  }

  /**
   * A Shift-click on a line while a comment is open: the comment is then on
   * every line from the one picked first to this one. What is typed stays.
   * False when no comment of this file is open.
   */
  private extend(rows: readonly Row[], anchor: Anchor, cx: Context): boolean {
    const { target } = this;
    if (!target || target.pivot.path !== anchor.path) return false;
    const span = spanBetween(rows, target.pivot, anchor);
    this.target = { ...target, anchor: span, code: quoteOf(spanRows(rows, span)) };
    // A comment that was written moves with its last line.
    if (target.written && anchorKey(span) !== anchorKey(target.anchor)) this.moveComment(target.anchor, this.target);
    this.field.focus();
    cx.notify();
    return true;
  }

  /** Takes a written comment from the lines it was on and puts it on other lines, with the same words. */
  private moveComment(from: Span, to: Target): void {
    const draft = readDraft(this.thread);
    const written = commentAt(draft, from);
    if (!written) return;
    saveDraft(this.thread, withComment(withoutComment(draft, from), to.anchor, to.code, written.body));
  }

  private fold(path: string, cx: Context): void {
    if (!this.folded.delete(path)) this.folded.add(path);
    cx.notify();
  }

  /** Puts what the person typed on the open line into the draft. */
  private keepTyped(): void {
    const { target } = this;
    if (!target || this.field.value().trim() === "") return;
    saveDraft(this.thread, withComment(readDraft(this.thread), target.anchor, target.code, this.field.value()));
  }

  private keepNote(): void {
    const draft = readDraft(this.thread);
    if (this.sent || draft.note === this.note.value()) return;
    saveDraft(this.thread, withNote(draft, this.note.value()));
  }

  private keepComment(cx: Context): void {
    this.keepTyped();
    this.closeComposer(cx);
  }

  private removeComment(anchor: Anchor, cx: Context): void {
    saveDraft(this.thread, withoutComment(readDraft(this.thread), anchor));
    this.closeComposer(cx);
  }

  private closeComposer(cx: Context): void {
    this.target = null;
    this.field.set_value("");
    this.handle.focus();
    cx.notify();
  }

  /** Sends the note and every comment to the thread in one message, then closes the review. */
  private send(cx: Context): void {
    if (this.sending) return;
    this.keepTyped();
    this.keepNote();
    const draft = readDraft(this.thread);
    if (isEmpty(draft)) return;
    const paths = (this.diff?.files ?? []).map((file) => file.path);
    this.sending = true;
    this.error = null;
    cx.spawn(async (task) => {
      try {
        await sendToThread(this.thread, reviewMessage(draft, paths));
      } catch (error) {
        this.error = messageOf(error);
        this.sending = false;
        task.notify();
        return;
      }
      this.sent = true;
      saveDraft(this.thread, NO_DRAFT);
      closeOverlay(this.overlay);
    });
    cx.notify();
  }
}
