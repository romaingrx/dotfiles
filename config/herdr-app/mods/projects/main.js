// src/main.ts
import { View, div as div8 } from "gpui-kit";
import { props } from "herdr";

// src/parse.ts
function isRecord(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function asRecord(value) {
  return isRecord(value) ? value : {};
}
function text(value) {
  return typeof value === "string" && value !== "" ? value : null;
}

// src/parts/new-project.ts
import { h_flex as h_flex3, InputState } from "gpui-base";
import { closeOverlay, machines } from "herdr";

// src/actions.ts
import { appHome, exec, hc, notify, openOverlay, run } from "herdr";

// src/status.ts
var GROUPS = [
  { id: "waiting", label: "Waiting on you" },
  { id: "working", label: "Working" },
  { id: "idle", label: "Idle" },
  { id: "resolved", label: "Resolved" }
];
var URGENCY = { blocked: 3, done: 2, working: 1, idle: 0 };
function isStatus(word) {
  return typeof word === "string" && word in URGENCY;
}
function parseStatus(word) {
  if (word === "error")
    return "blocked";
  return isStatus(word) ? word : null;
}
function parseReported(word) {
  return word === "done" || word === "needs-you" ? word : null;
}
function withReport(status, reported) {
  return reported === "needs-you" && status !== "working" ? "blocked" : status;
}
function mostUrgent(statuses) {
  let top = null;
  for (const status of statuses) {
    if (status && (!top || URGENCY[status] > URGENCY[top]))
      top = status;
  }
  return top;
}
function attention(status) {
  return status === "idle" ? null : status;
}
function isBusy(status) {
  return status === "working" || status === "blocked";
}
function groupOf(status, resolved) {
  if (resolved)
    return "resolved";
  if (status === "blocked")
    return "waiting";
  if (status === "working")
    return "working";
  return "idle";
}

// src/projects.ts
var ORCHESTRATOR = "orchestrator";
var LOCAL = "local";
var NAME = /^[a-z0-9][a-z0-9-]{0,15}$/;
var NAME_RULE = "Use lowercase letters, digits and hyphens, 16 characters at most.";
function isLead(member) {
  return member.role === ORCHESTRATOR;
}
function leadOf(project) {
  return project.members.find(isLead);
}
function threadsOf(project) {
  return project.members.filter((member) => !isLead(member));
}
function waitingOn(project) {
  return threadsOf(project).filter((member) => groupOf(member.status, member.resolved) === "waiting").length;
}
function isProjectName(name) {
  return NAME.test(name);
}
function nameProblem(name, others) {
  if (!isProjectName(name))
    return NAME_RULE;
  return others.includes(name) ? `A project named ${name} exists already.` : null;
}
function projectsOf(terminals) {
  const byName = new Map;
  for (const terminal of terminals) {
    if (!terminal.project)
      continue;
    byName.set(terminal.project, [...byName.get(terminal.project) ?? [], terminal]);
  }
  return [...byName.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([name, members]) => ({
    name,
    members: [...members.filter(isLead), ...members.filter((member) => !isLead(member))],
    machines: [...new Set(members.map((member) => member.machine))]
  }));
}
function shownProject(projects, focused) {
  if (focused === null)
    return null;
  return projects.find((project) => project.members.some((member) => member.address === focused)) ?? null;
}
function parseOrder(value) {
  return Array.isArray(value) ? value.filter((name) => typeof name === "string") : [];
}
function orderProjects(projects, order) {
  const place = new Map(order.map((name, index) => [name, index]));
  const rank = (project) => place.get(project.name) ?? order.length;
  return [...projects].sort((a, b) => rank(a) - rank(b) || a.name.localeCompare(b.name));
}
function moveProject(names, moved, target) {
  const rest = names.filter((name) => name !== moved);
  const at = rest.indexOf(target);
  if (at < 0 || !names.includes(moved))
    return [...names];
  const after = names.indexOf(moved) < names.indexOf(target);
  return [...rest.slice(0, at + (after ? 1 : 0)), moved, ...rest.slice(at + (after ? 1 : 0))];
}

// src/actions.ts
var MOD = "projects";
var LABELS = ["project", "role", "task", "title", "state", "report", "report-turn", "handled", "resolved"];
var MEMORY = ".claude/projects-memory";
var START_TIMEOUT = 180000;
var MOVE_MEMORY = `cd "$HOME/$1" 2>/dev/null || exit 0
[ -d "$2" ] || exit 0
if [ -e "$3" ]; then echo "a memory folder named $3 exists already: remove it or pick another name" >&2; exit 1; fi
mv -- "$2" "$3"`;
function reportFailure(title, error) {
  notify({ title, body: error instanceof Error ? error.message : String(error), level: "error" });
}
function succeed(result, program) {
  if (result.code !== 0)
    throw new Error(result.stderr.trim() || `${program} ended with code ${result.code}`);
}
async function core(args) {
  succeed(await hc(args), `hc ${args[0]}`);
}
function askName(title, value, command, args) {
  openOverlay({ mod: "prompt", kind: "dialog", width: 420, props: { title, value, command: { name: command, args } } });
}
function canRename(thread) {
  return thread.pane !== null;
}
function renameThread(thread) {
  if (thread.tab)
    askName("Rename thread", thread.title, "tab.rename", { id: thread.tab.id });
  else if (thread.pane)
    askName("Rename thread", thread.title, "pane.rename", { pane: thread.pane });
}
function openThreadMenu(tab) {
  openOverlay({ mod: "menu", kind: "popup", width: 200, props: { tab: "tab", target: tab } });
}
function setResolved(thread, resolved) {
  core(["label", thread.key, `resolved=${resolved ? "true" : ""}`]).catch((error) => reportFailure("Could not change the thread", error));
}
function openNewProjectDialog() {
  openOverlay({ mod: MOD, kind: "dialog", width: 440, props: { part: "new-project" } });
}
function openRenameProjectDialog(project) {
  openOverlay({ mod: MOD, kind: "dialog", width: 420, props: { part: "rename-project", project } });
}
function openProjectMenu(project) {
  openOverlay({ mod: MOD, kind: "popup", width: 220, height: 72, props: { part: "project-menu", project } });
}
async function startProject(name, machine, cwd) {
  const args = ["orchestrator", name, "--cwd", cwd, ...machine ? ["--on", machine] : []];
  succeed(await exec(`${appHome()}/mods/${MOD}/agent/start.sh`, args, { timeout: START_TIMEOUT }), "start.sh");
}
async function renameProject(project, name) {
  const moves = await Promise.all(project.machines.map((on) => exec("sh", ["-c", MOVE_MEMORY, "sh", MEMORY, project.name, name], { on })));
  for (const move of moves)
    succeed(move, "the move of the memory folder");
  await Promise.all(project.members.map((member) => core(["label", member.address, `project=${name}`])));
  const lead = leadOf(project);
  if (lead)
    await core(["send", lead.address, `The person renamed this project to "${name}". Its memory folder has that name now.`]);
}
async function deleteProject(ownSpace, outside) {
  if (ownSpace)
    run("space.close", { id: ownSpace });
  const cleared = LABELS.map((label) => `${label}=`);
  await Promise.all(outside.map((address) => core(["label", address, ...cleared])));
}

// src/dialog.ts
import { div as div2 } from "gpui-kit";
import { h_flex as h_flex2, Input, v_flex } from "gpui-base";

// src/ui.ts
import { div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { theme } from "herdr";
var COLOR_NAMES = [
  "background",
  "chrome",
  "popover",
  "raised",
  "selected",
  "hover",
  "border",
  "input",
  "foreground",
  "muted",
  "dim",
  "accent",
  "solid",
  "solid_foreground",
  "blocked",
  "working",
  "done"
];
function isColor(value) {
  return typeof value === "string" && value.startsWith("#");
}
function readTheme() {
  const all = theme();
  const colors = COLOR_NAMES.map((name) => {
    const color = all[name];
    if (!isColor(color))
      throw new Error(`the theme has no color "${name}"`);
    return [name, color];
  });
  return Object.fromEntries(colors);
}
function chromeIcon(name) {
  return `mods/workspace-chrome/${name}.svg`;
}
function statusMark(colors, status) {
  const dot = div().size(7).flex_none().rounded(4);
  if (status === null)
    return dot;
  if (status === "idle")
    return dot.border(1.5).border_color(colors.dim);
  return dot.bg(colors[status]);
}
var ICON_BUTTON = { regular: { box: 24, icon: 14, corner: 6 }, small: { box: 18, icon: 13, corner: 4 } };
function iconButton(colors, button) {
  const size = ICON_BUTTON[button.small ? "small" : "regular"];
  return div().id(button.id).size(size.box).flex_none().flex().items_center().justify_center().rounded(size.corner).when(button.active === true, (el) => el.bg(colors.selected)).text_color(button.active ? colors.foreground : colors.muted).hover((style) => style.bg(colors.hover).text_color(colors.foreground)).tooltip(button.tip).on_mouse_down("left", (_event, cx) => cx.stop_propagation()).on_click((_event, cx) => {
    cx.stop_propagation();
    button.onClick(cx);
  }).child(svg(button.icon).size(size.icon));
}
function resolveTip(resolved) {
  return resolved ? "Reopen" : "Mark resolved";
}
function heading(colors, props) {
  const label = props.count === undefined ? props.label : `${props.label} · ${props.count}`;
  const bar = h_flex().id(props.id).px(8).h(30).flex_none().gap(5).items_center().text_size(11.5).font_medium().text_color(colors.dim).child(label);
  const folding = optional(bar, props.fold, (el, fold) => el.cursor_pointer().hover((style) => style.text_color(colors.foreground)).on_click((_event, cx) => fold.onToggle(cx)).child(svg(chromeIcon(fold.open ? "chevron-down" : "chevron-right")).size(11).flex_none()));
  return optional(folding.child(div().flex_1()), props.action, (el, action) => el.child(iconButton(colors, action)));
}
function textButton(colors, button) {
  return h_flex().id(button.id).h(32).px(14).items_center().rounded(8).border_1().border_color(button.primary ? colors.solid : colors.input).bg(button.primary ? colors.solid : colors.raised).text_color(button.primary ? colors.solid_foreground : colors.foreground).text_size(12.5).font_medium().cursor_pointer().hover((style) => style.opacity(0.88)).on_click((_event, cx) => button.onClick(cx)).child(button.label);
}
function menuItem(colors, item) {
  return h_flex().id(item.id).h(31).px(8).gap(9).rounded(7).items_center().text_color(colors.foreground).cursor_pointer().hover((style) => style.bg(colors.hover)).on_click((_event, cx) => item.onClick(cx)).child(svg(item.icon).size(14).flex_none().text_color(colors.muted)).child(div().flex_1().child(item.label));
}
function optional(el, value, add) {
  return value === null || value === undefined ? el : add(el, value);
}

// src/dialog.ts
var REFOCUS_AFTER = 600;
function focusSoon(input, cx) {
  input.focus();
  cx.timer.after(REFOCUS_AFTER, () => input.focus());
}
function label(colors, text) {
  return div2().pt(4).text_size(11.5).text_color(colors.dim).child(text);
}
function textField(colors, state, invalid) {
  return Input.new(state).h(36).px(10).rounded(9).border_1().border_color(invalid ? colors.blocked : colors.input).bg(colors.background).text_size(12.8).text_color(colors.foreground);
}
function line(color, text) {
  return div2().text_size(11.5).text_color(color).child(text);
}
function dialog(colors, props) {
  const head = v_flex().id(props.id).w_full().p(18).gap(8).bg(colors.popover).text_color(colors.foreground).child(div2().text_size(15).font_semibold().child(props.title));
  const fields = optional(head, props.hint, (el, hint) => el.child(line(colors.dim, hint))).children([...props.fields]);
  return optional(fields, props.error, (el, error) => el.child(line(colors.blocked, error))).child(h_flex2().pt(8).gap(8).justify_end().children(props.buttons.map((button) => textButton(colors, button))));
}

// src/scene.ts
function buildScene(snapshot, order) {
  const projects = orderProjects(projectsOf(snapshot.terminals), order);
  return { snapshot, projects, shown: shownProject(projects, snapshot.focused) };
}
function usualFolder(snapshot, machine) {
  const space = snapshot.spaces.find((candidate) => candidate.machine === machine);
  if (!space)
    return null;
  const tabs = new Set(space.tabs.map((tab) => tab.id));
  const live = snapshot.panes.find((pane) => tabs.has(pane.tab) && pane.cwd)?.cwd;
  return live ?? (space.folder || null);
}

// src/snapshot.ts
import { agents, focused, panes, shared, spaces, terminals } from "herdr";

// src/terminal.ts
function currentReport(labels, turn) {
  return String(labels["report-turn"]) === String(turn) ? parseReported(labels.state) : null;
}
function machineOf(address) {
  const slash = address.indexOf("/");
  return slash < 0 ? null : address.slice(0, slash);
}
function parseTerminal(raw) {
  const address = text(raw.address);
  if (!address || raw.state !== "live")
    return null;
  const labels = asRecord(raw.labels);
  return {
    address,
    machine: machineOf(address),
    name: text(raw.name),
    title: text(raw.title) ?? "",
    status: parseStatus(raw.status),
    activity: text(asRecord(raw.report).msg),
    since: typeof raw.status_ms === "number" ? raw.status_ms : null,
    agent: asRecord(raw.program).agent === true,
    project: text(labels.project),
    role: text(labels.role),
    heading: text(labels.title) ?? text(labels.task),
    reported: currentReport(labels, raw.turn),
    resolved: labels.resolved === "true"
  };
}

// src/views.ts
function parseViews(value) {
  if (!isRecord(value))
    return {};
  const entries = Object.entries(value).filter((entry) => typeof entry[1] === "string" || entry[1] === null);
  return Object.fromEntries(entries);
}
function withView(views, project, thread) {
  return { ...views, [project]: thread };
}
function rememberedThread(views, project, threads) {
  const thread = views[project] ?? null;
  return thread !== null && threads.includes(thread) ? thread : null;
}

// src/snapshot.ts
var ORDER = "projects.order";
var VIEWS = "projects.views";
function isPresent(value) {
  return value !== null;
}
function shownStatus(terminal, listed) {
  const status = withReport(listed.get(terminal.address) ?? terminal.status, terminal.reported);
  return status === terminal.status ? terminal : { ...terminal, status };
}
function readSnapshot() {
  const listed = agents();
  const statuses = new Map(listed.map((agent) => [agent.address, agent.status]));
  return {
    spaces: spaces(),
    panes: panes(),
    agents: listed,
    terminals: terminals().map(parseTerminal).filter(isPresent).map((terminal) => shownStatus(terminal, statuses)),
    focused: focused()?.terminal ?? null
  };
}
function readViews() {
  return parseViews(shared(VIEWS));
}
function readScene() {
  return buildScene(readSnapshot(), parseOrder(shared(ORDER)));
}

// src/parts/new-project.ts
function reachable() {
  const names = machines().filter((machine) => machine.layout === "ready").map((machine) => machine.name);
  return [...names.filter((name) => name !== null), ...names.filter((name) => name === null)];
}

class NewProjectDialog {
  overlay;
  name = InputState.new({ placeholder: "billing" });
  folder = InputState.new({ placeholder: "/path/to/the/repository" });
  machine;
  problem = null;
  constructor(overlay, cx) {
    this.overlay = overlay;
    this.machine = reachable()[0] ?? null;
    this.offerFolder();
    for (const input of [this.name, this.folder]) {
      input.on("change", (_event, change) => this.clearError(change));
      input.on("submit", (_event, submit) => this.create(submit));
    }
    focusSoon(this.name, cx);
  }
  render() {
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
        textField(colors, this.folder, this.problem?.field === "folder")
      ],
      buttons: [
        { id: "cancel", label: "Cancel", onClick: () => closeOverlay(this.overlay) },
        { id: "create", label: "Create", primary: true, onClick: (cx) => this.create(cx) }
      ]
    });
  }
  machinePicker(colors) {
    return h_flex3().gap(6).flex_wrap().children(reachable().map((machine) => textButton(colors, {
      id: `machine-${machine ?? LOCAL}`,
      label: machine ?? "This computer",
      primary: machine === this.machine,
      onClick: (cx) => this.pickMachine(machine, cx)
    })));
  }
  pickMachine(machine, cx) {
    this.machine = machine;
    this.offerFolder();
    this.clearError(cx);
  }
  offerFolder() {
    this.folder.set_value(usualFolder(readScene().snapshot, this.machine) ?? "");
  }
  clearError(cx) {
    this.problem = null;
    cx.notify();
  }
  create(cx) {
    const name = this.name.value().trim();
    const folder = this.folder.value().trim();
    this.problem = this.check(name, folder);
    if (this.problem) {
      cx.notify();
      return;
    }
    closeOverlay(this.overlay);
    startProject(name, this.machine, folder).catch((error) => reportFailure(`Could not start ${name}`, error));
  }
  check(name, folder) {
    const taken = readScene().projects.map((project) => project.name);
    const wrongName = nameProblem(name, taken);
    if (wrongName)
      return { field: "name", message: wrongName };
    if (!folder.startsWith("/"))
      return { field: "folder", message: "Give the folder as a full path on that machine." };
    return null;
  }
}

// src/parts/panel-tabs.ts
import { div as div3 } from "gpui-kit";
import { h_flex as h_flex4 } from "gpui-base";

// src/layout-tree.ts
var PANEL = "panel";
var PANEL_STACK = "panel-body";
var THREAD = "thread";
var THREAD_TERMINAL = "thread-terminal";
var THREAD_DRAWER = "thread-drawer";
var THREAD_HEAD_HEIGHT = 36;
function findNode(node, id) {
  if (!node || node.id === id)
    return node;
  for (const child of node.children ?? []) {
    const found = findNode(child, id);
    if (found)
      return found;
  }
  return;
}
function threadView(terminal) {
  return {
    id: THREAD,
    type: "column",
    resizable: false,
    children: [
      {
        id: "thread-head",
        type: "block",
        size: { px: THREAD_HEAD_HEIGHT },
        content: { mod: "projects", props: { part: "thread-head" } }
      },
      { id: THREAD_TERMINAL, type: "block", size: { weight: 3 }, content: { terminal } },
      {
        id: THREAD_DRAWER,
        type: "stack",
        size: { weight: 2 },
        hidden: true,
        active: "thread-files",
        children: [
          { id: "thread-files", type: "block", content: { mod: "files" } },
          { id: "thread-changes", type: "block", content: { mod: "changes" } }
        ]
      }
    ]
  };
}
function withThread(node, terminal) {
  if (!node.children)
    return node;
  const children = node.children.filter((child) => child.id !== THREAD).map((child) => withThread(child, terminal));
  if (node.id !== PANEL_STACK || terminal === null)
    return { ...node, children };
  return { ...node, children: [...children, threadView(terminal)] };
}

// src/navigation.ts
import { run as run3, setShared as setShared2 } from "herdr";

// src/panel.ts
import { appHome as appHome2, layout, readTextFile, run as run2, setShared, shared as shared2 } from "herdr";
var LAYOUT = "projects";
var BASE = "mods/projects/layout.json";
var APPLIED = "projects.layout";
function asNode(value) {
  return isRecord(value) ? value : undefined;
}
function shownLayout() {
  return shared2("layout") === LAYOUT ? asNode(layout()) : undefined;
}
function isHidden(node) {
  return node === undefined || node.hidden === true;
}
function shownDrawer(drawer) {
  return isHidden(drawer) ? null : drawer?.active ?? null;
}
function readPanel() {
  const root = shownLayout();
  return {
    hidden: isHidden(findNode(root, PANEL)),
    active: findNode(root, PANEL_STACK)?.active ?? null,
    thread: findNode(root, THREAD_TERMINAL)?.content?.terminal ?? null,
    drawer: shownDrawer(findNode(root, THREAD_DRAWER))
  };
}
function selectPanel(panel) {
  run2("layout.select", { stack: PANEL_STACK, child: panel });
}
function togglePanel() {
  run2("layout.toggle", { id: PANEL });
}
function toggleDrawer(drawer) {
  if (readPanel().drawer === drawer) {
    run2("layout.hide", { id: THREAD_DRAWER });
    return;
  }
  run2("layout.select", { stack: THREAD_DRAWER, child: drawer });
  run2("layout.show", { id: THREAD_DRAWER });
}
function setLayout(tree, thread) {
  run2("layout.set", { layout: withThread(tree, thread) });
}
function showThreadInPanel(terminal, focus) {
  const shown = shownLayout();
  if (!shown)
    return;
  setLayout(shown, terminal);
  selectPanel(THREAD);
  if (focus)
    run2("pane.focus", { terminal });
}
async function syncLayout() {
  const base = await readTextFile(`${appHome2()}/${BASE}`);
  if (base === null)
    throw new Error(`${BASE} is missing`);
  if (shared2(APPLIED) === base || !shownLayout())
    return;
  const tree = asNode(JSON.parse(base));
  if (!tree)
    throw new Error(`${BASE} does not hold a layout`);
  setLayout(tree, readPanel().thread);
  setShared(APPLIED, base);
}

// src/text.ts
function stripGlyph(text) {
  return text.replace(/^[^\p{L}\p{N}\p{Ps}\p{Pi}]+/u, "").trim();
}

// src/threads.ts
function note(terminal) {
  if (!terminal.activity || !isBusy(terminal.status))
    return null;
  return stripGlyph(terminal.activity) || null;
}
function leadPanes(panes) {
  const leads = new Map;
  for (const pane of panes) {
    if (!pane.terminal)
      continue;
    const current = leads.get(pane.tab);
    if (!current || !current.program.agent && pane.program.agent)
      leads.set(pane.tab, pane);
  }
  return leads;
}
function seats(snapshot) {
  const leads = leadPanes(snapshot.panes);
  const homes = new Map(snapshot.spaces.flatMap((space) => space.tabs.map((tab) => [tab.id, { tab, space }])));
  const seated = new Map;
  for (const pane of snapshot.panes) {
    if (!pane.terminal)
      continue;
    const home = leads.get(pane.tab) === pane ? homes.get(pane.tab) : undefined;
    seated.set(pane.terminal, { pane, home: home ?? null });
  }
  return seated;
}
function sessionTitle(terminal, seat) {
  if (seat?.pane.name)
    return seat.pane.name;
  const tab = seat?.home?.tab;
  if (tab?.named && tab.name !== seat?.pane.program.name)
    return tab.name;
  return terminal.heading ?? terminal.name ?? (stripGlyph(terminal.title) || terminal.address);
}
function projectThreads(snapshot, project) {
  const seated = seats(snapshot);
  const spread = project.machines.length > 1;
  const lead = leadOf(project);
  const beside = lead !== undefined && seated.has(lead.address);
  return threadsOf(project).map((member) => {
    const seat = seated.get(member.address);
    return {
      key: member.address,
      title: sessionTitle(member, seat),
      status: member.status,
      agent: member.agent || member.status !== null,
      active: member.address === snapshot.focused,
      resolved: member.resolved,
      pane: seat?.pane.pane ?? null,
      tab: seat?.home ? { id: seat.home.tab.id, space: seat.home.space.id } : null,
      note: note(member),
      aside: spread ? member.machine ?? LOCAL : null,
      since: seat?.home?.tab.changed_at ?? member.since,
      opens: seat && !beside ? "pane" : "panel"
    };
  });
}
function threadAt(snapshot, projects, address) {
  const owner = projects.find((project) => project.members.some((member) => member.address === address));
  return owner && projectThreads(snapshot, owner).find((thread) => thread.key === address);
}
function projectHome(snapshot, project) {
  const seated = seats(snapshot);
  return project.members.find((member) => seated.has(member.address))?.address ?? null;
}
function projectFootprint(snapshot, project) {
  const seated = seats(snapshot);
  const lead = leadOf(project);
  const home = lead ? seated.get(lead.address)?.home?.space : null;
  const owned = new Set(project.members.map((member) => seated.get(member.address)?.home?.tab.id));
  const space = home?.tabs.every((tab) => owned.has(tab.id)) ? home.id : null;
  const inside = (address) => space !== null && seated.get(address)?.home?.space.id === space;
  const outside = project.members.map((member) => member.address).filter((address) => !inside(address));
  return { space, outside };
}
function groupThreads(threads) {
  return GROUPS.map((group) => ({
    ...group,
    threads: threads.filter((thread) => groupOf(thread.status, thread.resolved) === group.id)
  })).filter((group) => group.threads.length > 0);
}
function agentOrder(agents, shown) {
  const place = new Map(shown.map((thread, index) => [thread.key, index]));
  const rank = (agent) => place.get(agent.address) ?? Number.POSITIVE_INFINITY;
  return [...agents].sort((a, b) => rank(a) - rank(b)).map((agent) => agent.address);
}

// src/navigation.ts
function remember(thread) {
  const project = readScene().shown?.name;
  const views = readViews();
  if (project === undefined || (views[project] ?? null) === thread)
    return;
  setShared2(VIEWS, withView(views, project, thread));
}
function focusTerminal(terminal) {
  run3("pane.focus", { terminal });
}
function showInPanel(terminal, focus) {
  try {
    showThreadInPanel(terminal, focus);
  } catch (error) {
    reportFailure("Could not open the thread", error);
  }
}
function openThread(thread) {
  if (thread.opens === "pane") {
    focusTerminal(thread.key);
    return;
  }
  remember(thread.key);
  showInPanel(thread.key, true);
}
function showThreadList() {
  remember(null);
  selectPanel("threads");
}
function openProject(scene, project) {
  const home = projectHome(scene.snapshot, project);
  const inPanel = projectThreads(scene.snapshot, project).filter((thread) => thread.opens === "panel");
  const thread = rememberedThread(readViews(), project.name, inPanel.map((candidate) => candidate.key));
  if (home === null) {
    const session = thread ?? project.members[0]?.address;
    if (session)
      showInPanel(session, true);
    return;
  }
  if (thread)
    showInPanel(thread, false);
  else
    selectPanel("threads");
  focusTerminal(home);
}
function dropProject(scene, moved, target) {
  setShared2(ORDER, moveProject(scene.projects.map((project) => project.name), moved, target));
}

// src/parts/panel-tabs.ts
var TABS = [
  { id: "threads", label: "Threads" },
  { id: "files", label: "Files" },
  { id: "changes", label: "Changes" }
];
function isActive(tab, active) {
  return tab.id === active || tab.id === "threads" && active === THREAD;
}
function open(tab) {
  if (tab.id === "threads")
    showThreadList();
  else
    selectPanel(tab.id);
}
function badge(colors, count) {
  return div3().px(5).h(16).flex().items_center().rounded(8).bg(colors.blocked).text_size(10.5).font_semibold().text_color(colors.background).child(String(count));
}
function tabButton(colors, tab, active, count, onClick) {
  return h_flex4().id(`panel-tab-${tab.id}`).h(26).px(10).gap(6).flex_none().items_center().rounded(7).text_size(12.5).cursor_pointer().when(active, (el) => el.bg(colors.selected)).text_color(active ? colors.foreground : colors.muted).hover((style) => style.bg(colors.hover)).on_click(onClick).child(tab.label).when(count > 0, (el) => el.child(badge(colors, count)));
}
var panelTabs = {
  render() {
    const colors = readTheme();
    const { active } = readPanel();
    const { shown } = readScene();
    const waiting = shown ? waitingOn(shown) : 0;
    return h_flex4().size_full().px(8).gap(2).items_center().bg(colors.chrome).children(TABS.map((tab) => tabButton(colors, tab, isActive(tab, active), tab.id === "threads" ? waiting : 0, () => open(tab))));
  }
};

// src/parts/project-list.ts
import { div as div5 } from "gpui-kit";
import { v_flex as v_flex3 } from "gpui-base";

// src/entries.ts
function count(amount, noun) {
  return `${amount} ${noun}${amount === 1 ? "" : "s"}`;
}
function projectEntry(project, selected) {
  const [machine] = project.machines;
  const spread = project.machines.length > 1;
  return {
    id: `project-${project.name}`,
    name: project.name,
    aside: spread ? count(project.machines.length, "machine") : machine ?? LOCAL,
    detail: count(threadsOf(project).length, "thread"),
    status: attention(mostUrgent(project.members.map((member) => member.status))),
    selected
  };
}

// src/rows.ts
import { div as div4, svg as svg2 } from "gpui-kit";
import { h_flex as h_flex5, v_flex as v_flex2 } from "gpui-base";

// src/time.ts
var MINUTE = 60000;
function age(elapsed) {
  const minutes = Math.floor(elapsed / MINUTE);
  if (minutes < 1)
    return "now";
  if (minutes < 60)
    return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
}

// src/rows.ts
function withMenu(row, onMenu) {
  return row.on_mouse_down("right", (_event, cx) => {
    cx.stop_propagation();
    onMenu(cx);
  });
}
function entryRow(colors, entry, actions) {
  const row = h_flex5().id(entry.id).px(8).py(5).flex_none().gap(9).items_center().rounded(8).cursor_pointer().when(entry.selected, (el) => el.bg(colors.selected)).hover((style) => style.bg(colors.hover)).on_click((_event, cx) => actions.onOpen(cx)).on_mouse_down("left", (_event, cx) => actions.onPress(cx)).on_mouse_up("left", (_event, cx) => actions.onDrop(cx)).child(statusMark(colors, entry.status)).child(v_flex2().flex_1().min_w(0).child(h_flex5().gap(6).items_center().child(div4().flex_1().min_w(0).truncate().text_color(entry.selected ? colors.foreground : colors.muted).child(entry.name)).child(div4().flex_none().text_size(10.5).text_color(colors.dim).child(entry.aside))).child(div4().truncate().text_size(11).text_color(colors.dim).child(entry.detail)));
  return withMenu(row, actions.onMenu);
}
function threadMark(colors, thread) {
  if (thread.agent)
    return statusMark(colors, thread.status ?? "idle");
  return svg2(chromeIcon("terminal")).size(11).mx(-2).flex_none().text_color(colors.dim);
}
function threadMeta(thread, now) {
  const since = thread.since === null ? null : age(now - thread.since);
  return [thread.aside, since].filter((part) => part !== null).join(" · ");
}
function resolveButton(colors, thread, onResolve) {
  return iconButton(colors, {
    id: `resolve-${thread.key}`,
    icon: chromeIcon(thread.resolved ? "x" : "check"),
    tip: resolveTip(thread.resolved),
    small: true,
    onClick: onResolve
  });
}
function threadRow(colors, thread, view, actions) {
  const strong = thread.active || thread.status === "blocked";
  const trailing = view.hovered ? resolveButton(colors, thread, actions.onResolve) : div4().flex_none().text_size(11).text_color(colors.dim).child(threadMeta(thread, view.now));
  const row = v_flex2().id(`thread-${thread.key}`).px(10).py(7).flex_none().gap(2).rounded(8).cursor_pointer().when(thread.active, (el) => el.bg(colors.selected)).hover((style) => style.bg(colors.hover)).on_hover((on, cx) => actions.onHover(on, cx)).on_click((_event, cx) => actions.onOpen(cx)).child(h_flex5().h(18).gap(10).items_center().child(threadMark(colors, thread)).child(div4().flex_1().min_w(0).truncate().text_color(strong ? colors.foreground : colors.muted).child(thread.title)).child(trailing));
  const noted = optional(row, thread.note, (el, note) => el.child(div4().pl(17).truncate().text_size(11.5).text_color(thread.status === "blocked" ? colors.blocked : colors.dim).child(note)));
  return optional(noted, actions.onMenu, withMenu);
}

// src/parts/project-list.ts
class ProjectList {
  pressed = null;
  render() {
    const colors = readTheme();
    const scene = readScene();
    const rows = scene.projects.map((project) => this.row(colors, scene, project));
    return v_flex3().id("project-list").size_full().min_h(0).px(8).pb(8).gap(1).bg(colors.chrome).text_size(13).overflow_y_scrollbar().on_mouse_up("left", () => this.release()).child(heading(colors, {
      id: "projects",
      label: "Projects",
      action: { id: "new-project", icon: chromeIcon("plus"), tip: "New project", onClick: openNewProjectDialog }
    })).children(rows).when(rows.length === 0, (el) => el.child(div5().px(8).text_size(12).text_color(colors.dim).child("No project yet. Start one with the + above.")));
  }
  row(colors, scene, project) {
    return entryRow(colors, projectEntry(project, project === scene.shown), {
      onOpen: () => openProject(scene, project),
      onMenu: () => openProjectMenu(project.name),
      onPress: () => this.press(project.name),
      onDrop: (cx) => this.drop(scene, project.name, cx)
    });
  }
  press(name) {
    this.pressed = name;
  }
  release() {
    this.pressed = null;
  }
  drop(scene, target, cx) {
    const moved = this.pressed;
    this.release();
    if (moved === null || moved === target)
      return;
    dropProject(scene, moved, target);
    cx.notify();
  }
}

// src/parts/project-menu.ts
import { v_flex as v_flex4 } from "gpui-base";
import { closeOverlay as closeOverlay2 } from "herdr";
function projectMenu(overlay, name) {
  const rename = () => {
    closeOverlay2(overlay);
    openRenameProjectDialog(name);
  };
  const remove = () => {
    closeOverlay2(overlay);
    const scene = readScene();
    const project = scene.projects.find((candidate) => candidate.name === name);
    if (!project)
      return;
    const { space, outside } = projectFootprint(scene.snapshot, project);
    deleteProject(space, outside).catch((error) => reportFailure(`Could not delete ${name}`, error));
  };
  return {
    render() {
      const colors = readTheme();
      return v_flex4().id("project-menu").w_full().p(5).bg(colors.popover).text_size(12.8).child(menuItem(colors, { id: "rename-project", icon: chromeIcon("square-pen"), label: "Rename", onClick: rename })).child(menuItem(colors, { id: "delete-project", icon: chromeIcon("x"), label: "Delete", onClick: remove }));
    }
  };
}

// src/parts/rename-project.ts
import { InputState as InputState2 } from "gpui-base";
import { closeOverlay as closeOverlay3 } from "herdr";
class RenameProjectDialog {
  overlay;
  project;
  input;
  error = null;
  constructor(overlay, project, cx) {
    this.overlay = overlay;
    this.project = project;
    this.input = InputState2.new({ value: project });
    this.input.set_selected_range({ start: 0, end: project.length });
    this.input.on("change", (_event, change) => {
      this.error = null;
      change.notify();
    });
    this.input.on("submit", (_event, submit) => this.rename(submit));
    focusSoon(this.input, cx);
  }
  render() {
    const colors = readTheme();
    return dialog(colors, {
      id: "rename-project",
      title: "Rename project",
      error: this.error,
      fields: [textField(colors, this.input, this.error !== null)],
      buttons: [
        { id: "cancel", label: "Cancel", onClick: () => closeOverlay3(this.overlay) },
        { id: "save", label: "Save", primary: true, onClick: (cx) => this.rename(cx) }
      ]
    });
  }
  rename(cx) {
    const name = this.input.value().trim();
    const projects = readScene().projects;
    const project = projects.find((candidate) => candidate.name === this.project);
    const others = projects.map((candidate) => candidate.name).filter((other) => other !== this.project);
    this.error = nameProblem(name, others);
    if (this.error || !project) {
      cx.notify();
      return;
    }
    closeOverlay3(this.overlay);
    if (name === this.project)
      return;
    renameProject(project, name).catch((error) => reportFailure(`Could not rename ${this.project}`, error));
  }
}

// src/parts/thread-head.ts
import { div as div6 } from "gpui-kit";
import { h_flex as h_flex6 } from "gpui-base";
var DRAWERS = [
  { id: "thread-files", tip: "Files of this thread", icon: "mods/files/file.svg" },
  { id: "thread-changes", tip: "Changes of this thread", icon: "mods/changes/changes.svg" }
];
function drawerButtons(colors, shown) {
  return DRAWERS.map((drawer) => iconButton(colors, {
    id: drawer.id,
    icon: drawer.icon,
    tip: drawer.tip,
    active: shown === drawer.id,
    onClick: () => toggleDrawer(drawer.id)
  }));
}
function controls(colors, thread) {
  const rename = iconButton(colors, {
    id: "rename",
    icon: chromeIcon("square-pen"),
    tip: "Rename",
    onClick: () => renameThread(thread)
  });
  const resolve = iconButton(colors, {
    id: "resolve",
    icon: chromeIcon("circle-check"),
    tip: resolveTip(thread.resolved),
    active: thread.resolved,
    onClick: () => {
      setResolved(thread, !thread.resolved);
      showThreadList();
    }
  });
  return canRename(thread) ? [rename, resolve] : [resolve];
}
var threadHead = {
  render() {
    const colors = readTheme();
    const panel = readPanel();
    const { snapshot, projects } = readScene();
    const thread = threadAt(snapshot, projects, panel.thread);
    const bar = h_flex6().size_full().px(8).gap(6).items_center().bg(colors.chrome).text_size(12.5).child(iconButton(colors, { id: "back", icon: chromeIcon("chevron-left"), tip: "All threads", onClick: showThreadList })).child(statusMark(colors, thread?.status ?? null)).child(div6().flex_1().min_w(0).truncate().text_color(thread ? colors.foreground : colors.dim).child(thread?.title ?? "This thread has ended."));
    return optional(bar, thread, (el, open) => el.children([...drawerButtons(colors, panel.drawer), ...controls(colors, open)]));
  }
};

// src/parts/thread-panel.ts
import { div as div7 } from "gpui-kit";
import { v_flex as v_flex5 } from "gpui-base";
import { setAgentOrder } from "herdr";
var AGE_REFRESH = 60000;

class ThreadPanel {
  folded = new Set(["resolved"]);
  hovered = null;
  order = "";
  constructor(cx) {
    cx.timer.every(AGE_REFRESH, (tick) => tick.notify());
    syncLayout().catch((error) => reportFailure("Could not update the layout", error));
  }
  render() {
    const colors = readTheme();
    const { snapshot, shown } = readScene();
    const now = Date.now();
    const groups = groupThreads(shown ? projectThreads(snapshot, shown) : []);
    const threads = groups.flatMap((group) => group.threads);
    this.publishOrder(agentOrder(snapshot.agents, threads));
    return v_flex5().id("threads").size_full().min_h(0).px(8).pb(8).bg(colors.chrome).text_size(13).overflow_y_scrollbar().children(groups.flatMap((group) => this.group(colors, group, now))).when(threads.length === 0, (el) => el.child(this.empty(colors, shown !== null)));
  }
  empty(colors, hasProject) {
    const text = hasProject ? "No thread yet. Ask the orchestrator for some work." : "Pick a project on the left.";
    return div7().px(8).pt(12).text_size(12).text_color(colors.dim).child(text);
  }
  group(colors, group, now) {
    const open = !this.folded.has(group.id);
    const head = heading(colors, {
      id: group.id,
      label: group.label,
      count: group.threads.length,
      fold: { open, onToggle: (cx) => this.toggleFold(group.id, cx) }
    });
    return open ? [head, ...group.threads.map((thread) => this.row(colors, thread, now))] : [head];
  }
  row(colors, thread, now) {
    const { tab } = thread;
    return threadRow(colors, thread, { hovered: this.hovered === thread.key, now }, {
      onOpen: () => openThread(thread),
      onHover: (hovered, cx) => this.hover(thread.key, hovered, cx),
      onResolve: (cx) => {
        setResolved(thread, !thread.resolved);
        this.hover(thread.key, false, cx);
      },
      ...tab && { onMenu: () => openThreadMenu(tab) }
    });
  }
  publishOrder(order) {
    const word = order.join(" ");
    if (word === this.order)
      return;
    this.order = word;
    setAgentOrder([...order]);
  }
  hover(key, hovered, cx) {
    const next = hovered ? key : this.hovered === key ? null : this.hovered;
    if (next === this.hovered)
      return;
    this.hovered = next;
    cx.notify();
  }
  toggleFold(id, cx) {
    if (!this.folded.delete(id))
      this.folded.add(id);
    cx.notify();
  }
}

// src/parts/top-bar.ts
import { h_flex as h_flex7 } from "gpui-base";
import { window } from "herdr";
var WINDOW_BUTTONS = 76;
var EDGE = 12;
var topBar = {
  render() {
    const colors = readTheme();
    const frame = window();
    const hasWindowButtons = frame?.platform === "macos" && !frame.fullscreen;
    return h_flex7().size_full().pl(hasWindowButtons ? WINDOW_BUTTONS : EDGE).pr(EDGE).items_center().justify_end().bg(colors.chrome).child(iconButton(colors, {
      id: "toggle-panel",
      icon: chromeIcon("panel-right"),
      tip: "Threads panel",
      active: !readPanel().hidden,
      onClick: togglePanel
    }));
  }
};

// src/main.ts
var MAIN = "projects";
function readGiven() {
  const given = asRecord(props());
  return { part: text(given.part) ?? MAIN, overlay: text(given.overlay), project: text(given.project) };
}
function need(value, what) {
  if (value === null)
    throw new Error(`the projects mod needs ${what} for this part`);
  return value;
}
var PARTS = {
  top: () => topBar,
  projects: () => new ProjectList,
  tabs: () => panelTabs,
  threads: (_given, cx) => new ThreadPanel(cx),
  "thread-head": () => threadHead,
  "new-project": (given, cx) => new NewProjectDialog(need(given.overlay, "its overlay"), cx),
  "rename-project": (given, cx) => new RenameProjectDialog(need(given.overlay, "its overlay"), need(given.project, "a project"), cx),
  "project-menu": (given) => projectMenu(need(given.overlay, "its overlay"), need(given.project, "a project"))
};
function createPart(given, cx) {
  const factory = PARTS[given.part];
  if (!factory)
    throw new Error(`the projects mod has no part "${given.part}"`);
  return factory(given, cx);
}

class Projects extends View {
  part;
  init(_props, cx) {
    this.part = createPart(readGiven(), cx);
  }
  render(cx) {
    return this.part?.render(cx) ?? div8();
  }
}
export {
  Projects as default
};
