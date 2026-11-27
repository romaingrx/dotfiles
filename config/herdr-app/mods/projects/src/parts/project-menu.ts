import type { Context, Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { closeOverlay } from "herdr";
import { closeProject, openRenameProjectDialog, reportFailure, ungroupProject } from "../actions";
import type { Project } from "../projects";
import { readScene } from "../snapshot";
import { projectFootprint } from "../threads";
import { chromeIcon, menuItem, readTheme, type MenuItem } from "../ui";
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

/**
 * The right-click menu of a project: rename it, close it with its sessions, or
 * take it apart and keep them. An ending asks once more before it runs.
 */
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
    const all = project ? endings(project) : [];
    const asked = all.find((ending) => ending.id === this.asked);
    const items = asked ? this.confirmation(asked) : this.choices(all);
    return v_flex()
      .id("project-menu")
      .w_full()
      .p(5)
      .bg(colors.popover)
      .text_size(12.8)
      .children(items.map((item) => menuItem(colors, item)));
  }

  private choices(all: readonly Ending[]): MenuItem[] {
    const rename = {
      id: "rename-project",
      icon: chromeIcon("square-pen"),
      label: "Rename",
      onClick: () => this.rename(),
    };
    return [rename, ...all.map((ending) => ({ ...ending, onClick: (cx: Context) => this.ask(ending.id, cx) }))];
  }

  /**
   * The step that confirms an ending. It is the first row, where no ending
   * was: the second click of a double click lands on Cancel or on nothing.
   */
  private confirmation(ending: Ending): MenuItem[] {
    return [
      {
        id: `confirm-${ending.id}`,
        icon: chromeIcon("check"),
        label: ending.consequence,
        onClick: () => this.end(ending),
      },
      { id: "cancel", icon: chromeIcon("chevron-left"), label: "Cancel", onClick: (cx) => this.ask(null, cx) },
    ];
  }

  private rename(): void {
    closeOverlay(this.overlay);
    openRenameProjectDialog(this.name);
  }

  private ask(id: string | null, cx: Context): void {
    this.asked = id;
    cx.notify();
  }

  private end(ending: Ending): void {
    closeOverlay(this.overlay);
    ending.run().catch((error: unknown) => reportFailure(`Could not end ${this.name}`, error));
  }
}
