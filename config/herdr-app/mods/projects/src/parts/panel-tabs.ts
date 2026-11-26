import { div, type Element } from "gpui-kit";
import { h_flex } from "gpui-base";
import { THREAD } from "../layout-tree";
import { showThreadList } from "../navigation";
import { readPanel, selectPanel, type Panel } from "../panel";
import { waitingOn } from "../projects";
import { readScene } from "../snapshot";
import { readTheme, type Theme } from "../ui";
import type { Part } from "./part";

interface Tab {
  readonly id: Panel;
  readonly label: string;
}

const TABS: readonly Tab[] = [
  { id: "threads", label: "Threads" },
  { id: "files", label: "Files" },
  { id: "changes", label: "Changes" },
];

/** An open thread is part of Threads: the tab stays lit, and a click on it shows the list again. */
function isActive(tab: Tab, active: string | null): boolean {
  return tab.id === active || (tab.id === "threads" && active === THREAD);
}

/** Threads shows the list again, which the project remembers; the other tabs only switch. */
function open(tab: Tab): void {
  if (tab.id === "threads") showThreadList();
  else selectPanel(tab.id);
}

function badge(colors: Theme, count: number): Element {
  return div()
    .px(5)
    .h(16)
    .flex()
    .items_center()
    .rounded(8)
    .bg(colors.blocked)
    .text_size(10.5)
    .font_semibold()
    .text_color(colors.background)
    .child(String(count));
}

function tabButton(colors: Theme, tab: Tab, active: boolean, count: number, onClick: () => void): Element {
  return h_flex()
    .id(`panel-tab-${tab.id}`)
    .h(26)
    .px(10)
    .gap(6)
    .flex_none()
    .items_center()
    .rounded(7)
    .text_size(12.5)
    .cursor_pointer()
    .when(active, (el) => el.bg(colors.selected))
    .text_color(active ? colors.foreground : colors.muted)
    .hover((style) => style.bg(colors.hover))
    .on_click(onClick)
    .child(tab.label)
    .when(count > 0, (el) => el.child(badge(colors, count)));
}

/** The tab strip over the right panel. */
export const panelTabs: Part = {
  render(): Element {
    const colors = readTheme();
    const { active } = readPanel();
    const { shown } = readScene();
    const waiting = shown ? waitingOn(shown) : 0;
    return h_flex()
      .size_full()
      .px(8)
      .gap(2)
      .items_center()
      .bg(colors.chrome)
      .children(
        TABS.map((tab) =>
          tabButton(colors, tab, isActive(tab, active), tab.id === "threads" ? waiting : 0, () => open(tab)),
        ),
      );
  },
};
