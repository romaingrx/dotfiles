import type { AsyncContext, Context, Element, FocusHandle } from "gpui-kit";
import { h_flex, InputState, TextareaState, v_flex, VirtualListScrollHandle } from "gpui-base";
import { closeOverlay } from "herdr";
import { messageOf, sendToThread } from "../actions";
import { leadPull, openPulls, type Pull } from "../pulls";
import { reviewRange, type BranchDiff } from "../review/diff";
import { aboutOf, discussionsAt, type Discussion } from "../review/discussions";
import {
  anchorKey,
  commentAt,
  draftKey,
  duePosts,
  isEmpty,
  linesOf,
  NO_DRAFT,
  reviewMessage,
  withComment,
  withNote,
  withoutComment,
  withPosted,
  type About,
  type Anchor,
  type Draft,
  type Posting,
  type Span,
} from "../review/draft";
import { postReply, readBranchDiff, readDiscussions } from "../review/reader";
import {
  fileAt,
  fileKey,
  lineKey,
  offsets,
  quoteOf,
  reviewFiles,
  reviewRows,
  spanBetween,
  spanRows,
  widest,
  type ReviewFile,
  type Row,
} from "../review/rows";
import { fileTree, filterFiles, inTreeOrder } from "../review/tree";
import { readDraft, saveDraft } from "../review/store";
import {
  commentColumns,
  composer,
  diffPane,
  fileList,
  pullStrip,
  readType,
  reviewFoot,
  reviewHead,
  rowHeights,
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
  /** The comment on GitHub that a comment on this line answers. */
  readonly about: About | null;
}

/** The rows of the whole review, kept until its files, its comments, the width or the type change. */
interface Drawn {
  readonly signature: string;
  readonly rows: readonly Row[];
  /** How many characters of a card fit on one line, as the rows were cut. */
  readonly columns: number;
  readonly heights: readonly number[];
  /** Where each row starts in the list. */
  readonly tops: readonly number[];
  readonly widest: number;
}

/** The width the diff is taken to have before the app says how wide it is. */
const FIRST_WIDTH = 900;

/** What the person asks of the thread with one click on a discussion. */
const ADDRESS = "Address this comment.";

function linesWord(span: Span): string {
  if (span.start) return `Lines ${linesOf(span)}`;
  return span.side === "old" ? `Line ${span.line}, which the branch removes` : `Line ${span.line}`;
}

function whereOf(target: Target): string {
  // Several files are on show at once: the file's name says which one the lines are of.
  const { path } = target.anchor;
  const lines = `${path.slice(path.lastIndexOf("/") + 1)} · ${linesWord(target.anchor)}`;
  return target.about ? `${lines} · in answer to @${target.about.author} on GitHub` : lines;
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
  /** What the person typed to see only some files in the tree. */
  private readonly filter = InputState.new({ placeholder: "Filter files…" });
  private readonly scroll = VirtualListScrollHandle.new();
  private readonly handle: FocusHandle;
  /** The pull request under review. Null reviews the folder of a thread that has none. */
  private subject: Pull | null = null;
  private diff: BranchDiff | null = null;
  /** The open discussions of that pull request on GitHub. */
  private discussions: readonly Discussion[] = [];
  /** Set once the branch was asked for. The app can show the review before it knows the thread. */
  private asked = false;
  /** Counts the reads. An answer to a read that is not the last one is dropped. */
  private round = 0;
  private loading = false;
  /** Why the branch could not be read, or the review not sent. */
  private error: string | null = null;
  private sending = false;
  /** Set once the review went to the thread: nothing of it is kept then. */
  private sent = false;
  /** The path of the file the diff is scrolled to; the first file while null. */
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
    this.note = InputState.new({ placeholder: "A word on the whole branch (optional)" });
    this.note.on("change", (_event, change) => change.notify());
    this.filter.on("change", (_event, change) => change.notify());
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
    const draft = readDraft(this.key());
    const files = reviewFiles(this.diff?.files ?? [], draft.comments, this.discussions);
    const drawn = this.rowsOf(inTreeOrder(files), commentColumns(this.width, type), type);
    // The file on show is the one the diff is scrolled to: the first one before any scroll.
    const open = files.some((entry) => entry.file.path === this.open) ? this.open : fileAt(drawn.rows, drawn.tops, 0);
    const branch = thread?.checkout?.branch;
    const tip = branch && (reviewRange(this.subject, branch).tip ?? branch);
    const range = tip && this.diff ? `${tip} → ${this.diff.base}` : null;
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
      .children(
        pullStrip(colors, {
          choices: openPulls(thread?.pulls ?? []),
          shown: this.subject,
          onPick: (pull, cx) => this.turn(pull, cx),
        }),
      )
      .child(
        h_flex()
          .flex_1()
          .min_h(0)
          .items_start()
          .child(
            fileList(colors, {
              rows: fileTree(filterFiles(files, this.filter.value()), this.folded),
              filter: this.filter,
              onFold: (path, cx) => this.fold(path, cx),
              open,
              empty: this.emptyText(),
              onOpen: (path, cx) => this.show(drawn.rows, path, cx),
            }),
          )
          .child(this.diffSide(colors, type, drawn)),
      )
      .child(
        reviewFoot(colors, {
          note: this.note,
          // Before the first diff, the file list says what went wrong.
          error: this.diff ? this.error : null,
          send: this.sendButton(thread, draft),
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

  /** Where the draft of what is under review is kept. */
  private key(): string {
    return draftKey(this.thread, this.subject);
  }

  /** Puts a pull request under review: it has its own draft, and its own diff to read. */
  private turnTo(pull: Pull | null): void {
    this.keepTyped();
    this.keepNote();
    this.subject = pull;
    this.diff = null;
    this.discussions = [];
    this.open = null;
    this.target = null;
    this.drawn = null;
    this.scroll.scroll_to_item(0);
    this.field.set_value("");
    this.note.set_value(readDraft(this.key()).note);
  }

  /** A pick of another pull request of the stack. */
  private turn(pull: Pull, cx: Context): void {
    if (pull.url === this.subject?.url) return;
    this.turnTo(pull);
    this.load(cx);
  }

  private emptyText(): string {
    if (this.error && !this.diff) return this.error;
    if (!this.diff) return this.loading ? "Reading the branch…" : "No branch to review.";
    return `Nothing changed against ${this.diff.base}.`;
  }

  /** The right side: the diff of every file in one scroll, and the comment being written under it. */
  private diffSide(colors: Theme, type: Type, drawn: Drawn): Element {
    const side = v_flex().flex_1().min_w(0).h_full();
    if (drawn.rows.length === 0) return side;
    const { target } = this;
    const pane = side.child(
      diffPane(colors, {
        rows: drawn.rows,
        heights: drawn.heights,
        widest: drawn.widest,
        type,
        columns: drawn.columns,
        scroll: this.scroll,
        onScroll: (cx) => this.follow(drawn, cx),
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
        where: whereOf(target),
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
    const address: TextButton = { id: "review-address", label: "Ask to address it", onClick: (cx) => this.address(cx) };
    const cancel: TextButton = { id: "review-cancel", label: "Cancel", onClick: (cx) => this.closeComposer(cx) };
    const keep = (label: string, post: Posting, primary: boolean): TextButton => ({
      id: `review-keep-${post}`,
      label,
      primary,
      onClick: (cx) => this.keepComment(cx, post),
    });
    const first = target.written ? [remove] : [];
    // On a line with a discussion, the person says where the answer goes: nothing is posted without that click.
    if (target.about) {
      const ask = target.written ? [] : [address];
      return [
        ...ask,
        ...first,
        cancel,
        keep("To the thread only", "none", false),
        keep("Reply on GitHub", "due", true),
      ];
    }
    return [...first, cancel, keep(target.written ? "Save" : "Comment", "none", true)];
  }

  /** What Send says it does: how many comments go to the thread, and how many of them to GitHub too. */
  private sendLabel(draft: Draft): string {
    const comments = draft.comments.length;
    const replies = duePosts(draft).length;
    if (this.sending) return "Sending…";
    if (comments === 0) return "Send review";
    return replies > 0 ? `Send review · ${comments} · ${replies} to GitHub` : `Send review · ${comments}`;
  }

  private sendButton(thread: Thread | undefined, draft: Draft): TextButton {
    const empty = draft.comments.length === 0 && this.note.value().trim() === "";
    return {
      id: "review-send",
      label: this.sendLabel(draft),
      primary: true,
      disabled: empty || this.sending || !thread,
      onClick: (cx) => this.send(cx),
    };
  }

  private rowsOf(files: readonly ReviewFile[], columns: number, type: Type): Drawn {
    const said = files.flatMap((entry) => entry.comments);
    const words = said.map((comment) => `${anchorKey(comment)} ${comment.about?.post} ${comment.body}`);
    const signature = JSON.stringify([files.length, columns, type.size, words]);
    if (this.drawn?.signature === signature) return this.drawn;
    const rows = reviewRows(files, columns);
    const heights = rowHeights(rows, type);
    this.drawn = { signature, rows, columns, heights, tops: offsets(heights), widest: widest(rows) };
    return this.drawn;
  }

  /** After a turn of the wheel, the tree marks the file the diff is scrolled to. */
  private follow(drawn: Drawn, cx: Context): void {
    const path = fileAt(drawn.rows, drawn.tops, this.scroll.offset().y);
    if (path === this.open) return;
    this.open = path;
    cx.notify();
  }

  private load(cx: Context): void {
    const thread = this.find();
    if (!thread) return;
    // The pull requests of a thread can become known after its review opened: the next read takes the lead one.
    if (this.subject === null) this.turnTo(leadPull(openPulls(thread.pulls)));
    const { subject } = this;
    const range = reviewRange(subject, thread.checkout?.branch ?? "");
    const round = ++this.round;
    const latest = (): boolean => this.round === round;
    this.asked = true;
    this.loading = true;
    this.error = null;
    cx.spawn(async (task) => {
      const show = (): void => {
        this.drawn = null;
        task.notify();
      };
      await Promise.all([
        this.read(readBranchDiff(thread, range), (diff) => (this.diff = diff), latest).then(show),
        this.read(readDiscussions(thread, subject), (discussions) => (this.discussions = discussions), latest).then(
          show,
        ),
      ]);
      if (latest()) this.loading = false;
      task.notify();
    });
  }

  /**
   * Reads one part of the review. Each part shows as soon as it is there: the
   * other one may take longer, or fail. An answer that comes after the person
   * turned to another pull request is dropped.
   */
  private async read<T>(reading: Promise<T>, keep: (value: T) => void, latest: () => boolean): Promise<void> {
    try {
      const value = await reading;
      if (latest()) keep(value);
    } catch (error) {
      if (latest()) this.error = messageOf(error);
    }
  }

  /** A click on a file in the tree: the diff goes to that file's card. */
  private show(rows: readonly Row[], path: string, cx: Context): void {
    const at = rows.findIndex((row) => row.key === fileKey(path));
    if (at < 0) return;
    this.open = path;
    this.scroll.scroll_to_item(at, "top");
    cx.notify();
  }

  private resize(width: number, cx: Context): void {
    if (Math.abs(width - this.width) < 1) return;
    this.width = width;
    cx.notify();
  }

  /** A click on a line, or on a card under it, opens that line's comment to write. */
  private pick(rows: readonly Row[], key: string, cx: Context): void {
    const row = rows.find((candidate) => candidate.key === key);
    if (row?.kind !== "line" && row?.kind !== "card") return;
    if (this.shift && row.kind === "line" && this.extend(rows, row.anchor, cx)) return;
    this.keepTyped();
    const written = commentAt(readDraft(this.key()), row.anchor);
    const line = rows.find((candidate) => candidate.key === lineKey(row.anchor));
    this.target = {
      anchor: written ?? { path: row.anchor.path, side: row.anchor.side, line: row.anchor.line, start: null },
      pivot: row.anchor,
      code: written?.code ?? (line?.kind === "line" ? line.line.text : ""),
      written: Boolean(written),
      about: this.aboutAt(row.anchor),
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
    this.target = { ...target, anchor: span, code: quoteOf(spanRows(rows, span)), about: this.aboutAt(span) };
    // A comment that was written moves with its last line.
    if (target.written && anchorKey(span) !== anchorKey(target.anchor)) this.moveComment(target.anchor, this.target);
    this.field.focus();
    cx.notify();
    return true;
  }

  /** Takes a written comment from the lines it was on and puts it on other lines, with the same words. */
  /** What a comment that ends on a line answers: the discussion on GitHub that is on that line, if one is. */
  private aboutAt(anchor: Anchor): About | null {
    const [discussion] = discussionsAt(this.discussions, anchor);
    return discussion ? aboutOf(discussion) : null;
  }

  private moveComment(from: Span, to: Target): void {
    const draft = readDraft(this.key());
    const written = commentAt(draft, from);
    if (!written) return;
    saveDraft(this.key(), withComment(withoutComment(draft, from), to.anchor, { ...written, code: to.code }));
  }

  private fold(path: string, cx: Context): void {
    if (!this.folded.delete(path)) this.folded.add(path);
    cx.notify();
  }

  /** Puts what the person typed on the open line into the draft. */
  private keepTyped(chosen?: Posting): void {
    const { target } = this;
    if (!target || this.field.value().trim() === "") return;
    const draft = readDraft(this.key());
    // Without a choice (another line is picked, the dialog closes), an answer goes where it went before: never to GitHub by itself.
    const post = chosen ?? commentAt(draft, target.anchor)?.about?.post ?? "none";
    const about = target.about && { ...target.about, post };
    saveDraft(this.key(), withComment(draft, target.anchor, { code: target.code, body: this.field.value(), about }));
  }

  private keepNote(): void {
    // Before the first read, the field does not hold the draft's note yet.
    if (this.sent || !this.asked) return;
    const draft = readDraft(this.key());
    if (draft.note === this.note.value()) return;
    saveDraft(this.key(), withNote(draft, this.note.value()));
  }

  private keepComment(cx: Context, post?: Posting): void {
    this.keepTyped(post);
    this.closeComposer(cx);
  }

  /** Answers the discussion on the open line with a request to act on it. It is for the thread: it is not posted. */
  private address(cx: Context): void {
    this.field.set_value(ADDRESS);
    this.keepComment(cx, "none");
  }

  /**
   * Posts the answers that are replies on GitHub, one by one. Each is marked
   * once it is there, so a second try posts none twice.
   */
  private async postReplies(thread: Thread, key: string, pull: Pull | null): Promise<void> {
    for (const comment of duePosts(readDraft(key))) {
      // An answer is in a discussion, and a discussion is of the pull request under review.
      if (!comment.about || !pull) continue;
      await postReply(thread, pull, comment.about, comment.body);
      saveDraft(key, withPosted(readDraft(key), comment));
    }
  }

  private removeComment(anchor: Anchor, cx: Context): void {
    saveDraft(this.key(), withoutComment(readDraft(this.key()), anchor));
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
    const thread = this.find();
    // What is sent is the draft of the pull request on show now, also if the person picks another one meanwhile.
    const key = this.key();
    const { subject } = this;
    if (!thread || isEmpty(readDraft(key))) return;
    const paths = (this.diff?.files ?? []).map((file) => file.path);
    this.sending = true;
    this.error = null;
    cx.spawn(async (task) => {
      const fail = (message: string): void => {
        this.error = message;
        this.sending = false;
        task.notify();
      };
      // GitHub first: when a reply fails, the thread has no message yet, and another Send goes on from there.
      try {
        await this.postReplies(thread, key, subject);
      } catch (error) {
        return fail(
          `${messageOf(error)}. Nothing went to the thread: send again, or keep that answer for the thread only.`,
        );
      }
      try {
        await sendToThread(this.thread, reviewMessage(readDraft(key), paths, subject));
      } catch (error) {
        return fail(messageOf(error));
      }
      this.sent = true;
      saveDraft(key, NO_DRAFT);
      closeOverlay(this.overlay);
    });
    cx.notify();
  }
}
