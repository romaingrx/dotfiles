import type { Context, Element } from "gpui-kit";

/** One of the mod's faces: a block of the layout, or an overlay. A layout or `openOverlay` picks it with `props.part`. */
export interface Part {
  render(cx: Context): Element;
}
