import { describe, expect, test } from "bun:test";
import type { AgentInfo, PaneInfo, Program, SpaceInfo, TabInfo } from "herdr";
import { projectEntry } from "./entries";
import shipped from "../layout.json";
import { findNode, HOST_NESTING_LIMIT, nesting, withThread, type LayoutNode } from "./layout-tree";
import {
  isProjectName,
  moveProject,
  nameProblem,
  orderProjects,
  parseOrder,
  projectsOf,
  shownProject,
  waitingOn,
  type Project,
} from "./projects";
import { buildScene, usualFolder } from "./scene";
import { groupOf, mostUrgent, parseReported, parseStatus, withReport } from "./status";
import { machineOf, parseTerminal, type Terminal } from "./terminal";
import {
  agentOrder,
  groupThreads,
  projectHome,
  projectFootprint,
  projectThreads,
  threadAt,
  type Snapshot,
  type Thread,
} from "./threads";
import { age } from "./time";
import { parseViews, rememberedThread, withView } from "./views";

const CLAUDE: Program = {
  key: "claude",
  name: "Claude Code",
  icon: null,
  tint: false,
  tile: null,
  color: null,
  shell: false,
  agent: true,
};

function terminal(overrides: Partial<Terminal> & Pick<Terminal, "address">): Terminal {
  return {
    machine: machineOf(overrides.address),
    name: null,
    title: "",
    status: null,
    activity: null,
    since: null,
    agent: false,
    project: null,
    role: null,
    heading: null,
    reported: null,
    resolved: false,
    ...overrides,
  };
}

function tab(overrides: Partial<TabInfo> & Pick<TabInfo, "id">): TabInfo {
  return {
    index: 1,
    name: "1",
    named: false,
    active: false,
    status: null,
    panes: 1,
    zoomed: false,
    settled: false,
    settled_at: null,
    changed_at: null,
    working_since: null,
    ...overrides,
  };
}

function pane(overrides: Partial<PaneInfo> & Pick<PaneInfo, "pane" | "tab">): PaneInfo {
  return {
    terminal: null,
    title: "",
    name: null,
    cwd: null,
    branch: null,
    status: null,
    app: null,
    program: CLAUDE,
    focused: false,
    zoomed: false,
    movable: false,
    ...overrides,
  };
}

function space(overrides: Partial<SpaceInfo> & Pick<SpaceInfo, "id">, tabs: TabInfo[]): SpaceInfo {
  return {
    index: 1,
    name: "repo",
    named: false,
    folder: "",
    machine: null,
    branch: "main",
    active: true,
    status: null,
    tabs,
    ...overrides,
  };
}

function snapshot(overrides: Partial<Snapshot>): Snapshot {
  return { spaces: [], panes: [], agents: [], terminals: [], focused: null, ...overrides };
}

function only(terminals: Terminal[]): Project {
  const [project] = projectsOf(terminals);
  if (!project) throw new Error("no project");
  return project;
}

function byTitle(threads: Thread[], title: string): Thread {
  const thread = threads.find((candidate) => candidate.title === title);
  if (!thread) throw new Error(`no thread titled ${title}`);
  return thread;
}

describe("status", () => {
  test("an error counts as blocked, an unknown word as no status", () => {
    expect(parseStatus("error")).toBe("blocked");
    expect(parseStatus("working")).toBe("working");
    expect(parseStatus("starting")).toBeNull();
    expect(parseStatus(undefined)).toBeNull();
  });

  test("a thread that asked for the person waits on them until it works again", () => {
    expect(parseReported("needs-you")).toBe("needs-you");
    expect(parseReported("whatever")).toBeNull();
    expect(withReport("done", "needs-you")).toBe("blocked");
    expect(withReport("idle", "needs-you")).toBe("blocked");
    expect(withReport("working", "needs-you")).toBe("working");
    expect(withReport("done", "done")).toBe("done");
    expect(withReport("idle", null)).toBe("idle");
  });

  test("blocked outranks done, done outranks working", () => {
    expect(mostUrgent(["working", "done", null])).toBe("done");
    expect(mostUrgent(["done", "blocked", "idle"])).toBe("blocked");
    expect(mostUrgent([null, null])).toBeNull();
  });

  test("a resolved thread is put away whatever its status", () => {
    expect(groupOf("working", true)).toBe("resolved");
    expect(groupOf("blocked", false)).toBe("waiting");
    expect(groupOf("done", false)).toBe("idle");
    expect(groupOf(null, false)).toBe("idle");
  });
});

describe("parseTerminal", () => {
  test("reads the labels and the report of a live terminal", () => {
    const parsed = parseTerminal({
      address: "box/t7",
      state: "live",
      status: "working",
      status_ms: 42,
      turn: 3,
      labels: {
        project: "billing",
        role: "thread",
        task: "fix-tax",
        title: "Fix the tax rule",
        state: "needs-you",
        "report-turn": "3",
      },
      report: { msg: "Running tests" },
      program: { agent: true },
    });
    expect(parsed).toMatchObject({
      address: "box/t7",
      machine: "box",
      status: "working",
      activity: "Running tests",
      since: 42,
      agent: true,
      project: "billing",
      role: "thread",
      heading: "Fix the tax rule",
      reported: "needs-you",
      resolved: false,
    });
  });

  test("a report from an earlier turn is behind the thread", () => {
    const labels = { state: "needs-you", "report-turn": "3" };
    expect(parseTerminal({ address: "t1", state: "live", turn: 3, labels })?.reported).toBe("needs-you");
    expect(parseTerminal({ address: "t1", state: "live", turn: 4, labels })?.reported).toBeNull();
    expect(parseTerminal({ address: "t1", state: "live", turn: 3, labels: { state: "needs-you" } })?.reported).toBeNull();
  });

  test("a thread without a title is known by its task", () => {
    const parsed = parseTerminal({ address: "t1", state: "live", labels: { task: "fix-tax", resolved: "true" } });
    expect(parsed).toMatchObject({ heading: "fix-tax", resolved: true });
  });

  test("skips a terminal that ended or has no address", () => {
    expect(parseTerminal({ address: "t1", state: "finished" })).toBeNull();
    expect(parseTerminal({ state: "live" })).toBeNull();
  });

  test("survives missing and malformed fields", () => {
    const parsed = parseTerminal({ address: "t1", state: "live", labels: "oops", report: null });
    expect(parsed).toMatchObject({ machine: null, project: null, activity: null, agent: false, reported: null });
  });
});

describe("projects", () => {
  const lead = terminal({ address: "t1", project: "billing", role: "orchestrator" });
  const local = terminal({ address: "t2", project: "billing", status: "working" });
  const remote = terminal({ address: "box/t3", project: "billing", status: "blocked" });
  const other = terminal({ address: "t4", project: "audit" });
  const loose = terminal({ address: "t5" });
  const projects = projectsOf([local, remote, lead, other, loose]);

  test("groups terminals by label, sorted by name, the orchestrator first", () => {
    expect(projects.map((project) => project.name)).toEqual(["audit", "billing"]);
    expect(projects[1]?.members.map((member) => member.address)).toEqual(["t1", "t2", "box/t3"]);
    expect(projects[1]?.machines).toEqual([null, "box"]);
  });

  test("follows the focused terminal's project, else shows none", () => {
    expect(shownProject(projects, "t2")?.name).toBe("billing");
    expect(shownProject(projects, "t5")).toBeNull();
    expect(shownProject(projects, null)).toBeNull();
  });

  test("counts the threads that wait on the person, not the resolved ones", () => {
    const asks = terminal({ address: "t6", project: "billing", status: "blocked", resolved: true });
    expect(waitingOn(only([lead, local, remote, asks]))).toBe(1);
  });

  test("a name is a short slug", () => {
    expect(isProjectName("billing-2")).toBe(true);
    expect(isProjectName("Billing")).toBe(false);
    expect(isProjectName("-billing")).toBe(false);
    expect(isProjectName("a-name-that-is-too-long")).toBe(false);
    expect(isProjectName("")).toBe(false);
  });

  test("an entry counts machines and threads, not the orchestrator, and marks the most urgent state", () => {
    const billing = projects[1];
    if (!billing) throw new Error("no billing project");
    expect(projectEntry(billing, true)).toMatchObject({
      name: "billing",
      aside: "2 machines",
      detail: "2 threads",
      status: "blocked",
      selected: true,
    });
  });
});

describe("a project started by the launcher", () => {
  const lead = terminal({ address: "t1", project: "p", role: "orchestrator", status: "working" });
  const fix = terminal({ address: "t2", project: "p", heading: "Fix the export", name: "p-fix", since: 111 });
  const audit = terminal({ address: "t3", project: "p", heading: "Audit the logs", resolved: true });
  const stray = terminal({
    address: "box/t4",
    project: "p",
    heading: "Elsewhere",
    activity: "✳ Reading",
    status: "working",
  });
  const project = only([fix, audit, stray, lead]);
  const own = space({ id: "sp-p" }, [
    tab({ id: "lead" }),
    tab({ id: "fix", name: "Fix Safari export", named: true, changed_at: 222 }),
    tab({ id: "audit" }),
  ]);
  const scene = snapshot({
    spaces: [own],
    panes: [
      pane({ pane: "p1", tab: "lead", terminal: "t1" }),
      pane({ pane: "p2", tab: "fix", terminal: "t2" }),
      pane({ pane: "p3", tab: "audit", terminal: "t3", name: "Log audit" }),
    ],
    focused: "t2",
  });
  const threads = projectThreads(scene, project);

  test("the orchestrator is not a thread", () => {
    expect(threads.map((thread) => thread.key)).toEqual(["t2", "t3", "box/t4"]);
  });

  test("a name given in Herdr wins: the pane's, then the tab's, then the launcher's title", () => {
    expect(threads.map((thread) => thread.title)).toEqual(["Fix Safari export", "Log audit", "Elsewhere"]);
  });

  test("a tab that Herdr named after its program does not hide the session's own title", () => {
    const auto = snapshot({
      spaces: [space({ id: "sp-p" }, [tab({ id: "fix", name: "Claude Code", named: true })])],
      panes: [pane({ pane: "p2", tab: "fix", terminal: "t2" })],
    });
    expect(projectThreads(auto, project)[0]?.title).toBe("Fix the export");
  });

  test("a thread owns its tab, so Herdr's rename, close and settle apply", () => {
    expect(byTitle(threads, "Fix Safari export")).toMatchObject({
      pane: "p2",
      tab: { id: "fix", space: "sp-p" },
      active: true,
      since: 222,
    });
    expect(byTitle(threads, "Elsewhere")).toMatchObject({ pane: null, tab: null, aside: "box", note: "Reading" });
  });

  test("every thread opens in the panel, beside the orchestrator", () => {
    expect(threads.map((thread) => thread.opens)).toEqual(["panel", "panel", "panel"]);
    expect(projectHome(scene, project)).toBe("t1");
  });

  test("a thread is found by its terminal, whatever project is on show; the orchestrator is none", () => {
    expect(threadAt(scene, [project], "t3")?.title).toBe("Log audit");
    expect(threadAt(scene, [project], "t1")).toBeUndefined();
    expect(threadAt(scene, [project], null)).toBeUndefined();
  });

  test("resolved is the label on the thread's terminal, and nothing else", () => {
    expect(byTitle(threads, "Log audit").resolved).toBe(true);
    expect(byTitle(threads, "Fix Safari export").resolved).toBe(false);
    const settled = snapshot({ ...scene, spaces: [space({ id: "sp-p" }, [tab({ id: "fix", settled: true })])] });
    expect(byTitle(projectThreads(settled, project), "Fix the export").resolved).toBe(false);
  });

  test("its space is its own while every tab there is the project's", () => {
    expect(projectFootprint(scene, project)).toEqual({ space: "sp-p", outside: ["box/t4"] });
    const shared = snapshot({ ...scene, spaces: [{ ...own, tabs: [...own.tabs, tab({ id: "someone-else" })] }] });
    expect(projectFootprint(shared, project)).toEqual({ space: null, outside: ["t1", "t2", "t3", "box/t4"] });
  });
});

describe("sessions that were only grouped", () => {
  const first = terminal({ address: "t1", project: "p", heading: "First" });
  const second = terminal({ address: "t2", project: "p", heading: "Second" });
  const project = only([first, second]);
  const scene = snapshot({
    spaces: [space({ id: "s1" }, [tab({ id: "a" })])],
    panes: [pane({ pane: "p1", tab: "a", terminal: "t1" })],
  });

  test("without an orchestrator, a session with a pane opens there", () => {
    const threads = projectThreads(scene, project);
    expect(threads.map((thread) => thread.opens)).toEqual(["pane", "panel"]);
    expect(projectHome(scene, project)).toBe("t1");
    expect(projectHome(snapshot({}), project)).toBeNull();
  });

  test("it has no space of its own, so ending it only ungroups its sessions", () => {
    expect(projectFootprint(scene, project)).toEqual({ space: null, outside: ["t1", "t2"] });
  });
});

describe("the thread list", () => {
  const threads = projectThreads(
    snapshot({}),
    only([
      terminal({ address: "t1", project: "p", heading: "idle" }),
      terminal({ address: "t2", project: "p", heading: "busy", status: "working" }),
      terminal({ address: "t3", project: "p", heading: "ask", status: "blocked" }),
      terminal({ address: "t4", project: "p", heading: "put away", status: "done", resolved: true }),
    ]),
  );

  test("groups keep the order a person acts in and drop empty ones", () => {
    expect(groupThreads(threads).map((group) => group.id)).toEqual(["waiting", "working", "idle", "resolved"]);
    expect(groupThreads(threads.slice(0, 1)).map((group) => group.id)).toEqual(["idle"]);
  });

  test("agents follow the list's order, the rest keep theirs after", () => {
    const agent = (address: string) => ({ address }) as AgentInfo;
    const shown = groupThreads(threads).flatMap((group) => group.threads);
    expect(agentOrder([agent("t1"), agent("t9"), agent("t3")], shown)).toEqual(["t3", "t1", "t9"]);
  });
});

describe("scene", () => {
  const blocked = terminal({ address: "t1", project: "p", status: "blocked" });
  const working = terminal({ address: "t2", project: "p", status: "working" });

  test("shows the focused terminal's project, else none", () => {
    expect(buildScene(snapshot({ terminals: [blocked, working], focused: "t2" }), []).shown?.name).toBe("p");
    expect(buildScene(snapshot({ terminals: [blocked] }), []).shown).toBeNull();
  });

  test("offers the folder a machine's first space works in", () => {
    const home = space({ id: "s1", machine: "box", folder: "/made/here" }, [tab({ id: "a" })]);
    const live = snapshot({ spaces: [home], panes: [pane({ pane: "p1", tab: "a", cwd: "/live/here" })] });
    expect(usualFolder(live, "box")).toBe("/live/here");
    expect(usualFolder(snapshot({ spaces: [home] }), "box")).toBe("/made/here");
    expect(usualFolder(snapshot({ spaces: [home] }), null)).toBeNull();
  });
});

describe("age", () => {
  test("rounds down to minutes, hours, then days", () => {
    expect(age(20_000)).toBe("now");
    expect(age(5 * 60_000)).toBe("5m");
    expect(age(3 * 3_600_000 + 59 * 60_000)).toBe("3h");
    expect(age(50 * 3_600_000)).toBe("2d");
  });
});

describe("withThread", () => {
  const base: LayoutNode = {
    id: "root",
    type: "row",
    children: [
      { id: "main", type: "block" },
      {
        id: "panel-body",
        type: "stack",
        active: "threads",
        children: [
          { id: "threads", type: "block" },
          { id: "files", type: "block" },
        ],
      },
    ],
  };
  const ids = (tree: LayoutNode) => findNode(tree, "panel-body")?.children?.map((child) => child.id);

  test("adds a header and the thread's terminal to the panel's stack", () => {
    const tree = withThread(base, "box/t7");
    expect(ids(tree)).toEqual(["threads", "files", "thread"]);
    expect(findNode(tree, "thread")?.children?.map((child) => child.id)).toEqual([
      "thread-head",
      "thread-terminal",
      "thread-drawer",
    ]);
    expect(findNode(tree, "thread-terminal")?.content?.terminal).toBe("box/t7");
    expect(findNode(tree, "main")).toEqual({ id: "main", type: "block" });
  });

  test("another thread takes the place of the open one, and null removes it", () => {
    const tree = withThread(withThread(base, "t1"), "t2");
    expect(ids(tree)).toEqual(["threads", "files", "thread"]);
    expect(findNode(tree, "thread-terminal")?.content?.terminal).toBe("t2");
    expect(ids(withThread(tree, null))).toEqual(["threads", "files"]);
  });

  test("leaves the base untouched", () => {
    withThread(base, "t1");
    expect(ids(base)).toEqual(["threads", "files"]);
  });
});

describe("the shipped layout", () => {
  test("stays within what Herdr accepts as an argument, with a thread open", () => {
    expect(nesting({ a: [{ b: 1 }] })).toBe(3);
    const sent = { layout: withThread(shipped as LayoutNode, "box/t7") };
    expect(nesting(sent)).toBeLessThanOrEqual(HOST_NESTING_LIMIT);
  });

  test("has the blocks the mod drives", () => {
    for (const id of ["sidebar", "main", "panel", "panel-body", "threads"]) {
      expect(findNode(shipped as LayoutNode, id)?.id).toBe(id);
    }
  });
});

describe("the person's order of projects", () => {
  const projects = projectsOf(["b", "a", "c"].map((name, index) => terminal({ address: `t${index}`, project: name })));
  const names = (order: string[]) => orderProjects(projects, order).map((project) => project.name);

  test("named projects come first in that order, the rest by name", () => {
    expect(names([])).toEqual(["a", "b", "c"]);
    expect(names(["c", "a"])).toEqual(["c", "a", "b"]);
    expect(names(["gone", "b"])).toEqual(["b", "a", "c"]);
  });

  test("a dropped project takes the place of the one it was dropped on", () => {
    expect(moveProject(["a", "b", "c"], "a", "c")).toEqual(["b", "c", "a"]);
    expect(moveProject(["a", "b", "c"], "c", "a")).toEqual(["c", "a", "b"]);
    expect(moveProject(["a", "b", "c"], "b", "b")).toEqual(["a", "b", "c"]);
    expect(moveProject(["a", "b", "c"], "x", "a")).toEqual(["a", "b", "c"]);
  });

  test("a stored order is a list of names, anything else is no order", () => {
    expect(parseOrder(["b", 3, "a"])).toEqual(["b", "a"]);
    expect(parseOrder({ b: 1 })).toEqual([]);
    expect(buildScene(snapshot({ terminals: projects.flatMap((project) => project.members) }), ["c"]).projects[0]?.name).toBe("c");
  });

  test("a name must be a slug that no other project has", () => {
    expect(nameProblem("billing", ["audit"])).toBeNull();
    expect(nameProblem("Billing", [])).toContain("lowercase");
    expect(nameProblem("audit", ["audit"])).toContain("exists already");
  });
});

describe("what each project has open", () => {
  test("a project remembers its thread while that thread is still its own", () => {
    const views = withView(withView({}, "a", "t1"), "b", null);
    expect(rememberedThread(views, "a", ["t1", "t2"])).toBe("t1");
    expect(rememberedThread(views, "a", ["t2"])).toBeNull();
    expect(rememberedThread(views, "b", ["t1"])).toBeNull();
    expect(rememberedThread(views, "c", ["t1"])).toBeNull();
  });

  test("stored views are read back, anything else is dropped", () => {
    expect(parseViews({ a: "t1", b: null, c: 3 })).toEqual({ a: "t1", b: null });
    expect(parseViews(["t1"])).toEqual({});
    expect(parseViews(null)).toEqual({});
  });
});
