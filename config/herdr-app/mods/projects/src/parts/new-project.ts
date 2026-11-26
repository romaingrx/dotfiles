import type { AsyncContext, Context, Element } from "gpui-kit";
import { h_flex, InputState } from "gpui-base";
import { closeOverlay, machines } from "herdr";
import { reportFailure, startProject } from "../actions";
import { dialog, focusSoon, label, textField } from "../dialog";
import { LOCAL, nameProblem } from "../projects";
import { usualFolder } from "../scene";
import { readScene } from "../snapshot";
import { readTheme, textButton, type Theme } from "../ui";
import type { Part } from "./part";

/** What is wrong with the form, and the field to mark. */
interface Problem {
  readonly field: "name" | "folder";
  readonly message: string;
}

/** The machines a project can start on. A remote one comes first: it runs while this computer sleeps. */
function reachable(): (string | null)[] {
  const names = machines()
    .filter((machine) => machine.layout === "ready")
    .map((machine) => machine.name);
  return [...names.filter((name) => name !== null), ...names.filter((name) => name === null)];
}

/** A dialog that asks for a name, a machine and a folder, then starts the project's orchestrator there. */
export class NewProjectDialog implements Part {
  private readonly name = InputState.new({ placeholder: "billing" });
  private readonly folder = InputState.new({ placeholder: "/path/to/the/repository" });
  private machine: string | null;
  private problem: Problem | null = null;

  constructor(
    private readonly overlay: string,
    cx: AsyncContext,
  ) {
    this.machine = reachable()[0] ?? null;
    this.offerFolder();
    for (const input of [this.name, this.folder]) {
      input.on("change", (_event, change) => this.clearError(change));
      input.on("submit", (_event, submit) => this.create(submit));
    }
    focusSoon(this.name, cx);
  }

  render(): Element {
    const colors = readTheme();
    return dialog(colors, {
      id: "new-project",
      title: "New project",
      hint: "Starts an orchestrator. It runs the project's threads on the same machine.",
      error: this.problem?.message ?? null,
      fields: [
        label(colors, "Name"),
        textField(colors, this.name, this.problem?.field === "name"),
        label(colors, "Machine"),
        this.machinePicker(colors),
        label(colors, "Folder"),
        textField(colors, this.folder, this.problem?.field === "folder"),
      ],
      buttons: [
        { id: "cancel", label: "Cancel", onClick: () => closeOverlay(this.overlay) },
        { id: "create", label: "Create", primary: true, onClick: (cx) => this.create(cx) },
      ],
    });
  }

  private machinePicker(colors: Theme): Element {
    return h_flex()
      .gap(6)
      .flex_wrap()
      .children(
        reachable().map((machine) =>
          textButton(colors, {
            id: `machine-${machine ?? LOCAL}`,
            label: machine ?? "This computer",
            primary: machine === this.machine,
            onClick: (cx) => this.pickMachine(machine, cx),
          }),
        ),
      );
  }

  private pickMachine(machine: string | null, cx: Context): void {
    this.machine = machine;
    this.offerFolder();
    this.clearError(cx);
  }

  /** Fills the folder with where that machine's first space works. */
  private offerFolder(): void {
    this.folder.set_value(usualFolder(readScene().snapshot, this.machine) ?? "");
  }

  private clearError(cx: Context): void {
    this.problem = null;
    cx.notify();
  }

  private create(cx: Context): void {
    const name = this.name.value().trim();
    const folder = this.folder.value().trim();
    this.problem = this.check(name, folder);
    if (this.problem) {
      cx.notify();
      return;
    }
    closeOverlay(this.overlay);
    startProject(name, this.machine, folder).catch((error: unknown) => reportFailure(`Could not start ${name}`, error));
  }

  private check(name: string, folder: string): Problem | null {
    const taken = readScene().projects.map((project) => project.name);
    const wrongName = nameProblem(name, taken);
    if (wrongName) return { field: "name", message: wrongName };
    if (!folder.startsWith("/")) return { field: "folder", message: "Give the folder as a full path on that machine." };
    return null;
  }
}
