import { div, svg, type Color, type Context, type Element } from "gpui-kit";
import {
  h_flex,
  Input,
  Scrollbar,
  Textarea,
  v_flex,
  v_virtual_list,
  type InputState,
  type TextareaState,
  type VirtualListScrollHandle,
} from "gpui-base";
import { settings } from "herdr";
import { text } from "../parse";
import { stageLabel, type Pull, type Stack } from "../pulls";
import { chromeIcon, iconButton, optional, textButton, type Handler, type TextButton, type Theme } from "../ui";
import type { DiffFile, DiffLine } from "./diff";
import type { Card, ReviewFile, Row } from "./rows";
import type { TreeRow } from "./tree";

/** The type the diff is set in: the terminals' font, and the room one character and one row take. */
export interface Type {
  readonly family: string;
  readonly size: number;
  readonly row: number;
  readonly char: number;
}

const FALLBACK_FONT = "JetBrains Mono";
const FALLBACK_SIZE = 13;

export function readType(): Type {
  const all = settings();
  const size = typeof all.font_size === "number" ? all.font_size : FALLBACK_SIZE;
  return { family: text(all.font_family) ?? FALLBACK_FONT, size, row: Math.ceil(size * 1.8), char: size * 0.64 };
}

/** How many times a px of the window is a px of a mod. */
export function readZoom(): number {
  const { zoom } = settings();
  return typeof zoom === "number" && zoom > 0 ? zoom : 1;
}

const NUMBER_DIGITS = 4;
const MARK = 3;
const COMMENT_GAP = 4;
const COMMENT_PAD = { x: 10, y: 6 };
const DIFF_END = 16;

/** How wide the column of line numbers is. */
function numbers(type: Type): number {
  return Math.ceil((NUMBER_DIGITS + 1) * type.char);
}

/** The room left of a line's text: the mark at the edge, the line number, and a gap. */
function gutter(type: Type): number {
  return MARK + numbers(type) + Math.ceil(2 * type.char);
}

/** How many characters of a comment fit on one line, in a diff that is `width` wide. */
export function commentColumns(width: number, type: Type): number {
  const room = width - gutter(type) - 2 * COMMENT_PAD.x - DIFF_END;
  return Math.max(24, Math.floor(room / type.char));
}

/** The gap over a file's card, and the height of its head. */
const FILE_GAP = 10;
const FILE_HEAD = 32;

function rowHeight(row: Row, type: Type): number {
  if (row.kind === "file") return FILE_GAP + FILE_HEAD;
  return row.kind === "card" ? row.lines.length * type.row + 2 * (COMMENT_GAP + COMMENT_PAD.y) : type.row;
}

/** How high each row of a review is, for a type: the list places its rows by these. */
export function rowHeights(rows: readonly Row[], type: Type): number[] {
  return rows.map((row) => rowHeight(row, type));
}

function tint(colors: Theme, line: DiffLine): Color | null {
  if (line.sign === "+") return `${colors.ansi2}1c`;
  return line.sign === "-" ? `${colors.ansi1}1c` : null;
}

function lineNumber(colors: Theme, type: Type, number: number | null): Element {
  return div()
    .w(numbers(type))
    .flex_none()
    .text_right()
    .text_color(colors.dim)
    .child(number === null ? "" : String(number));
}

function lineRow(colors: Theme, type: Type, row: Extract<Row, { kind: "line" }>, active: boolean): Element {
  const { line } = row;
  const face = h_flex()
    .w_full()
    .h(type.row)
    .flex_none()
    .gap(Math.ceil(2 * type.char))
    .cursor_pointer()
    .hover((style) => style.bg(colors.hover))
    .child(
      h_flex()
        .h_full()
        .flex_none()
        .child(optional(div().w(MARK).h_full().flex_none(), edgeOf(colors, row, active), (el, color) => el.bg(color)))
        // One number, as the file has it now; a line the branch removes keeps the number it had.
        .child(lineNumber(colors, type, line.now ?? line.old)),
    )
    .child(
      div()
        .flex_1()
        .min_w(0)
        .whitespace_nowrap()
        .child(row.text || " "),
    );
  // The lines a comment is being written on stand out from the lines the branch adds.
  if (active) return face.bg(`${colors.accent}26`);
  return optional(face, tint(colors, line), (el, color) => el.bg(color));
}

/**
 * The color of a line's left edge. What is said about the line comes first:
 * the person's own comment stands out, a discussion on GitHub is quiet. Else
 * it is the line's own change: added or removed.
 */
function edgeOf(colors: Theme, row: Extract<Row, { kind: "line" }>, active: boolean): Color | null {
  if (row.commented || active) return colors.accent;
  if (row.discussed) return colors.muted;
  if (row.line.sign === "+") return colors.ansi2;
  return row.line.sign === "-" ? colors.ansi1 : null;
}

/**
 * A stretch of the file that the branch did not change, told in one row. Its
 * words start where the lines' text starts: a row is as wide as the longest
 * line of the diff, so words in its middle can be off the screen.
 */
function foldRow(colors: Theme, type: Type, text: string): Element {
  return h_flex()
    .w_full()
    .h(type.row)
    .flex_none()
    .pl(gutter(type))
    .items_center()
    .bg(colors.raised)
    .text_size(type.size - 1)
    .text_color(colors.dim)
    .child(text);
}

/** The color of a card's edge: one of GitHub is quiet, the person's own stands out, a misplaced one warns. */
function edge(colors: Theme, card: Card): Color {
  if (card.stale) return colors.blocked;
  return card.from === "github" ? colors.muted : colors.accent;
}

function cardRow(colors: Theme, type: Type, row: Card, columns: number): Element {
  return div()
    .w_full()
    .h(rowHeight(row, type))
    .flex_none()
    .pl(gutter(type))
    .py(COMMENT_GAP)
    .cursor_pointer()
    .child(
      v_flex()
        .w(Math.ceil(columns * type.char) + 2 * COMMENT_PAD.x)
        .h_full()
        .px(COMMENT_PAD.x)
        .py(COMMENT_PAD.y)
        .rounded(6)
        .bg(colors.raised)
        .border_l(2)
        .border_color(edge(colors, row))
        .text_color(colors.foreground)
        .children(
          row.lines.map((line) =>
            div()
              .h(type.row)
              .flex_none()
              .whitespace_nowrap()
              .when(line.head, (el) => el.text_color(colors.muted))
              .child(line.text || " "),
          ),
        ),
    );
}

function plainRow(colors: Theme, type: Type, text: string): Element {
  return div().w_full().h(type.row).flex_none().px(12).truncate().text_color(colors.dim).child(text);
}

export interface DiffPane {
  readonly rows: readonly Row[];
  /** How high each row is, from `rowHeights`. */
  readonly heights: number[];
  /** The longest line of the rows, in characters. */
  readonly widest: number;
  readonly type: Type;
  /** How many characters of a comment fit on one line. */
  readonly columns: number;
  readonly scroll: VirtualListScrollHandle;
  /** The keys of the lines the person writes a comment on. */
  readonly active: ReadonlySet<string>;
  /** A press on the diff, with whether Shift is held: a click on a row follows it. */
  readonly onPress: (shift: boolean) => void;
  /** A click on a row, by its key. */
  readonly onPick: (key: string, cx: Context) => void;
  /** The width the diff has on screen, in px of the mod. */
  readonly onWidth: (width: number, cx: Context) => void;
  /** A turn of the wheel over the diff: the file on show may be another one. */
  readonly onScroll: Handler;
}

/** The diff of every file, one after the other, with the comments under their lines. Only the rows on screen are drawn. */
export function diffPane(colors: Theme, props: DiffPane): Element {
  const { rows, type } = props;
  const draw = (row: Row): Element => {
    if (row.kind === "line") return lineRow(colors, type, row, props.active.has(row.key));
    if (row.kind === "card") return cardRow(colors, type, row, props.columns);
    if (row.kind === "file") return cardHead(colors, type, row.entry.file);
    return row.kind === "hunk" ? foldRow(colors, type, row.text) : plainRow(colors, type, row.text);
  };
  const list = v_virtual_list(
    "review-diff",
    rows.length,
    props.heights,
    (index) => rows[index]?.key ?? String(index),
    (range) => rows.slice(range.start, range.end).map(draw),
  )
    .track_scroll(props.scroll)
    .on_item_click(props.onPick)
    .size_full();
  return (
    div()
      .id("review-diff-box")
      .flex_1()
      .min_h(0)
      .relative()
      .font_family(type.family)
      .text_size(type.size)
      .on_size_change((size, cx) => props.onWidth(size.width / readZoom(), cx))
      // A click on a row of the list says which row, not which keys are held: the press before it does.
      .on_mouse_down("left", (event) => props.onPress(event.modifiers.shift))
      .on_scroll_wheel((_event, cx) => props.onScroll(cx))
      .child(
        div()
          .id("review-diff-x")
          .size_full()
          .overflow_x_scrollbar()
          .child(
            div()
              .w_full()
              .min_w(Math.ceil(props.widest * type.char) + gutter(type) + DIFF_END)
              .h_full()
              .child(list),
          ),
      )
      .child(Scrollbar.vertical("review-diff").viewport_from_layout().absolute().inset_0())
  );
}

function counts(colors: Theme, added: number, removed: number): Element[] {
  const count = (amount: number, sign: string, color: Color) =>
    div().flex_none().text_size(11).text_color(color).child(`${sign}${amount}`);
  return [
    ...(added > 0 ? [count(added, "+", colors.ansi2)] : []),
    ...(removed > 0 ? [count(removed, "−", colors.ansi1)] : []),
  ];
}

/** How many cards a file has: filled for the person's comments, an outline for the discussions on GitHub. */
function badge(colors: Theme, amount: number, own: boolean): Element {
  const face = div().px(5).h(16).flex().flex_none().items_center().rounded(8).text_size(10.5).font_semibold();
  if (own) return face.bg(colors.accent).text_color(colors.background).child(String(amount));
  return face.border_1().border_color(colors.input).text_color(colors.muted).child(String(amount));
}

type FolderRow = Extract<TreeRow, { kind: "folder" }>;
type FileRow = Extract<TreeRow, { kind: "file" }>;

/** The height of a row of the tree: it is dense, as a list of many files must be. */
const TREE_ROW = 24;

/** How far a row of the tree is from the left edge, for its depth. */
function inset(depth: number): number {
  return 8 + depth * 14;
}

function folderRow(colors: Theme, row: FolderRow, onFold: Handler): Element {
  return h_flex()
    .id(`review-folder-${row.path}`)
    .h(TREE_ROW)
    .flex_none()
    .pl(inset(row.depth))
    .pr(8)
    .gap(6)
    .items_center()
    .rounded(6)
    .cursor_pointer()
    .text_color(colors.muted)
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => onFold(cx))
    .child(svg(chromeIcon("folder")).size(12).flex_none())
    .child(div().min_w(0).truncate().child(row.name))
    .child(
      svg(chromeIcon(row.open ? "chevron-down" : "chevron-right"))
        .size(10)
        .flex_none()
        .text_color(colors.dim),
    );
}

/** The color of a file's name in the tree: a new file and a removed one stand out, as their lines do in the diff. */
function nameColor(colors: Theme, entry: ReviewFile): Color {
  if (entry.gone) return colors.blocked;
  if (entry.file.change === "added") return colors.ansi2;
  return entry.file.change === "deleted" ? colors.ansi1 : colors.foreground;
}

function fileRow(colors: Theme, row: FileRow, open: boolean, onOpen: Handler): Element {
  const { entry } = row;
  const { file } = entry;
  return h_flex()
    .id(`review-file-${file.path}`)
    .h(TREE_ROW)
    .flex_none()
    .pl(inset(row.depth) + 18)
    .pr(8)
    .gap(8)
    .items_center()
    .rounded(6)
    .cursor_pointer()
    .when(open, (el) => el.bg(colors.selected))
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => onOpen(cx))
    .child(div().flex_1().min_w(0).truncate().text_color(nameColor(colors, entry)).child(row.name))
    .when(entry.discussions.length > 0, (el) => el.child(badge(colors, entry.discussions.length, false)))
    .when(entry.comments.length > 0, (el) => el.child(badge(colors, entry.comments.length, true)))
    .children(counts(colors, file.added, file.removed));
}

export interface FileList {
  /** The files of the review as a tree, from the top. */
  readonly rows: readonly TreeRow[];
  /** Where the person types a part of a path, to see only the files that have it. */
  readonly filter: InputState;
  /** The path of the file whose diff shows. */
  readonly open: string | null;
  /** What the list says while it has no file. */
  readonly empty: string;
  readonly onOpen: (path: string, cx: Context) => void;
  /** A click on a folder, to fold it or to open it again. */
  readonly onFold: (path: string, cx: Context) => void;
}

export function fileList(colors: Theme, props: FileList): Element {
  const draw = (row: TreeRow): Element =>
    row.kind === "folder"
      ? folderRow(colors, row, (cx) => props.onFold(row.path, cx))
      : fileRow(colors, row, row.entry.file.path === props.open, (cx) => props.onOpen(row.entry.file.path, cx));
  const filter = Input.new(props.filter)
    .h(26)
    .flex_none()
    .mx(6)
    .mt(6)
    .px(8)
    .rounded(6)
    .border_1()
    .border_color(colors.border)
    .text_size(12)
    .text_color(colors.foreground);
  const tree = v_flex()
    .id("review-files")
    .flex_1()
    .min_h(0)
    .p(6)
    .overflow_y_scrollbar()
    .children(props.rows.map(draw))
    .when(props.rows.length === 0, (el) =>
      el.child(div().p(8).text_size(12).text_color(colors.muted).child(props.empty)),
    );
  return v_flex()
    .w(300)
    .h_full()
    .flex_none()
    .border_r(1)
    .border_color(colors.border)
    .text_size(12)
    .child(filter)
    .child(tree);
}

export interface ReviewHead {
  readonly title: string;
  /** The branch and what it is compared with: "fix-it → origin/main". */
  readonly range: string | null;
  readonly files: readonly DiffFile[];
  readonly loading: boolean;
  readonly onRefresh: Handler;
  readonly onClose: Handler;
}

export interface PullStrip {
  /** The pull requests the person can review, the lowest of a stack first. */
  readonly choices: Stack;
  /** The one whose diff shows. */
  readonly shown: Pull | null;
  readonly onPick: (pull: Pull, cx: Context) => void;
}

/** One pull request of a stack, as a tab: its number, its title, and where it stands. */
function pullTab(colors: Theme, pull: Pull, shown: boolean, onPick: Handler): Element {
  return h_flex()
    .id(`review-pull-${pull.number}`)
    .h(24)
    .max_w(340)
    .min_w(0)
    .px(8)
    .gap(6)
    .items_center()
    .rounded(6)
    .text_size(11.5)
    .cursor_pointer()
    .when(shown, (el) => el.bg(colors.selected))
    .text_color(shown ? colors.foreground : colors.muted)
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => onPick(cx))
    .child(div().flex_none().font_medium().child(`#${pull.number}`))
    .child(div().min_w(0).truncate().child(pull.title))
    .child(div().flex_none().text_color(colors.dim).child(stageLabel(pull.stage)));
}

/** The strip under the review's head, for a thread with a stack: one tab for each open pull request. None for one. */
export function pullStrip(colors: Theme, props: PullStrip): Element[] {
  if (props.choices.length < 2) return [];
  const tabs = props.choices.map((pull) =>
    pullTab(colors, pull, pull.url === props.shown?.url, (cx) => props.onPick(pull, cx)),
  );
  return [
    h_flex().h(34).flex_none().px(10).gap(4).items_center().border_b(1).border_color(colors.border).children(tabs),
  ];
}

export function reviewHead(colors: Theme, props: ReviewHead): Element {
  const added = props.files.reduce((sum, file) => sum + file.added, 0);
  const removed = props.files.reduce((sum, file) => sum + file.removed, 0);
  const bar = h_flex()
    .h(44)
    .flex_none()
    .px(14)
    .gap(8)
    .items_center()
    .border_b(1)
    .border_color(colors.border)
    .text_size(13)
    .child(svg(chromeIcon("git-compare")).size(14).flex_none().text_color(colors.muted))
    .child(div().flex_none().font_semibold().child("Review"))
    .child(div().min_w(0).truncate().text_color(colors.muted).child(props.title));
  return optional(bar, props.range, (el, range) =>
    el.child(
      div()
        .flex_none()
        .px(6)
        .py(1)
        .rounded(4)
        .border_1()
        .border_color(colors.border)
        .text_size(11)
        .text_color(colors.muted)
        .child(range),
    ),
  )
    .children(counts(colors, added, removed))
    .child(div().flex_1())
    .child(
      props.loading
        ? svg(chromeIcon("spinner")).size(13).flex_none().text_color(colors.working).spin(900)
        : iconButton(colors, {
            id: "review-refresh",
            icon: "mods/projects/refresh.svg",
            tip: "Read the diff again",
            onClick: props.onRefresh,
          }),
    )
    .child(iconButton(colors, { id: "review-close", icon: chromeIcon("x"), tip: "Close", onClick: props.onClose }));
}

/** The head of a file's card in the diff: its name, its folder, where it moved from, and how much of it changed. */
function cardHead(colors: Theme, type: Type, file: DiffFile): Element {
  const cut = file.path.lastIndexOf("/");
  const bar = h_flex()
    .w_full()
    .h(FILE_HEAD)
    .px(12)
    .gap(8)
    .items_center()
    .bg(colors.raised)
    .border_t(1)
    .border_b(1)
    .border_color(colors.border)
    .text_size(type.size - 1)
    .text_color(colors.foreground)
    .child(
      div()
        .flex_none()
        .child(file.path.slice(cut + 1)),
    )
    .child(
      div()
        .min_w(0)
        .truncate()
        .text_color(colors.muted)
        .child(file.path.slice(0, cut + 1)),
    );
  const head = optional(bar, file.from, (el, from) =>
    el.child(div().min_w(0).truncate().text_color(colors.dim).child(`from ${from}`)),
  )
    // The counts follow the name: a row is as wide as the diff's longest line, so its right end can be off the screen.
    .children(counts(colors, file.added, file.removed));
  // The gap over the head sets a file's card apart from the one over it.
  return div()
    .w_full()
    .h(FILE_GAP + FILE_HEAD)
    .flex_none()
    .pt(FILE_GAP)
    .child(head);
}

export interface Composer {
  /** The line the comment is on, in words: "Line 12". */
  readonly where: string;
  /** The text of that line. */
  readonly code: string;
  readonly type: Type;
  readonly field: TextareaState;
  readonly buttons: readonly TextButton[];
}

/** Where the person writes the comment of one line, under the diff. */
export function composer(colors: Theme, props: Composer): Element {
  return v_flex()
    .id("review-composer")
    .flex_none()
    .p(10)
    .gap(8)
    .border_t(1)
    .border_color(colors.border)
    .bg(colors.chrome)
    .child(
      h_flex()
        .gap(8)
        .items_center()
        .text_size(11.5)
        .child(div().flex_none().text_color(colors.muted).child(props.where))
        .child(
          div()
            .flex_1()
            .min_w(0)
            .truncate()
            .font_family(props.type.family)
            .text_color(colors.dim)
            .child(props.code.trim()),
        ),
    )
    .child(
      Textarea.new(props.field)
        .h(96)
        .p(8)
        .rounded(8)
        .border_1()
        .border_color(colors.input)
        .bg(colors.background)
        .text_size(12.8)
        .text_color(colors.foreground),
    )
    .child(
      h_flex()
        .gap(8)
        .justify_end()
        .children(props.buttons.map((button) => textButton(colors, button))),
    );
}

export interface ReviewFoot {
  readonly note: InputState;
  /** What went wrong with the last try to send. */
  readonly error: string | null;
  readonly send: TextButton;
}

/** The strip under the review: a word on the whole branch, and the button that sends it all. */
export function reviewFoot(colors: Theme, props: ReviewFoot): Element {
  const bar = h_flex()
    .flex_none()
    .p(10)
    .gap(10)
    .items_center()
    .border_t(1)
    .border_color(colors.border)
    .child(
      Input.new(props.note)
        .flex_1()
        .min_w(0)
        .h(32)
        .px(10)
        .rounded(8)
        .border_1()
        .border_color(colors.input)
        .bg(colors.background)
        .text_size(12.5)
        .text_color(colors.foreground),
    );
  return optional(bar, props.error, (el, error) =>
    // An error can be a few lines, such as what GitHub answers: it is shown whole.
    el.child(div().max_w(520).text_size(11.5).text_color(colors.blocked).child(error)),
  ).child(textButton(colors, props.send));
}
