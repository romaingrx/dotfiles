import { div, type AsyncContext, type Color, type Element } from "gpui-kit";
import { h_flex, Input, v_flex, type InputState } from "gpui-base";
import { optional, textButton, type TextButton, type Theme } from "./ui";

export interface Dialog {
  readonly id: string;
  readonly title: string;
  readonly hint?: string;
  /** What went wrong with the last try, shown above the buttons. */
  readonly error: string | null;
  readonly fields: readonly Element[];
  readonly buttons: readonly TextButton[];
}

/** The app can show a dialog before it can take the keyboard: ask again shortly after. */
const REFOCUS_AFTER = 600;

/** Puts the keyboard in a dialog's field when the dialog opens. */
export function focusSoon(input: InputState, cx: AsyncContext): void {
  input.focus();
  cx.timer.after(REFOCUS_AFTER, () => input.focus());
}

export function label(colors: Theme, text: string): Element {
  return div().pt(4).text_size(11.5).text_color(colors.dim).child(text);
}

export function textField(colors: Theme, state: InputState, invalid: boolean): Element {
  return Input.new(state)
    .h(36)
    .px(10)
    .rounded(9)
    .border_1()
    .border_color(invalid ? colors.blocked : colors.input)
    .bg(colors.background)
    .text_size(12.8)
    .text_color(colors.foreground);
}

function line(color: Color, text: string): Element {
  return div().text_size(11.5).text_color(color).child(text);
}

/** The frame of the mod's dialogs: a title, fields, an error line and buttons. */
export function dialog(colors: Theme, props: Dialog): Element {
  const head = v_flex()
    .id(props.id)
    .w_full()
    .p(18)
    .gap(8)
    .bg(colors.popover)
    .text_color(colors.foreground)
    .child(div().text_size(15).font_semibold().child(props.title));
  const fields = optional(head, props.hint, (el, hint) => el.child(line(colors.dim, hint))).children([...props.fields]);
  return optional(fields, props.error, (el, error) => el.child(line(colors.blocked, error))).child(
    h_flex()
      .pt(8)
      .gap(8)
      .justify_end()
      .children(props.buttons.map((button) => textButton(colors, button))),
  );
}
