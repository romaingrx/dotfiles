import type { AsyncContext, Context, Element } from "gpui-kit";
import { InputState } from "gpui-base";
import { closeOverlay } from "herdr";
import { renameProject, reportFailureOf } from "../actions";
import { dialog, focusSoon, textField } from "../dialog";
import { nameProblem } from "../projects";
import { readScene } from "../snapshot";
import { readTheme } from "../ui";
import type { Part } from "./part";

/** A dialog that gives a project another name. */
export class RenameProjectDialog implements Part {
  private readonly input: InputState;
  private error: string | null = null;

  constructor(
    private readonly overlay: string,
    private readonly project: string,
    cx: AsyncContext,
  ) {
    this.input = InputState.new({ value: project });
    this.input.set_selected_range({ start: 0, end: project.length });
    this.input.on("change", (_event, change) => {
      this.error = null;
      change.notify();
    });
    this.input.on("submit", (_event, submit) => this.rename(submit));
    focusSoon(this.input, cx);
  }

  render(): Element {
    const colors = readTheme();
    return dialog(colors, {
      id: "rename-project",
      title: "Rename project",
      error: this.error,
      fields: [textField(colors, this.input, this.error !== null)],
      buttons: [
        { id: "cancel", label: "Cancel", onClick: () => closeOverlay(this.overlay) },
        { id: "save", label: "Save", primary: true, onClick: (cx) => this.rename(cx) },
      ],
    });
  }

  private rename(cx: Context): void {
    const name = this.input.value().trim();
    const projects = readScene().projects;
    const project = projects.find((candidate) => candidate.name === this.project);
    const others = projects.map((candidate) => candidate.name).filter((other) => other !== this.project);
    this.error = nameProblem(name, others);
    if (this.error || !project) {
      cx.notify();
      return;
    }
    closeOverlay(this.overlay);
    if (name === this.project) return;
    reportFailureOf(`Could not rename ${this.project}`, renameProject(project, name));
  }
}
