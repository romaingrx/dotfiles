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
import { chromeIcon, iconButton, optional, textButton, type Handler, type TextButton, type Theme } from "../ui";
import type { Change, DiffFile, DiffLine } from "./diff";
import type { ReviewFile, Row } from "./rows";

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
const SIGN = 2;
const COMMENT_GAP = 4;
const COMMENT_PAD = { x: 10, y: 6 };
const DIFF_END = 16;

/** The room left of a line's text: the comment mark, the two line numbers and the sign. */
function gutter(type: Type): number {
  return MARK + Math.ceil((2 * (NUMBER_DIGITS + 1) + SIGN) * type.char);
}

/** How many characters of a comment fit on one line, in a diff that is `width` wide. */
export function commentColumns(width: number, type: Type): number {
  const room = width - gutter(type) - 2 * COMMENT_PAD.x - DIFF_END;
  return Math.max(24, Math.floor(room / type.char));
}

function rowHeight(row: Row, type: Type): number {
  return row.kind === "comment" ? row.lines.length * type.row + 2 * (COMMENT_GAP + COMMENT_PAD.y) : type.row;
}

function tint(colors: Theme, line: DiffLine): Color | null {
  if (line.sign === "+") return `${colors.ansi2}1c`;
  return line.sign === "-" ? `${colors.ansi1}1c` : null;
}

function lineNumber(colors: Theme, type: Type, number: number | null): Element {
  return div()
    .w(Math.ceil((NUMBER_DIGITS + 1) * type.char))
    .flex_none()
    .text_right()
    .text_color(colors.dim)
    .child(number === null ? "" : String(number));
}

function lineRow(colors: Theme, type: Type, row: Extract<Row, { kind: "line" }>, active: boolean): Element {
  const { line } = row;
  const marked = row.commented || active;
  const face = h_flex()
    .w_full()
    .h(type.row)
    .flex_none()
    .cursor_pointer()
    .hover((style) => style.bg(colors.hover))
    .child(
      div()
        .w(MARK)
        .h_full()
        .flex_none()
        .when(marked, (el) => el.bg(colors.accent)),
    )
    .child(lineNumber(colors, type, line.old))
    .child(lineNumber(colors, type, line.now))
    .child(
      div()
        .w(Math.ceil(SIGN * type.char))
        .flex_none()
        .text_center()
        .text_color(colors.dim)
        .child(line.sign),
    )
    .child(
      div()
        .flex_1()
        .min_w(0)
        .whitespace_nowrap()
        .child(row.text || " "),
    );
  if (active) return face.bg(colors.selected);
  return optional(face, tint(colors, line), (el, color) => el.bg(color));
}

function commentRow(colors: Theme, type: Type, row: Extract<Row, { kind: "comment" }>, columns: number): Element {
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
        .border_color(row.stale ? colors.blocked : colors.accent)
        .text_color(colors.foreground)
        .children(
          row.lines.map((line) =>
            div()
              .h(type.row)
              .flex_none()
              .whitespace_nowrap()
              .child(line || " "),
          ),
        ),
    );
}

function plainRow(colors: Theme, type: Type, text: string, raised: boolean): Element {
  return div()
    .w_full()
    .h(type.row)
    .flex_none()
    .px(12)
    .truncate()
    .when(raised, (el) => el.bg(colors.raised))
    .text_color(colors.dim)
    .child(text);
}

export interface DiffPane {
  readonly rows: readonly Row[];
  /** The longest line of the rows, in characters. */
  readonly widest: number;
  readonly type: Type;
  /** How many characters of a comment fit on one line. */
  readonly columns: number;
  readonly scroll: VirtualListScrollHandle;
  /** The key of the row the person writes a comment on. */
  readonly active: string | null;
  /** A click on a row, by its key. */
  readonly onPick: (key: string, cx: Context) => void;
  /** The width the diff has on screen, in px of the mod. */
  readonly onWidth: (width: number, cx: Context) => void;
}

/** One file's diff: its lines with the comments under them. Only the rows on screen are drawn. */
export function diffPane(colors: Theme, props: DiffPane): Element {
  const { rows, type } = props;
  const draw = (row: Row): Element => {
    if (row.kind === "line") return lineRow(colors, type, row, row.key === props.active);
    if (row.kind === "comment") return commentRow(colors, type, row, props.columns);
    return plainRow(colors, type, row.text, row.kind === "hunk");
  };
  const list = v_virtual_list(
    "review-diff",
    rows.length,
    rows.map((row) => rowHeight(row, type)),
    (index) => rows[index]?.key ?? String(index),
    (range) => rows.slice(range.start, range.end).map(draw),
  )
    .track_scroll(props.scroll)
    .on_item_click(props.onPick)
    .size_full();
  return div()
    .id("review-diff-box")
    .flex_1()
    .min_h(0)
    .relative()
    .font_family(type.family)
    .text_size(type.size)
    .on_size_change((size, cx) => props.onWidth(size.width / readZoom(), cx))
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
    .child(Scrollbar.vertical("review-diff").viewport_from_layout().absolute().inset_0());
}

const CHANGES: Readonly<Record<Change, { readonly letter: string; readonly tone: "ansi1" | "ansi2" | "muted" }>> = {
  added: { letter: "A", tone: "ansi2" },
  deleted: { letter: "D", tone: "ansi1" },
  modified: { letter: "M", tone: "muted" },
  renamed: { letter: "R", tone: "muted" },
};

function counts(colors: Theme, added: number, removed: number): Element[] {
  const count = (amount: number, sign: string, color: Color) =>
    div().flex_none().text_size(11).text_color(color).child(`${sign}${amount}`);
  return [
    ...(added > 0 ? [count(added, "+", colors.ansi2)] : []),
    ...(removed > 0 ? [count(removed, "−", colors.ansi1)] : []),
  ];
}

function badge(colors: Theme, amount: number): Element {
  return div()
    .px(5)
    .h(16)
    .flex()
    .flex_none()
    .items_center()
    .rounded(8)
    .bg(colors.accent)
    .text_size(10.5)
    .font_semibold()
    .text_color(colors.background)
    .child(String(amount));
}

/** A path as a name, then its folder, drawn faint: the name is what a narrow list must keep. */
function pathLabel(colors: Theme, path: string): Element {
  const cut = path.lastIndexOf("/");
  return h_flex()
    .flex_1()
    .min_w(0)
    .gap(6)
    .child(
      div()
        .flex_none()
        .max_w(190)
        .truncate()
        .child(path.slice(cut + 1)),
    )
    .child(
      div()
        .min_w(0)
        .truncate()
        .text_color(colors.dim)
        .child(path.slice(0, Math.max(cut, 0))),
    );
}

function fileRow(colors: Theme, entry: ReviewFile, open: boolean, onOpen: Handler): Element {
  const { file } = entry;
  const change = CHANGES[file.change];
  return h_flex()
    .id(`review-file-${file.path}`)
    .h(28)
    .flex_none()
    .px(8)
    .gap(8)
    .items_center()
    .rounded(7)
    .cursor_pointer()
    .when(open, (el) => el.bg(colors.selected))
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => onOpen(cx))
    .child(
      div()
        .w(12)
        .flex_none()
        .text_size(11)
        .text_color(colors[entry.gone ? "blocked" : change.tone])
        .child(entry.gone ? "!" : change.letter),
    )
    .child(pathLabel(colors, file.path))
    .when(entry.comments.length > 0, (el) => el.child(badge(colors, entry.comments.length)))
    .children(counts(colors, file.added, file.removed));
}

export interface FileList {
  readonly files: readonly ReviewFile[];
  /** The path of the file whose diff shows. */
  readonly open: string | null;
  /** What the list says while it has no file. */
  readonly empty: string;
  readonly onOpen: (path: string, cx: Context) => void;
}

export function fileList(colors: Theme, props: FileList): Element {
  return v_flex()
    .id("review-files")
    .w(300)
    .h_full()
    .flex_none()
    .p(6)
    .border_r(1)
    .border_color(colors.border)
    .text_size(12.5)
    .overflow_y_scrollbar()
    .children(
      props.files.map((entry) =>
        fileRow(colors, entry, entry.file.path === props.open, (cx) => props.onOpen(entry.file.path, cx)),
      ),
    )
    .when(props.files.length === 0, (el) =>
      el.child(div().p(8).text_size(12).text_color(colors.muted).child(props.empty)),
    );
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
    .child(div().flex_1())
    .children(counts(colors, added, removed))
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

/** The strip over a file's diff: its path, and where it moved from. */
export function fileHead(colors: Theme, type: Type, file: DiffFile): Element {
  const bar = h_flex()
    .h(32)
    .flex_none()
    .px(12)
    .gap(8)
    .items_center()
    .border_b(1)
    .border_color(colors.border)
    .font_family(type.family)
    .text_size(12)
    .child(div().min_w(0).truncate().child(file.path));
  return optional(bar, file.from, (el, from) =>
    el.child(div().min_w(0).truncate().text_color(colors.dim).child(`from ${from}`)),
  );
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
    el.child(div().max_w(360).truncate().text_size(11.5).text_color(colors.blocked).child(error)),
  ).child(textButton(colors, props.send));
}
