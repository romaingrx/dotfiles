import { type Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { closeOverlay } from "herdr";
import { deleteProject, openRenameProjectDialog, reportFailure } from "../actions";
import { readScene } from "../snapshot";
import { projectFootprint } from "../threads";
import { chromeIcon, menuItem, readTheme } from "../ui";
import type { Part } from "./part";

/** The right-click menu of a project. */
export function projectMenu(overlay: string, name: string): Part {
  const rename = (): void => {
    closeOverlay(overlay);
    openRenameProjectDialog(name);
  };
  const remove = (): void => {
    closeOverlay(overlay);
    const scene = readScene();
    const project = scene.projects.find((candidate) => candidate.name === name);
    if (!project) return;
    const { space, outside } = projectFootprint(scene.snapshot, project);
    deleteProject(space, outside).catch((error: unknown) =>
      reportFailure(`Could not delete ${name}`, error),
    );
  };
  return {
    render(): Element {
      const colors = readTheme();
      return v_flex()
        .id("project-menu")
        .w_full()
        .p(5)
        .bg(colors.popover)
        .text_size(12.8)
        .child(menuItem(colors, { id: "rename-project", icon: chromeIcon("square-pen"), label: "Rename", onClick: rename }))
        .child(menuItem(colors, { id: "delete-project", icon: chromeIcon("x"), label: "Delete", onClick: remove }));
    },
  };
}
