import { div, svg, type Color, type Context, type Element } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme } from "herdr";
import type { Status } from "herdr";

const COLOR_NAMES = [
  "background",
  "chrome",
  "popover",
  "raised",
  "selected",
  "hover",
  "border",
  "input",
  "foreground",
  "muted",
  "dim",
  "accent",
  "solid",
  "solid_foreground",
  "blocked",
  "working",
  "done",
] as const;

export type Theme = Readonly<Record<(typeof COLOR_NAMES)[number], Color>>;

export type Handler = (cx: Context) => void;

function isColor(value: unknown): value is Color {
  return typeof value === "string" && value.startsWith("#");
}

/** The theme's colors that this mod draws with. Every Herdr theme names them all. */
export function readTheme(): Theme {
  const all: Record<string, unknown> = theme();
  const colors = COLOR_NAMES.map((name) => {
    const color = all[name];
    if (!isColor(color)) throw new Error(`the theme has no color "${name}"`);
    return [name, color] as const;
  });
  return Object.fromEntries(colors) as Theme;
}

/** An icon of the shipped sidebar, by name. */
export function chromeIcon(name: string): string {
  return `mods/workspace-chrome/${name}.svg`;
}

/** A dot for a state that asks for attention, a ring for idle, a blank for none. */
export function statusMark(colors: Theme, status: Status | null): Element {
  const dot = div().size(7).flex_none().rounded(4);
  if (status === null) return dot;
  if (status === "idle") return dot.border(1.5).border_color(colors.dim);
  return dot.bg(colors[status]);
}

export interface IconButton {
  readonly id: string;
  readonly icon: string;
  readonly tip: string;
  readonly active?: boolean;
  /** Set for a button inside a row of a list. */
  readonly small?: boolean;
  readonly onClick: Handler;
}

const ICON_BUTTON = { regular: { box: 24, icon: 14, corner: 6 }, small: { box: 18, icon: 13, corner: 4 } } as const;

export function iconButton(colors: Theme, button: IconButton): Element {
  const size = ICON_BUTTON[button.small ? "small" : "regular"];
  return div()
    .id(button.id)
    .size(size.box)
    .flex_none()
    .flex()
    .items_center()
    .justify_center()
    .rounded(size.corner)
    .when(button.active === true, (el) => el.bg(colors.selected))
    .text_color(button.active ? colors.foreground : colors.muted)
    .hover((style) => style.bg(colors.hover).text_color(colors.foreground))
    .tooltip(button.tip)
    .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
    .on_click((_event, cx) => {
      cx.stop_propagation();
      button.onClick(cx);
    })
    .child(svg(button.icon).size(size.icon));
}

/** What the button that puts a thread away, or brings it back, says it does. */
export function resolveTip(resolved: boolean): string {
  return resolved ? "Reopen" : "Mark resolved";
}

export interface Heading {
  readonly id: string;
  readonly label: string;
  readonly count?: number;
  /** Set for a heading that folds its section. */
  readonly fold?: { readonly open: boolean; readonly onToggle: Handler };
  /** A button at the right end, such as "new". */
  readonly action?: IconButton;
}

export function heading(colors: Theme, props: Heading): Element {
  const label = props.count === undefined ? props.label : `${props.label} · ${props.count}`;
  const bar = h_flex()
    .id(props.id)
    .px(8)
    .h(30)
    .flex_none()
    .gap(5)
    .items_center()
    .text_size(11.5)
    .font_medium()
    .text_color(colors.dim)
    .child(label);
  const folding = optional(bar, props.fold, (el, fold) =>
    el
      .cursor_pointer()
      .hover((style) => style.text_color(colors.foreground))
      .on_click((_event, cx) => fold.onToggle(cx))
      .child(svg(chromeIcon(fold.open ? "chevron-down" : "chevron-right")).size(11).flex_none()),
  );
  return optional(folding.child(div().flex_1()), props.action, (el, action) => el.child(iconButton(colors, action)));
}

export interface TextButton {
  readonly id: string;
  readonly label: string;
  readonly primary?: boolean;
  readonly onClick: Handler;
}

export function textButton(colors: Theme, button: TextButton): Element {
  return h_flex()
    .id(button.id)
    .h(32)
    .px(14)
    .items_center()
    .rounded(8)
    .border_1()
    .border_color(button.primary ? colors.solid : colors.input)
    .bg(button.primary ? colors.solid : colors.raised)
    .text_color(button.primary ? colors.solid_foreground : colors.foreground)
    .text_size(12.5)
    .font_medium()
    .cursor_pointer()
    .hover((style) => style.opacity(0.88))
    .on_click((_event, cx) => button.onClick(cx))
    .child(button.label);
}

export interface MenuItem {
  readonly id: string;
  readonly icon: string;
  readonly label: string;
  readonly onClick: Handler;
}

export function menuItem(colors: Theme, item: MenuItem): Element {
  return h_flex()
    .id(item.id)
    .h(31)
    .px(8)
    .gap(9)
    .rounded(7)
    .items_center()
    .text_color(colors.foreground)
    .cursor_pointer()
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => item.onClick(cx))
    .child(svg(item.icon).size(14).flex_none().text_color(colors.muted))
    .child(div().flex_1().child(item.label));
}

/** Adds what `add` makes of `value` to the element, when there is a value. */
export function optional<T>(el: Element, value: T | null | undefined, add: (el: Element, value: T) => Element): Element {
  return value === null || value === undefined ? el : add(el, value);
}
