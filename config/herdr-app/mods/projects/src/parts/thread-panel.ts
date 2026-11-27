import { div, type AsyncContext, type Context, type Element } from "gpui-kit";
import { v_flex } from "gpui-base";
import { setAgentOrder } from "herdr";
import { openThreadMenu, reportFailureOf, setResolved } from "../actions";
import { openThread } from "../navigation";
import { syncLayout } from "../panel";
import { leadOf, type Project } from "../projects";
import { threadRow } from "../rows";
import { readScene } from "../snapshot";
import { agentOrder, groupThreads, projectThreads, type Thread, type ThreadGroup } from "../threads";
import { heading, readTheme, type Theme } from "../ui";
import type { Part } from "./part";

/** How often the rows' ages are drawn again. */
const AGE_REFRESH = 60_000;

/** What the panel says in place of a list that has no thread. */
function emptyText(shown: Project | null): string {
  if (!shown) return "Pick a project on the left.";
  if (leadOf(shown)?.status === "blocked") return "No thread yet. The orchestrator waits on you, in the middle.";
  return "No thread yet. Ask the orchestrator for some work.";
}

/** The Threads tab of the right panel: the shown project's threads, grouped by whose move it is. */
export class ThreadPanel implements Part {
  private readonly folded = new Set<string>(["resolved"]);
  private hovered: string | null = null;
  /** The agent order last given to Herdr, as one word. */
  private order = "";

  constructor(cx: AsyncContext) {
    cx.timer.every(AGE_REFRESH, (tick) => tick.notify());
    reportFailureOf("Could not update the layout", syncLayout());
  }

  render(): Element {
    const colors = readTheme();
    const { snapshot, shown } = readScene();
    const now = Date.now();
    const groups = groupThreads(shown ? projectThreads(snapshot, shown) : []);
    const threads = groups.flatMap((group) => group.threads);
    this.publishOrder(agentOrder(snapshot.agents, threads));
    return v_flex()
      .id("threads")
      .size_full()
      .min_h(0)
      .px(8)
      .pb(8)
      .bg(colors.chrome)
      .text_size(13)
      .overflow_y_scrollbar()
      .children(groups.flatMap((group) => this.group(colors, group, now)))
      .when(threads.length === 0, (el) =>
        el.child(div().px(8).pt(12).text_size(12).text_color(colors.muted).child(emptyText(shown))),
      );
  }

  private group(colors: Theme, group: ThreadGroup, now: number): Element[] {
    const open = !this.folded.has(group.id);
    const head = heading(colors, {
      id: group.id,
      label: group.label,
      count: group.threads.length,
      ...(group.id === "waiting" && { tone: colors.blocked }),
      fold: { open, onToggle: (cx) => this.toggleFold(group.id, cx) },
    });
    return open ? [head, ...group.threads.map((thread) => this.row(colors, thread, now))] : [head];
  }

  private row(colors: Theme, thread: Thread, now: number): Element {
    const { tab } = thread;
    return threadRow(
      colors,
      thread,
      { hovered: this.hovered === thread.key, now },
      {
        onOpen: () => openThread(thread),
        onHover: (hovered, cx) => this.hover(thread.key, hovered, cx),
        onResolve: (cx) => {
          setResolved(thread, !thread.resolved);
          this.hover(thread.key, false, cx);
        },
        ...(tab && { onMenu: () => openThreadMenu(tab) }),
      },
    );
  }

  /** Herdr's agent shortcuts follow the list: it is told the order when that order changes. */
  private publishOrder(order: readonly string[]): void {
    const word = order.join(" ");
    if (word === this.order) return;
    this.order = word;
    setAgentOrder([...order]);
  }

  private hover(key: string, hovered: boolean, cx: Context): void {
    const next = hovered ? key : this.hovered === key ? null : this.hovered;
    if (next === this.hovered) return;
    this.hovered = next;
    cx.notify();
  }

  private toggleFold(id: string, cx: Context): void {
    if (!this.folded.delete(id)) this.folded.add(id);
    cx.notify();
  }
}
