import type { Context, Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { closeOverlay } from "herdr";
import { closeProject, openRenameProjectDialog, reportFailure, ungroupProject } from "../actions";
import type { Project } from "../projects";
import { readScene } from "../snapshot";
import { projectFootprint } from "../threads";
import { chromeIcon, menuItem, readTheme, type Theme } from "../ui";
import type { Part } from "./part";

/** A way to end a project. The menu asks once more, in words that say what the step does. */
interface Ending {
  readonly id: string;
  readonly icon: string;
  readonly label: string;
  readonly consequence: string;
  readonly run: () => Promise<void>;
}

function sessions(amount: number): string {
  return `${amount} session${amount === 1 ? "" : "s"}`;
}

function endings(project: Project): Ending[] {
  const { snapshot } = readScene();
  const { space, outside } = projectFootprint(snapshot, project);
  const all = sessions(project.members.length);
  return [
    {
      id: "close-project",
      icon: chromeIcon("x"),
      label: "Close project",
      consequence: `End ${all}`,
      run: () => closeProject(space, outside),
    },
    {
      id: "ungroup-project",
      icon: chromeIcon("layers"),
      label: "Ungroup",
      consequence: `Keep ${all} running`,
      run: () => ungroupProject(project),
    },
  ];
}

/** The right-click menu of a project: rename it, close it with its sessions, or take it apart and keep them. */
export class ProjectMenu implements Part {
  /** The id of the ending that waits for its second click. */
  private asked: string | null = null;

  constructor(
    private readonly overlay: string,
    private readonly name: string,
  ) {}

  render(): Element {
    const colors = readTheme();
    const project = readScene().projects.find((candidate) => candidate.name === this.name);
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
      .children(project ? endings(project).map((ending) => this.item(colors, ending)) : []);
  }

  private item(colors: Theme, ending: Ending): Element {
    if (this.asked !== ending.id) {
      return menuItem(colors, { ...ending, onClick: (cx) => this.ask(ending.id, cx) });
    }
    return menuItem(colors, {
      id: `confirm-${ending.id}`,
      icon: chromeIcon("check"),
      label: ending.consequence,
      onClick: () => this.end(ending),
    });
  }

  private rename(): void {
    closeOverlay(this.overlay);
    openRenameProjectDialog(this.name);
  }

  private ask(id: string, cx: Context): void {
    this.asked = id;
    cx.notify();
  }

  private end(ending: Ending): void {
    closeOverlay(this.overlay);
    ending.run().catch((error: unknown) => reportFailure(`Could not end ${this.name}`, error));
  }
}
