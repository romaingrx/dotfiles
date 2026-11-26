import { div, type Element } from "gpui-kit";
import { h_flex } from "gpui-base";
import { canRename, openLink, openReview, renameThread, setResolved } from "../actions";
import type { Drawer } from "../layout-tree";
import { showThreadList } from "../navigation";
import { readPanel, toggleDrawer } from "../panel";
import { leadPull } from "../pulls";
import { threadState } from "../rows";
import { readScene } from "../snapshot";
import { threadAt, type Thread } from "../threads";
import { chromeIcon, iconButton, optional, readTheme, resolveTip, statusMark, type Theme } from "../ui";
import type { Part } from "./part";

const DRAWERS: readonly { readonly id: Drawer; readonly tip: string; readonly icon: string }[] = [
  { id: "thread-files", tip: "Files of this thread", icon: "mods/files/file.svg" },
  { id: "thread-changes", tip: "Changes of this thread", icon: "mods/changes/changes.svg" },
];

function drawerButtons(colors: Theme, shown: string | null): Element[] {
  return DRAWERS.map((drawer) =>
    iconButton(colors, {
      id: drawer.id,
      icon: drawer.icon,
      tip: drawer.tip,
      active: shown === drawer.id,
      onClick: () => toggleDrawer(drawer.id),
    }),
  );
}

function controls(colors: Theme, thread: Thread): Element[] {
  const rename = iconButton(colors, {
    id: "rename",
    icon: chromeIcon("square-pen"),
    tip: "Rename",
    onClick: () => renameThread(thread),
  });
  const resolve = iconButton(colors, {
    id: "resolve",
    icon: chromeIcon("circle-check"),
    tip: resolveTip(thread.resolved),
    active: thread.resolved,
    onClick: () => {
      setResolved(thread, !thread.resolved);
      showThreadList();
    },
  });
  const pull = leadPull(thread.pulls);
  const link = pull
    ? [
        iconButton(colors, {
          id: "pull-request",
          icon: chromeIcon("git-branch"),
          tip: `Open pull request #${pull.number}`,
          onClick: () => openLink(pull.url),
        }),
      ]
    : [];
  const review = iconButton(colors, {
    id: "review",
    icon: chromeIcon("git-compare"),
    tip: "Review its branch",
    onClick: () => openReview(thread.key),
  });
  return [...(thread.checkout ? [review] : []), ...link, ...(canRename(thread) ? [rename] : []), resolve];
}

/** The strip over an open thread: back to the list, its name and state, its drawers, review, rename and resolve. */
export const threadHead: Part = {
  render(): Element {
    const colors = readTheme();
    const panel = readPanel();
    const { snapshot, projects } = readScene();
    const thread = threadAt(snapshot, projects, panel.thread);
    const bar = h_flex()
      .size_full()
      .px(8)
      .gap(6)
      .items_center()
      .bg(colors.chrome)
      .text_size(12.5)
      .child(iconButton(colors, { id: "back", icon: chromeIcon("chevron-left"), tip: "All threads", onClick: showThreadList }))
      .child(statusMark(colors, thread?.status ?? null))
      .child(
        div()
          .flex_1()
          .min_w(0)
          .truncate()
          .text_color(thread ? colors.foreground : colors.dim)
          .child(thread?.title ?? "This thread has ended."),
      );
    return optional(bar, thread, (el, open) =>
      el
        .child(div().flex_none().text_size(11).text_color(colors.muted).child(threadState(open, Date.now())))
        .children([...drawerButtons(colors, panel.drawer), ...controls(colors, open)]),
    );
  },
};
