import type { Context, Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { closeOverlay } from "herdr";
import { deleteProject, openRenameProjectDialog, reportFailure } from "../actions";
import type { Project } from "../projects";
import { readScene } from "../snapshot";
import { projectFootprint, type Footprint } from "../threads";
import { chromeIcon, menuItem, readTheme } from "../ui";
import type { Part } from "./part";

function sessions(amount: number): string {
  return `${amount} session${amount === 1 ? "" : "s"}`;
}

/** What a delete does to the project's sessions, as the words of the step that confirms it. */
function consequence(project: Project, footprint: Footprint): string {
  const inside = project.members.length - footprint.outside.length;
  return footprint.space ? `End ${sessions(inside)}` : `Ungroup ${sessions(project.members.length)}`;
}

/** The right-click menu of a project. Delete asks once more, and says what it does. */
export class ProjectMenu implements Part {
  private confirming = false;

  constructor(
    private readonly overlay: string,
    private readonly name: string,
  ) {}

  render(): Element {
    const colors = readTheme();
    const scene = readScene();
    const project = scene.projects.find((candidate) => candidate.name === this.name);
    const footprint = project ? projectFootprint(scene.snapshot, project) : null;
    const remove =
      this.confirming && project && footprint
        ? {
            id: "confirm-delete",
            icon: chromeIcon("check"),
            label: consequence(project, footprint),
            onClick: () => this.remove(footprint),
          }
        : { id: "delete-project", icon: chromeIcon("x"), label: "Delete", onClick: (cx: Context) => this.ask(cx) };
    return v_flex()
      .id("project-menu")
      .w_full()
      .p(5)
      .bg(colors.popover)
      .text_size(12.8)
      .child(
        menuItem(colors, {
          id: "rename-project",
          icon: chromeIcon("square-pen"),
          label: "Rename",
          onClick: () => this.rename(),
        }),
      )
      .child(menuItem(colors, remove));
  }

  private rename(): void {
    closeOverlay(this.overlay);
    openRenameProjectDialog(this.name);
  }

  private ask(cx: Context): void {
    this.confirming = true;
    cx.notify();
  }

  private remove(footprint: Footprint): void {
    closeOverlay(this.overlay);
    deleteProject(footprint.space, footprint.outside).catch((error: unknown) =>
      reportFailure(`Could not delete ${this.name}`, error),
    );
  }
}
