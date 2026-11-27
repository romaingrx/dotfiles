import type { AsyncContext, Context, Element } from "gpui-kit";
import { h_flex, InputState } from "gpui-base";
import { closeOverlay, machines } from "herdr";
import { reportFailureOf, startProject } from "../actions";
import { dialog, focusSoon, label, textField } from "../dialog";
import { LOCAL, nameProblem } from "../projects";
import type { Outcome } from "../result";
import { usualFolder } from "../scene";
import { readScene } from "../snapshot";
import { readTheme, textButton, type Theme } from "../ui";
import type { Part } from "./part";

/** What is wrong, and the field to mark when it is one field's fault. */
interface Problem {
  readonly field: "name" | "folder" | null;
  readonly message: string;
}

/** A machine a project can start on. One that cannot be reached is shown, and cannot be chosen. */
interface Choice {
  readonly name: string | null;
  readonly offline: boolean;
}

/** A remote machine comes first: it runs while this computer sleeps. */
function choices(): Choice[] {
  const known = machines()
    .filter((machine) => machine.layout !== "loading")
    .map((machine) => ({ name: machine.name, offline: machine.layout === "unavailable" }));
  return [...known.filter((choice) => choice.name !== null), ...known.filter((choice) => choice.name === null)];
}

function machineLabel(choice: Choice): string {
  const name = choice.name ?? "This computer";
  return choice.offline ? `${name} (offline)` : name;
}

/** A dialog that asks for a name, a machine and a folder, then starts the project's orchestrator there. */
export class NewProjectDialog implements Part {
  private readonly name = InputState.new({ placeholder: "billing" });
  private readonly folder = InputState.new({ placeholder: "/path/to/the/repository" });
  private machine: string | null;
  private problem: Problem | null = null;
  /** True from Create until the orchestrator runs or the start fails. The dialog stays open meanwhile. */
  private starting = false;

  constructor(
    private readonly overlay: string,
    cx: AsyncContext,
  ) {
    this.machine = choices().find((choice) => !choice.offline)?.name ?? null;
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
      hint: this.starting
        ? `Starting the orchestrator on ${this.machine ?? "this computer"}. This can take a minute.`
        : "Starts an orchestrator. It runs the project's threads on the same machine.",
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
        { id: "cancel", label: this.starting ? "Hide" : "Cancel", onClick: () => closeOverlay(this.overlay) },
        {
          id: "create",
          label: this.starting ? "Starting…" : "Create",
          primary: true,
          disabled: this.starting,
          onClick: (cx) => this.create(cx),
        },
      ],
    });
  }

  private machinePicker(colors: Theme): Element {
    return h_flex()
      .gap(6)
      .flex_wrap()
      .children(
        choices().map((choice) =>
          textButton(colors, {
            id: `machine-${choice.name ?? LOCAL}`,
            label: machineLabel(choice),
            primary: choice.name === this.machine,
            disabled: choice.offline || this.starting,
            onClick: (cx) => this.pickMachine(choice.name, cx),
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
    if (this.starting) return;
    const name = this.name.value().trim();
    const folder = this.folder.value().trim();
    this.problem = this.check(name, folder);
    this.starting = this.problem === null;
    cx.notify();
    if (!this.starting) return;
    const start = startProject(name, this.machine, folder);
    // The notice reaches the person also after they hid the dialog.
    reportFailureOf(`Could not start ${name}`, start);
    cx.spawn((task) => this.follow(start, task));
  }

  /** Closes the dialog once the orchestrator runs. A start that fails leaves it open, with what was typed. */
  private async follow(start: Promise<Outcome>, cx: AsyncContext): Promise<void> {
    const started = await start;
    if (started.ok) {
      closeOverlay(this.overlay);
      return;
    }
    this.starting = false;
    this.problem = { field: null, message: started.error };
    cx.notify();
  }

  private check(name: string, folder: string): Problem | null {
    const taken = readScene().projects.map((project) => project.name);
    const wrongName = nameProblem(name, taken);
    if (wrongName) return { field: "name", message: wrongName };
    if (!folder.startsWith("/")) return { field: "folder", message: "Give the folder as a full path on that machine." };
    return null;
  }
}
