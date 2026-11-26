import { div, type Context, type Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { openNewProjectDialog, openProjectMenu } from "../actions";
import { projectEntry } from "../entries";
import { dropProject, openProject } from "../navigation";
import type { Project } from "../projects";
import { entryRow } from "../rows";
import type { Scene } from "../scene";
import { readScene } from "../snapshot";
import { chromeIcon, heading, readTheme, type Theme } from "../ui";
import type { Part } from "./part";

/** The left sidebar: every project, in an order the person sets by dragging. */
export class ProjectList implements Part {
  /** The project under the pressed mouse button: released on another project, it moves there. */
  private pressed: string | null = null;

  render(): Element {
    const colors = readTheme();
    const scene = readScene();
    const rows = scene.projects.map((project) => this.row(colors, scene, project));
    return v_flex()
      .id("project-list")
      .size_full()
      .min_h(0)
      .px(8)
      .pb(8)
      .gap(1)
      .bg(colors.chrome)
      .text_size(13)
      .overflow_y_scrollbar()
      .on_mouse_up("left", () => this.release())
      .child(
        heading(colors, {
          id: "projects",
          label: "Projects",
          action: { id: "new-project", icon: chromeIcon("plus"), tip: "New project", onClick: openNewProjectDialog },
        }),
      )
      .children(rows)
      .when(rows.length === 0, (el) =>
        el.child(div().px(8).text_size(12).text_color(colors.dim).child("No project yet. Start one with the + above.")),
      );
  }

  private row(colors: Theme, scene: Scene, project: Project): Element {
    return entryRow(colors, projectEntry(project, project === scene.shown), {
      onOpen: () => openProject(scene, project),
      onMenu: () => openProjectMenu(project.name),
      onPress: () => this.press(project.name),
      onDrop: (cx) => this.drop(scene, project.name, cx),
    });
  }

  private press(name: string): void {
    this.pressed = name;
  }

  private release(): void {
    this.pressed = null;
  }

  private drop(scene: Scene, target: string, cx: Context): void {
    const moved = this.pressed;
    this.release();
    if (moved === null || moved === target) return;
    dropProject(scene, moved, target);
    cx.notify();
  }
}
