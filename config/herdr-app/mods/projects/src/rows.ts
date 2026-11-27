import { div, svg, type Context, type Element } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import type { Entry } from "./entries";
import { stackLabel } from "./pulls";
import { groupLabel } from "./status";
import { threadGroup, type Thread } from "./threads";
import { age } from "./time";
import { chromeIcon, iconButton, markBox, optional, resolveTip, statusMark, type Handler, type Theme } from "./ui";

/** Opens the row's menu on a right click. */
function withMenu(row: Element, onMenu: Handler): Element {
  return row.on_mouse_down("right", (_event, cx) => {
    cx.stop_propagation();
    onMenu(cx);
  });
}

export interface EntryActions {
  readonly onOpen: Handler;
  readonly onMenu: Handler;
  /** A press starts a drag of the entry; a release on another entry drops the dragged one there. */
  readonly onPress: Handler;
  readonly onDrop: Handler;
}

export function entryRow(colors: Theme, entry: Entry, actions: EntryActions): Element {
  const needsYou = entry.status === "blocked";
  const row = h_flex()
    .id(entry.id)
    .px(8)
    .py(5)
    .flex_none()
    .gap(7)
    .items_center()
    .rounded(8)
    .cursor_pointer()
    .when(entry.selected, (el) => el.bg(colors.selected))
    .hover((style) => style.bg(colors.hover))
    .on_click((_event, cx) => actions.onOpen(cx))
    .on_mouse_down("left", (_event, cx) => actions.onPress(cx))
    .on_mouse_up("left", (_event, cx) => actions.onDrop(cx))
    .child(statusMark(colors, entry.status))
    .child(
      v_flex()
        .flex_1()
        .min_w(0)
        .child(
          h_flex()
            .gap(6)
            .items_center()
            .child(
              div()
                .flex_1()
                .min_w(0)
                .truncate()
                .text_color(entry.selected || needsYou ? colors.foreground : colors.muted)
                .when(needsYou, (el) => el.font_medium())
                .child(entry.name),
            )
            .child(div().flex_none().text_size(10.5).text_color(colors.muted).child(entry.aside)),
        )
        .child(div().truncate().text_size(11).text_color(colors.muted).child(entry.detail)),
    );
  return withMenu(row, actions.onMenu);
}

export interface ThreadView {
  readonly hovered: boolean;
  /** The time now, in ms since the epoch, for the row's age. */
  readonly now: number;
}

export interface ThreadActions {
  readonly onOpen: Handler;
  readonly onHover: (hovered: boolean, cx: Context) => void;
  readonly onResolve: Handler;
  /** Set for a thread that owns a tab. */
  readonly onMenu?: Handler;
}

function threadMark(colors: Theme, thread: Thread): Element {
  if (thread.agent) return statusMark(colors, thread.status ?? "idle");
  return markBox(svg(chromeIcon("terminal")).size(11).text_color(colors.dim));
}

/** Where it runs, its pull requests, then how long it has been in its state. */
function threadMeta(thread: Thread, now: number): string {
  const since = thread.since === null ? null : age(now - thread.since);
  return [thread.aside, stackLabel(thread.pulls), since].filter((part) => part !== null).join(" · ");
}

/** Whose move it is, in words, with where the thread runs and for how long: for a place that shows one thread. */
export function threadState(thread: Thread, now: number): string {
  return [groupLabel(threadGroup(thread)), threadMeta(thread, now)].filter(Boolean).join(" · ");
}

function resolveButton(colors: Theme, thread: Thread, onResolve: Handler): Element {
  return iconButton(colors, {
    id: `resolve-${thread.key}`,
    icon: chromeIcon(thread.resolved ? "x" : "check"),
    tip: resolveTip(thread.resolved),
    small: true,
    onClick: onResolve,
  });
}

export function threadRow(colors: Theme, thread: Thread, view: ThreadView, actions: ThreadActions): Element {
  const strong = thread.active || thread.status === "blocked";
  const trailing = view.hovered
    ? resolveButton(colors, thread, actions.onResolve)
    : div().flex_none().text_size(11).text_color(colors.muted).child(threadMeta(thread, view.now));
  const row = v_flex()
    .id(`thread-${thread.key}`)
    .px(10)
    .py(7)
    .flex_none()
    .gap(2)
    .rounded(8)
    .cursor_pointer()
    .when(thread.active, (el) => el.bg(colors.selected))
    .hover((style) => style.bg(colors.hover))
    .on_hover((on, cx) => actions.onHover(on, cx))
    .on_click((_event, cx) => actions.onOpen(cx))
    .child(
      h_flex()
        .h(22)
        .gap(7)
        .items_center()
        .child(threadMark(colors, thread))
        .child(
          div()
            .flex_1()
            .min_w(0)
            .truncate()
            .text_color(strong ? colors.foreground : colors.muted)
            .child(thread.title),
        )
        .child(trailing),
    );
  const noted = optional(row, thread.note, (el, note) =>
    el.child(
      div()
        .pl(21)
        .truncate()
        .text_size(11.5)
        .text_color(thread.status === "blocked" ? colors.blocked : colors.muted)
        .child(note),
    ),
  );
  return optional(noted, actions.onMenu, withMenu);
}
