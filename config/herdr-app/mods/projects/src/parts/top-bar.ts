import type { Element } from "gpui-kit";
import { h_flex } from "gpui-base";
import { window } from "herdr";
import { readPanel, togglePanel } from "../panel";
import { chromeIcon, iconButton, readTheme } from "../ui";
import type { Part } from "./part";

/** Room for the macOS window buttons, which sit over the sidebar. */
const WINDOW_BUTTONS = 76;
const EDGE = 12;

/** The strip over the project list: it drags the window and shows or hides the right panel. */
export const topBar: Part = {
  render(): Element {
    const colors = readTheme();
    const frame = window();
    const hasWindowButtons = frame?.platform === "macos" && !frame.fullscreen;
    return h_flex()
      .size_full()
      .pl(hasWindowButtons ? WINDOW_BUTTONS : EDGE)
      .pr(EDGE)
      .items_center()
      .justify_end()
      .bg(colors.chrome)
      .child(
        iconButton(colors, {
          id: "toggle-panel",
          icon: chromeIcon("panel-right"),
          tip: "Threads panel",
          active: !readPanel().hidden,
          onClick: togglePanel,
        }),
      );
  },
};
