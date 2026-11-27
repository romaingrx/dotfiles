// src/main.ts
import { View, div as div9 } from "gpui-kit";
import { props } from "herdr";

// src/background.ts
import { checking, nextCommand, setBadge, window as window2 } from "herdr";

// src/actions.ts
import { appHome, exec, hc, notify, openOverlay, run, window } from "herdr";

// src/status.ts
var GROUPS = [
  { id: "review", label: "Ready for review" },
  { id: "waiting", label: "Waiting on you" },
  { id: "finished", label: "Finished" },
  { id: "working", label: "Working" },
  { id: "landing", label: "Landing" },
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
  return word === "done" || word === "review" || word === "needs-you" ? word : null;
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
function groupOf(status, resolved, pull = null) {
  if (resolved)
    return "resolved";
  if (status === "blocked")
    return "waiting";
  if (status === "working")
    return "working";
  if (pull === "review")
    return "review";
  if (pull === "landing")
    return "landing";
  return status === "done" ? "finished" : "idle";
}
function groupLabel(group) {
  return GROUPS.find((candidate) => candidate.id === group)?.label ?? group;
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
var LABELS = ["project", "role", "task", "title", "state", "report", "report-turn", "handled", "resolved", "pulls"];
var MEMORY = ".claude/projects-memory";
var START_TIMEOUT = 180000;
var MOVE_MEMORY = `cd "$HOME/$1" 2>/dev/null || exit 0
[ -d "$2" ] || exit 0
if [ -e "$3" ]; then echo "a memory folder named $3 exists already: remove it or pick another name" >&2; exit 1; fi
mv -- "$2" "$3"`;
function messageOf(error) {
  return error instanceof Error ? error.message : String(error);
}
function reportFailure(title, error) {
  notify({ title, body: messageOf(error), level: "error" });
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
  openOverlay({ mod: MOD, kind: "popup", width: 220, height: 103, props: { part: "project-menu", project } });
}
function openReview(thread) {
  openOverlay({ mod: MOD, kind: "dialog", modal: true, width: 0.92, height: 0.9, props: { part: "review", thread } });
}
async function sendToThread(thread, message) {
  await core(["send", thread, message]);
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
async function closeProject(ownSpace, outside) {
  if (ownSpace)
    run("space.close", { id: ownSpace, confirmed: true });
  await Promise.all(outside.map((address) => core(["kill", address])));
}
async function ungroupProject(project) {
  const cleared = LABELS.map((label) => `${label}=`);
  await Promise.all(project.members.map((member) => core(["label", member.address, ...cleared])));
}
function openLink(url) {
  const opener = window()?.platform === "macos" ? "open" : "xdg-open";
  exec(opener, [url]).then((result) => succeed(result, opener)).catch((error) => reportFailure("Could not open the link", error));
}

// src/navigation.ts
import { notify as notify2, run as run3, setShared as setShared2 } from "herdr";

// src/panel.ts
import { appHome as appHome2, layout, readTextFile, run as run2, setShared, shared } from "herdr";

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

// src/panel.ts
var LAYOUT = "projects";
var BASE = "mods/projects/layout.json";
var APPLIED = "projects.layout";
function asNode(value) {
  return isRecord(value) ? value : undefined;
}
function shownLayout() {
  return shared("layout") === LAYOUT ? asNode(layout()) : undefined;
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
  if (shared(APPLIED) === base || !shownLayout())
    return;
  const tree = asNode(JSON.parse(base));
  if (!tree)
    throw new Error(`${BASE} does not hold a layout`);
  setLayout(tree, readPanel().thread);
  setShared(APPLIED, base);
}

// src/snapshot.ts
import { agents, focused, machines, panes, shared as shared2, spaces, terminals } from "herdr";

// src/pulls.ts
var STAGE_WORDS = {
  draft: "draft",
  review: "in review",
  changes: "changes requested",
  landing: "landing",
  merged: "merged",
  closed: "closed"
};
var PULL_FIELDS = "number,url,state,isDraft,reviewDecision,autoMergeRequest,baseRefName,headRefName,title";
var MAX_DECLARED = 8;
var PULL_URL = /^https:\/\/([^/\s]+)\/([^/\s]+)\/([^/\s]+)\/pull\/(\d+)$/;
function isStage(word) {
  return typeof word === "string" && word in STAGE_WORDS;
}
function stageOf(raw) {
  if (raw.state === "MERGED")
    return "merged";
  if (raw.state === "CLOSED")
    return "closed";
  if (raw.isDraft === true)
    return "draft";
  if (raw.reviewDecision === "CHANGES_REQUESTED")
    return "changes";
  if (raw.reviewDecision === "APPROVED")
    return "landing";
  if (raw.reviewDecision === "REVIEW_REQUIRED")
    return "review";
  return isRecord(raw.autoMergeRequest) ? "landing" : "review";
}
function parsePull(value) {
  if (!isRecord(value) || typeof value.number !== "number" || typeof value.url !== "string")
    return null;
  const title = text(value.title);
  const base = text(value.base) ?? text(value.baseRefName);
  const head = text(value.head) ?? text(value.headRefName);
  if (!title || !base || !head)
    return null;
  return {
    number: value.number,
    url: value.url,
    title,
    stage: isStage(value.stage) ? value.stage : stageOf(value),
    base,
    head
  };
}
function parsePulls(value) {
  if (!isRecord(value))
    return {};
  const pulls = Object.entries(value).map(([key, pull]) => [key, parsePull(pull)]);
  return Object.fromEntries(pulls.filter((entry) => entry[1] !== null));
}
function parseDeclared(label) {
  if (typeof label !== "string")
    return [];
  const urls = label.split(/\s+/).filter((word) => PULL_URL.test(word));
  return [...new Set(urls)].slice(0, MAX_DECLARED);
}
function placeOf(url) {
  const [, host, owner, name, number] = PULL_URL.exec(url) ?? [];
  return host && owner && name && number ? { host, owner, name, number: Number(number) } : null;
}
function refsOf(terminal, declared) {
  if (declared.length === 0)
    return [{ kind: "branch", terminal }];
  return declared.map((url) => ({ kind: "declared", url }));
}
function refKey(ref) {
  return ref.kind === "declared" ? ref.url : ref.terminal;
}
function depth(pull, pulls) {
  let steps = 0;
  let below = pulls.find((other) => other.head === pull.base);
  while (below && steps < pulls.length) {
    steps++;
    const { base } = below;
    below = pulls.find((other) => other.head === base);
  }
  return steps;
}
function orderStack(pulls) {
  const depths = new Map(pulls.map((pull) => [pull, depth(pull, pulls)]));
  return [...pulls].sort((a, b) => (depths.get(a) ?? 0) - (depths.get(b) ?? 0) || a.number - b.number);
}
function stackOf(refs, known) {
  const found = refs.map((ref) => known[refKey(ref)]).filter((pull) => pull !== undefined);
  return orderStack([...new Map(found.map((pull) => [pull.url, pull])).values()]);
}
var LEAD_ORDER = ["review", "changes", "draft", "landing", "merged", "closed"];
function leadPull(stack) {
  for (const stage of LEAD_ORDER) {
    const pull = stack.find((candidate) => candidate.stage === stage);
    if (pull)
      return pull;
  }
  return null;
}
function openPulls(stack) {
  return stack.filter((pull) => pull.stage !== "merged" && pull.stage !== "closed");
}
function stageLabel(stage) {
  return STAGE_WORDS[stage];
}
function stackLabel(stack) {
  const runs = [];
  for (const pull of stack) {
    const last = runs[runs.length - 1];
    if (last?.stage === pull.stage)
      last.numbers.push(`#${pull.number}`);
    else
      runs.push({ numbers: [`#${pull.number}`], stage: pull.stage });
  }
  return runs.length ? runs.map((run) => `${run.numbers.join(" ")} ${STAGE_WORDS[run.stage]}`).join(", ") : null;
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
    resolved: labels.resolved === "true",
    declared: parseDeclared(labels.pulls)
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
var PULLS = "projects.pulls";
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
    pulls: parsePulls(shared2(PULLS)),
    focused: focused()?.terminal ?? null
  };
}
function readOffline() {
  return new Set(machines().filter((machine) => machine.layout === "unavailable").map((machine) => machine.name));
}
function readViews() {
  return parseViews(shared2(VIEWS));
}
function readScene() {
  return buildScene(readSnapshot(), parseOrder(shared2(ORDER)));
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
function place(pane) {
  return pane.terminal && pane.cwd ? `${machineOf(pane.terminal) ?? ""}:${pane.cwd}` : null;
}
function sharedFolders(snapshot) {
  const sessions = new Set(snapshot.terminals.filter((terminal) => terminal.project).map((terminal) => terminal.address));
  const seen = new Set;
  const shared = new Set;
  for (const pane of snapshot.panes) {
    const key = sessions.has(pane.terminal ?? "") ? place(pane) : null;
    if (key === null)
      continue;
    (seen.has(key) ? shared : seen).add(key);
  }
  return shared;
}
function checkout(seat, shared) {
  const { cwd, branch } = seat?.pane ?? {};
  if (!seat || !cwd || !branch || shared.has(place(seat.pane) ?? ""))
    return null;
  return { folder: cwd, branch };
}
function threadGroup(thread) {
  return groupOf(thread.status, thread.resolved, leadPull(thread.pulls)?.stage);
}
function projectThreads(snapshot, project) {
  const seated = seats(snapshot);
  const shared = sharedFolders(snapshot);
  const spread = project.machines.length > 1;
  const lead = leadOf(project);
  const beside = lead !== undefined && seated.has(lead.address);
  return threadsOf(project).map((member) => {
    const seat = seated.get(member.address);
    const refs = refsOf(member.address, member.declared);
    return {
      key: member.address,
      project: project.name,
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
      checkout: checkout(seat, shared),
      refs,
      pulls: stackOf(refs, snapshot.pulls),
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
  const members = new Set(project.members.map((member) => member.address));
  const spaceOfTab = new Map(snapshot.spaces.flatMap((space) => space.tabs.map((tab) => [tab.id, space])));
  const sessions = snapshot.panes.filter((pane) => pane.terminal !== null);
  const spaceOf = (address) => spaceOfTab.get(sessions.find((pane) => pane.terminal === address)?.tab ?? "");
  const home = spaceOf(leadOf(project)?.address);
  const foreign = sessions.some((pane) => spaceOfTab.get(pane.tab) === home && !members.has(pane.terminal ?? ""));
  const space = home && !foreign ? home.id : null;
  const outside = [...members].filter((address) => space === null || spaceOf(address)?.id !== space);
  return { space, outside };
}
function longestFirst(a, b) {
  return (a.since ?? Number.POSITIVE_INFINITY) - (b.since ?? Number.POSITIVE_INFINITY);
}
var QUEUES = ["review", "waiting", "finished"];
function groupThreads(threads) {
  return GROUPS.map((group) => {
    const members = threads.filter((thread) => threadGroup(thread) === group.id);
    return { ...group, threads: QUEUES.includes(group.id) ? members.sort(longestFirst) : members };
  }).filter((group) => group.threads.length > 0);
}
function agentOrder(agents, shown) {
  const place = new Map(shown.map((thread, index) => [thread.key, index]));
  const rank = (agent) => place.get(agent.address) ?? Number.POSITIVE_INFINITY;
  return [...agents].sort((a, b) => rank(a) - rank(b)).map((agent) => agent.address);
}

// src/waits.ts
function isWaiting(member) {
  return groupOf(member.status, member.resolved) === "waiting";
}
function waits(snapshot, projects) {
  return projects.flatMap((project) => {
    const waiting = project.members.filter(isWaiting);
    if (waiting.length === 0)
      return [];
    const threads = new Map(projectThreads(snapshot, project).map((thread) => [thread.key, thread]));
    return waiting.map((member) => {
      const thread = threads.get(member.address);
      return {
        terminal: member.address,
        project: project.name,
        title: thread?.title ?? null,
        since: thread ? thread.since : member.since
      };
    });
  }).sort(longestFirst);
}
function nextWait(all, focused) {
  const at = all.findIndex((wait) => wait.terminal === focused);
  return all[(at + 1) % all.length];
}

// src/navigation.ts
function remember(project, thread) {
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
  remember(thread.project, thread.key);
  showInPanel(thread.key, true);
}
function showThreadList() {
  remember(readScene().shown?.name, null);
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
function stepProject(step) {
  const scene = readScene();
  const count = scene.projects.length;
  const shown = scene.shown ? scene.projects.indexOf(scene.shown) : null;
  const from = shown ?? (step === 1 ? -1 : 0);
  const next = scene.projects[(from + step + count) % count];
  if (next)
    openProject(scene, next);
}
function openNextWait() {
  const scene = readScene();
  const wait = nextWait(waits(scene.snapshot, scene.projects), scene.snapshot.focused);
  const project = scene.projects.find((candidate) => candidate.name === wait?.project);
  if (!wait || !project) {
    notify2({ title: "No session waits on you", level: "info" });
    return;
  }
  const thread = threadAt(scene.snapshot, [project], wait.terminal);
  if (!thread) {
    openProject(scene, project);
    return;
  }
  const home = projectHome(scene.snapshot, project);
  if (home && thread.opens === "panel")
    focusTerminal(home);
  openThread(thread);
}
function selectProject(index) {
  const scene = readScene();
  const project = scene.projects[index];
  if (project)
    openProject(scene, project);
}

// src/pull-reader.ts
import { exec as exec2, setShared as setShared3 } from "herdr";

// src/pull-asks.ts
function askOf(thread, ref) {
  const on = machineOf(thread.key);
  if (ref.kind === "declared")
    return { key: refKey(ref), args: [ref.url], cwd: null, on };
  return thread.checkout ? { key: refKey(ref), args: [], cwd: thread.checkout.folder, on } : null;
}
function pullAsks(threads) {
  const asks = threads.flatMap((thread) => thread.refs.map((ref) => askOf(thread, ref)));
  const byKey = new Map(asks.filter((ask) => ask !== null).map((ask) => [ask.key, ask]));
  return [...byKey.values()];
}

// src/pull-reader.ts
var PULL_TIMEOUT = 20000;
var NO_PULL = /no pull requests found|Could not resolve to a PullRequest/;
async function readPull(ask, known) {
  const before = known[ask.key] ?? null;
  try {
    const options = { ...ask.cwd !== null && { cwd: ask.cwd }, on: ask.on, timeout: PULL_TIMEOUT };
    const result = await exec2("gh", ["pr", "view", ...ask.args, "--json", PULL_FIELDS], options);
    if (result.code === 0)
      return parsePull(JSON.parse(result.stdout)) ?? before;
    return NO_PULL.test(result.stderr) ? null : before;
  } catch {
    return before;
  }
}
async function refreshPulls() {
  const { snapshot, projects } = readScene();
  const open = projects.flatMap((project) => projectThreads(snapshot, project)).filter((thread) => !thread.resolved);
  const read = await Promise.all(pullAsks(open).map(async (ask) => [ask.key, await readPull(ask, snapshot.pulls)]));
  const pulls = Object.fromEntries(read.filter(([, pull]) => pull !== null));
  if (JSON.stringify(pulls) !== JSON.stringify(snapshot.pulls))
    setShared3(PULLS, pulls);
}

// src/background.ts
var MOD2 = "projects";
var LOOK_EVERY = 5000;
var PULLS_EVERY = 120000;
var SELECT = Object.fromEntries(Array.from({ length: 9 }, (_, index) => [`select-${index + 1}`, () => selectProject(index)]));
function reviewOpenThread() {
  const { thread } = readPanel();
  if (thread)
    openReview(thread);
}
var COMMANDS = {
  ...SELECT,
  new: openNewProjectDialog,
  next: () => stepProject(1),
  prev: () => stepProject(-1),
  "next-waiting": openNextWait,
  threads: showThreadList,
  review: reviewOpenThread
};
async function runCommands(cx) {
  for (;; ) {
    const name = await nextCommand();
    cx.notify();
    try {
      COMMANDS[name]?.();
    } catch (error) {
      reportFailure(`Could not run ${MOD2}.${name}`, error);
    }
  }
}
function watchWaits(cx) {
  let badge;
  const look = () => {
    const { snapshot, projects } = readScene();
    const amount = waits(snapshot, projects).length;
    const count = amount > 0 ? String(amount) : null;
    if (count !== badge)
      setBadge(count);
    badge = count;
  };
  look();
  cx.timer.every(LOOK_EVERY, look);
}
function watchPulls(cx) {
  const look = () => {
    if (window2()?.visible)
      refreshPulls();
  };
  look();
  cx.timer.every(PULLS_EVERY, look);
}
function startBackground(cx) {
  if (checking())
    return;
  cx.spawn(runCommands);
  watchWaits(cx);
  watchPulls(cx);
}

// src/parts/new-project.ts
import { h_flex as h_flex3, InputState } from "gpui-base";
import { closeOverlay, machines as machines2 } from "herdr";

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
  "done",
  "ansi1",
  "ansi2",
  "ansi3",
  "ansi4",
  "ansi5",
  "ansi6"
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
var MARK = 14;
function markBox(mark) {
  const box = div().size(MARK).flex_none().flex().items_center().justify_center();
  return mark ? box.child(mark) : box;
}
function statusMark(colors, status) {
  if (status === null)
    return markBox();
  if (status === "working")
    return markBox(svg(chromeIcon("spinner")).size(12).text_color(colors.working).spin(900));
  if (status === "blocked") {
    return markBox().rounded(4).bg(`${colors.blocked}26`).text_size(10.5).font_bold().text_color(colors.blocked).child("!");
  }
  const dot = div().size(7).rounded(4);
  return markBox(status === "idle" ? dot.border(1.5).border_color(colors.dim) : dot.bg(colors.done));
}
var ICON_BUTTON = { regular: { box: 24, icon: 14, corner: 6 }, small: { box: 22, icon: 13, corner: 5 } };
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
  const bar = h_flex().id(props.id).px(8).h(30).flex_none().gap(5).items_center().text_size(11.5).font_medium().text_color(props.tone ?? colors.dim).child(label);
  const folding = optional(bar, props.fold, (el, fold) => el.cursor_pointer().hover((style) => style.text_color(colors.foreground)).on_click((_event, cx) => fold.onToggle(cx)).child(svg(chromeIcon(fold.open ? "chevron-down" : "chevron-right")).size(11).flex_none()));
  return optional(folding.child(div().flex_1()), props.action, (el, action) => el.child(iconButton(colors, action)));
}
function textButton(colors, button) {
  const face = h_flex().id(button.id).h(32).px(14).items_center().rounded(8).border_1().border_color(button.primary ? colors.solid : colors.input).bg(button.primary ? colors.solid : colors.raised).text_color(button.primary ? colors.solid_foreground : colors.foreground).text_size(12.5).font_medium().child(button.label);
  if (button.disabled)
    return face.opacity(0.45);
  return face.cursor_pointer().hover((style) => style.opacity(0.88)).on_click((_event, cx) => button.onClick(cx));
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

// src/parts/new-project.ts
function choices() {
  const known = machines2().filter((machine) => machine.layout !== "loading").map((machine) => ({ name: machine.name, offline: machine.layout === "unavailable" }));
  return [...known.filter((choice) => choice.name !== null), ...known.filter((choice) => choice.name === null)];
}
function machineLabel(choice) {
  const name = choice.name ?? "This computer";
  return choice.offline ? `${name} (offline)` : name;
}

class NewProjectDialog {
  overlay;
  name = InputState.new({ placeholder: "billing" });
  folder = InputState.new({ placeholder: "/path/to/the/repository" });
  machine;
  problem = null;
  starting = false;
  constructor(overlay, cx) {
    this.overlay = overlay;
    this.machine = choices().find((choice) => !choice.offline)?.name ?? null;
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
      hint: this.starting ? `Starting the orchestrator on ${this.machine ?? "this computer"}. This can take a minute.` : "Starts an orchestrator. It runs the project's threads on the same machine.",
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
        { id: "cancel", label: this.starting ? "Hide" : "Cancel", onClick: () => closeOverlay(this.overlay) },
        {
          id: "create",
          label: this.starting ? "Starting…" : "Create",
          primary: true,
          disabled: this.starting,
          onClick: (cx) => this.create(cx)
        }
      ]
    });
  }
  machinePicker(colors) {
    return h_flex3().gap(6).flex_wrap().children(choices().map((choice) => textButton(colors, {
      id: `machine-${choice.name ?? LOCAL}`,
      label: machineLabel(choice),
      primary: choice.name === this.machine,
      disabled: choice.offline || this.starting,
      onClick: (cx) => this.pickMachine(choice.name, cx)
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
    if (this.starting)
      return;
    const name = this.name.value().trim();
    const folder = this.folder.value().trim();
    this.problem = this.check(name, folder);
    this.starting = this.problem === null;
    cx.notify();
    if (!this.starting)
      return;
    const start = startProject(name, this.machine, folder);
    start.catch((error) => reportFailure(`Could not start ${name}`, error));
    cx.spawn((task) => this.follow(start, task));
  }
  async follow(start, cx) {
    try {
      await start;
      closeOverlay(this.overlay);
    } catch (error) {
      this.starting = false;
      this.problem = { field: null, message: messageOf(error) };
      cx.notify();
    }
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
function place2(project, offline) {
  const [machine] = project.machines;
  const where = project.machines.length > 1 ? count(project.machines.length, "machine") : machine ?? LOCAL;
  return offline ? `${where} · offline` : where;
}
function detail(project, groups) {
  const lead = leadOf(project);
  const open = groups.filter((group) => group !== "resolved");
  const amount = (group) => open.filter((candidate) => candidate === group).length;
  const moves = [
    lead && groupOf(lead.status, lead.resolved) === "waiting" ? "orchestrator waits" : null,
    amount("review") > 0 ? `${amount("review")} to review` : null,
    amount("waiting") > 0 ? `${amount("waiting")} waiting` : null,
    amount("finished") > 0 ? `${amount("finished")} finished` : null,
    amount("working") > 0 ? `${amount("working")} working` : null
  ].filter((move) => move !== null);
  if (moves.length > 0)
    return moves.join(" · ");
  return open.length > 0 ? count(open.length, "thread") : "No thread";
}
function projectEntry(project, { selected, offline, groups }) {
  return {
    id: `project-${project.name}`,
    name: project.name,
    aside: place2(project, offline),
    detail: detail(project, groups),
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
  const needsYou = entry.status === "blocked";
  const row = h_flex5().id(entry.id).px(8).py(5).flex_none().gap(7).items_center().rounded(8).cursor_pointer().when(entry.selected, (el) => el.bg(colors.selected)).hover((style) => style.bg(colors.hover)).on_click((_event, cx) => actions.onOpen(cx)).on_mouse_down("left", (_event, cx) => actions.onPress(cx)).on_mouse_up("left", (_event, cx) => actions.onDrop(cx)).child(statusMark(colors, entry.status)).child(v_flex2().flex_1().min_w(0).child(h_flex5().gap(6).items_center().child(div4().flex_1().min_w(0).truncate().text_color(entry.selected || needsYou ? colors.foreground : colors.muted).when(needsYou, (el) => el.font_medium()).child(entry.name)).child(div4().flex_none().text_size(10.5).text_color(colors.muted).child(entry.aside))).child(div4().truncate().text_size(11).text_color(colors.muted).child(entry.detail)));
  return withMenu(row, actions.onMenu);
}
function threadMark(colors, thread) {
  if (thread.agent)
    return statusMark(colors, thread.status ?? "idle");
  return markBox(svg2(chromeIcon("terminal")).size(11).text_color(colors.dim));
}
function threadMeta(thread, now) {
  const since = thread.since === null ? null : age(now - thread.since);
  return [thread.aside, stackLabel(thread.pulls), since].filter((part) => part !== null).join(" · ");
}
function threadState(thread, now) {
  return [groupLabel(threadGroup(thread)), threadMeta(thread, now)].filter(Boolean).join(" · ");
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
  const trailing = view.hovered ? resolveButton(colors, thread, actions.onResolve) : div4().flex_none().text_size(11).text_color(colors.muted).child(threadMeta(thread, view.now));
  const row = v_flex2().id(`thread-${thread.key}`).px(10).py(7).flex_none().gap(2).rounded(8).cursor_pointer().when(thread.active, (el) => el.bg(colors.selected)).hover((style) => style.bg(colors.hover)).on_hover((on, cx) => actions.onHover(on, cx)).on_click((_event, cx) => actions.onOpen(cx)).child(h_flex5().h(22).gap(7).items_center().child(threadMark(colors, thread)).child(div4().flex_1().min_w(0).truncate().text_color(strong ? colors.foreground : colors.muted).child(thread.title)).child(trailing));
  const noted = optional(row, thread.note, (el, note) => el.child(div4().pl(21).truncate().text_size(11.5).text_color(thread.status === "blocked" ? colors.blocked : colors.muted).child(note)));
  return optional(noted, actions.onMenu, withMenu);
}

// src/parts/project-list.ts
class ProjectList {
  pressed = null;
  render() {
    const colors = readTheme();
    const scene = readScene();
    const offline = readOffline();
    const rows = scene.projects.map((project) => this.row(colors, scene, project, project.machines.some((machine) => offline.has(machine))));
    return v_flex3().id("project-list").size_full().min_h(0).px(8).pb(8).gap(1).bg(colors.chrome).text_size(13).overflow_y_scrollbar().on_mouse_up("left", () => this.release()).child(heading(colors, {
      id: "projects",
      label: "Projects",
      action: { id: "new-project", icon: chromeIcon("plus"), tip: "New project", onClick: openNewProjectDialog }
    })).children(rows).when(rows.length === 0, (el) => el.child(div5().px(8).text_size(12).text_color(colors.muted).child("No project yet. Start one with the + above.")));
  }
  row(colors, scene, project, offline) {
    const groups = projectThreads(scene.snapshot, project).map(threadGroup);
    const entry = projectEntry(project, { selected: project === scene.shown, offline, groups });
    return entryRow(colors, entry, {
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
function sessions(amount) {
  return `${amount} session${amount === 1 ? "" : "s"}`;
}
function endings(project) {
  const { snapshot } = readScene();
  const { space, outside } = projectFootprint(snapshot, project);
  const all = sessions(project.members.length);
  return [
    {
      id: "close-project",
      icon: chromeIcon("x"),
      label: "Close project",
      consequence: `End ${all}`,
      run: () => closeProject(space, outside)
    },
    {
      id: "ungroup-project",
      icon: chromeIcon("layers"),
      label: "Ungroup",
      consequence: `Keep ${all} running`,
      run: () => ungroupProject(project)
    }
  ];
}

class ProjectMenu {
  overlay;
  name;
  asked = null;
  constructor(overlay, name) {
    this.overlay = overlay;
    this.name = name;
  }
  render() {
    const colors = readTheme();
    const project = readScene().projects.find((candidate) => candidate.name === this.name);
    const all = project ? endings(project) : [];
    const asked = all.find((ending) => ending.id === this.asked);
    const items = asked ? this.confirmation(asked) : this.choices(all);
    return v_flex4().id("project-menu").w_full().p(5).bg(colors.popover).text_size(12.8).children(items.map((item) => menuItem(colors, item)));
  }
  choices(all) {
    const rename = { id: "rename-project", icon: chromeIcon("square-pen"), label: "Rename", onClick: () => this.rename() };
    return [rename, ...all.map((ending) => ({ ...ending, onClick: (cx) => this.ask(ending.id, cx) }))];
  }
  confirmation(ending) {
    return [
      {
        id: `confirm-${ending.id}`,
        icon: chromeIcon("check"),
        label: ending.consequence,
        onClick: () => this.end(ending)
      },
      { id: "cancel", icon: chromeIcon("chevron-left"), label: "Cancel", onClick: (cx) => this.ask(null, cx) }
    ];
  }
  rename() {
    closeOverlay2(this.overlay);
    openRenameProjectDialog(this.name);
  }
  ask(id, cx) {
    this.asked = id;
    cx.notify();
  }
  end(ending) {
    closeOverlay2(this.overlay);
    ending.run().catch((error) => reportFailure(`Could not end ${this.name}`, error));
  }
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

// src/parts/review.ts
import { h_flex as h_flex7, InputState as InputState3, TextareaState, v_flex as v_flex6, VirtualListScrollHandle } from "gpui-base";
import { closeOverlay as closeOverlay4 } from "herdr";

// src/review/diff.ts
var USUAL_BASES = ["origin/HEAD", "origin/main", "origin/master", "main", "master"];
function baseRefs(pullBase) {
  const named = pullBase ? [`origin/${pullBase}`, pullBase] : [];
  return [...new Set([...named, ...USUAL_BASES])];
}
function reviewRange(pull, branch) {
  const tip = pull && pull.head !== branch ? pull.head : null;
  return { bases: baseRefs(pull?.base ?? null), tip };
}
var NO_FILE = "/dev/null";
var FILE = "diff --git ";
var QUOTED = /^"(.*)"$/;
var HUNK = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/;
function samePath(pair) {
  const path = pair.slice("a/".length, (pair.length - " ".length) / 2);
  return pair === `a/${path} b/${path}` ? path : null;
}
function sidePath(line) {
  const path = line.slice(4).replace(/\t$/, "").replace(QUOTED, "$1");
  return path === NO_FILE ? null : path.slice(2);
}
function openFile(line) {
  const pair = line.slice(FILE.length);
  return { path: samePath(pair) ?? pair, from: null, change: "modified", binary: false, hunks: [] };
}
function readHeader(file, line) {
  if (line.startsWith("new file mode"))
    file.change = "added";
  else if (line.startsWith("deleted file mode"))
    file.change = "deleted";
  else if (line.startsWith("rename from "))
    file.from = line.slice("rename from ".length);
  else if (line.startsWith("rename to ")) {
    file.path = line.slice("rename to ".length);
    file.change = "renamed";
  } else if (line.startsWith("Binary files ") || line === "GIT binary patch")
    file.binary = true;
  else if (line.startsWith("--- ") || line.startsWith("+++ "))
    file.path = sidePath(line) ?? file.path;
}
function openHunk(file, line, sizes) {
  file.hunks.push({ header: line, lines: [] });
  return {
    old: Number(sizes[1]),
    oldLeft: Number(sizes[2] ?? 1),
    now: Number(sizes[3]),
    nowLeft: Number(sizes[4] ?? 1)
  };
}
function readLine(lines, line, at) {
  const text = line.slice(1);
  if (line.startsWith("+")) {
    lines.push({ sign: "+", old: null, now: at.now++, text });
    at.nowLeft--;
  } else if (line.startsWith("-")) {
    lines.push({ sign: "-", old: at.old++, now: null, text });
    at.oldLeft--;
  } else if (!line.startsWith("\\")) {
    lines.push({ sign: " ", old: at.old++, now: at.now++, text });
    at.oldLeft--;
    at.nowLeft--;
  }
}
function count2(lines, sign) {
  return lines.filter((line) => line.sign === sign).length;
}
function closeFile(file) {
  const lines = file.hunks.flatMap((hunk) => hunk.lines);
  return {
    ...file,
    from: file.change === "renamed" ? file.from : null,
    added: count2(lines, "+"),
    removed: count2(lines, "-")
  };
}
function parseDiff(text) {
  const files = [];
  let at = { old: 0, now: 0, oldLeft: 0, nowLeft: 0 };
  for (const line of text.split(`
`)) {
    const file = files[files.length - 1];
    const hunk = file?.hunks[file.hunks.length - 1];
    const sizes = HUNK.exec(line);
    if (hunk && (at.oldLeft > 0 || at.nowLeft > 0))
      readLine(hunk.lines, line, at);
    else if (line.startsWith(FILE))
      files.push(openFile(line));
    else if (file && sizes)
      at = openHunk(file, line, sizes);
    else if (file)
      readHeader(file, line);
  }
  return files.map(closeFile);
}
function parseBranchDiff(output) {
  const [base = "", ...diff] = output.split(`
`);
  return { base, files: parseDiff(diff.join(`
`)) };
}

// src/review/draft.ts
var NO_DRAFT = { note: "", comments: [] };
function anchorKey(anchor) {
  return `${anchor.side}:${anchor.line}:${anchor.path}`;
}
function anchorOf(path, line) {
  return line.now === null ? { path, side: "old", line: line.old ?? 0 } : { path, side: "new", line: line.now };
}
function isSide(value) {
  return value === "old" || value === "new";
}
function parseMark(value) {
  if (!isRecord(value) || !isSide(value.side) || typeof value.line !== "number")
    return null;
  return { side: value.side, line: value.line };
}
function parsePosting(value) {
  return value === "due" || value === "done" ? value : "none";
}
function parseAbout(value) {
  if (!isRecord(value))
    return null;
  const author = text(value.author);
  const url = text(value.url);
  const discussion = text(value.discussion);
  if (!author || !url || !discussion || typeof value.quote !== "string")
    return null;
  return { author, url, quote: value.quote, discussion, post: parsePosting(value.post) };
}
function parseComment(value) {
  if (!isRecord(value))
    return null;
  const path = text(value.path);
  const body = text(value.body);
  const last = parseMark(value);
  if (!path || !body || !last || typeof value.code !== "string")
    return null;
  const start = parseMark(value.start);
  return { path, ...last, start, code: value.code, body, about: parseAbout(value.about) };
}
function parseDraft(value) {
  if (!isRecord(value))
    return NO_DRAFT;
  const comments = Array.isArray(value.comments) ? value.comments.map(parseComment) : [];
  return {
    note: typeof value.note === "string" ? value.note : "",
    comments: comments.filter((comment) => comment !== null)
  };
}
function isEmpty(draft) {
  return draft.comments.length === 0 && draft.note.trim() === "";
}
function parseDrafts(value) {
  if (!isRecord(value))
    return {};
  const drafts = Object.entries(value).map(([thread, draft]) => [thread, parseDraft(draft)]);
  return Object.fromEntries(drafts.filter(([, draft]) => !isEmpty(draft)));
}
function withDraft(drafts, thread, draft) {
  const kept = Object.entries({ ...drafts, [thread]: draft });
  return Object.fromEntries(kept.filter(([, value]) => !isEmpty(value)));
}
function commentAt(draft, anchor) {
  const key = anchorKey(anchor);
  return draft.comments.find((comment) => anchorKey(comment) === key);
}
function withoutComment(draft, anchor) {
  const key = anchorKey(anchor);
  return { ...draft, comments: draft.comments.filter((comment) => anchorKey(comment) !== key) };
}
function withComment(draft, span, written) {
  const rest = withoutComment(draft, span);
  const { path, side, line, start } = span;
  const body = written.body.trim();
  return body ? { ...rest, comments: [...rest.comments, { path, side, line, start, ...written, body }] } : rest;
}
function withNote(draft, note) {
  return { ...draft, note };
}
function duePosts(draft) {
  return draft.comments.filter((comment) => comment.about?.post === "due");
}
function withPosted(draft, anchor) {
  const key = anchorKey(anchor);
  const posted = (comment) => anchorKey(comment) === key && comment.about ? { ...comment, about: { ...comment.about, post: "done" } } : comment;
  return { ...draft, comments: draft.comments.map(posted) };
}
function inOrder(comments, paths) {
  const place = (comment) => {
    const index = paths.indexOf(comment.path);
    return index < 0 ? paths.length : index;
  };
  return [...comments].sort((a, b) => place(a) - place(b) || a.path.localeCompare(b.path) || a.line - b.line || a.side.localeCompare(b.side));
}
var INDENT = "   ";
function indent(text) {
  return text.split(`
`).map((line) => line ? INDENT + line : "").join(`
`);
}
function linesOf(span) {
  return span.start ? `${span.start.line}-${span.line}` : String(span.line);
}
function quoted(code) {
  if (!code.trim())
    return [];
  return [
    indent(code.split(`
`).map((line) => `> ${line.trim()}`).join(`
`))
  ];
}
function answerText(about) {
  const posted = about.post === "done" ? ", where this answer is posted too" : "";
  return `In answer to @${about.author} on GitHub (${about.url})${posted}:
> ${about.quote}`;
}
function commentText(comment, index) {
  const removed = comment.side === "old" ? " (a line the branch removes)" : "";
  const answers = comment.about ? [indent(answerText(comment.about))] : [];
  return [
    `${index + 1}. ${comment.path}:${linesOf(comment)}${removed}`,
    ...quoted(comment.code),
    ...answers,
    indent(comment.body)
  ].join(`
`);
}
function countOf(comments) {
  return comments === 1 ? "1 comment" : `${comments} comments`;
}
function draftKey(thread, pull) {
  return pull ? `${thread}#${pull.number}` : thread;
}
function reviewMessage(draft, paths, pull) {
  const comments = inOrder(draft.comments, paths);
  const what = pull ? `pull request #${pull.number} (${pull.url})` : "your branch";
  const head = comments.length ? `Review of ${what}: ${countOf(comments.length)}.` : `Review of ${what}.`;
  const note = draft.note.trim();
  return [head, ...note ? [note] : [], ...comments.map(commentText)].join(`

`);
}

// src/review/discussions.ts
var DISCUSSIONS_QUERY = `query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line originalLine diffSide startLine originalStartLine startDiffSide
          comments(first: 50) { nodes { author { login } body url } }
        }
      }
    }
  }
}`;
var REPLY_MUTATION = `mutation($discussion: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: $discussion, body: $body }) {
    comment { url }
  }
}`;
function nodes(value) {
  const list = asRecord(value).nodes;
  return Array.isArray(list) ? list : [];
}
function parseRemark(value) {
  const raw = asRecord(value);
  const body = text(raw.body);
  const url = text(raw.url);
  return body && url ? { author: text(asRecord(raw.author).login) ?? "ghost", body, url } : null;
}
function sideOf(value) {
  return value === "LEFT" ? "old" : "new";
}
function parseDiscussion(value) {
  const raw = asRecord(value);
  const id = text(raw.id);
  const path = text(raw.path);
  const line = raw.line ?? raw.originalLine;
  const remarks = nodes(raw.comments).map(parseRemark).filter((remark) => remark !== null);
  if (raw.isResolved === true || !id || !path || typeof line !== "number" || remarks.length === 0)
    return null;
  const side = sideOf(raw.diffSide);
  const first = raw.startLine ?? raw.originalStartLine;
  const start = typeof first === "number" ? { side: raw.startDiffSide ? sideOf(raw.startDiffSide) : side, line: first } : null;
  return { id, path, side, line, start, outdated: raw.isOutdated === true, remarks };
}
function parseDiscussions(answer) {
  const pull = asRecord(asRecord(asRecord(answer).data).repository).pullRequest;
  return nodes(asRecord(pull).reviewThreads).map(parseDiscussion).filter((discussion) => discussion !== null);
}
var QUOTE = 160;
function aboutOf(discussion) {
  const [first] = discussion.remarks;
  if (!first)
    return null;
  const start = first.body.trim().split(`
`)[0] ?? "";
  const quote = start.length > QUOTE ? `${start.slice(0, QUOTE)}…` : start;
  return { author: first.author, url: first.url, quote, discussion: discussion.id, post: "none" };
}
function discussionsAt(discussions, anchor) {
  const key = anchorKey(anchor);
  return discussions.filter((discussion) => anchorKey(discussion) === key);
}

// src/review/reader.ts
import { exec as exec3 } from "herdr";
var DIFF_TIMEOUT = 60000;
var FOLDER = "-";
var DIFF = `cd "$(git rev-parse --show-toplevel)" || exit 1
tip=$1
shift
[ "$tip" = ${FOLDER} ] && tip=
if [ -n "$tip" ] && ! git rev-parse --verify --quiet "$tip^{commit}" >/dev/null; then tip="origin/$tip"; fi
for base in "$@"; do
  fork=$(git merge-base "$base" "\${tip:-HEAD}" 2>/dev/null) || continue
  printf '%s\\n' "$base"
  git --no-optional-locks -c core.quotePath=false diff --no-color --no-ext-diff --no-textconv -M "$fork" \${tip:+"$tip"} -- || exit 1
  [ -n "$tip" ] || git ls-files --others --exclude-standard -z |
    xargs -0 -r -n 1 git -c core.quotePath=false diff --no-color --no-index -- /dev/null
  exit 0
done
echo "this repository has no base branch to compare with" >&2
exit 1`;
var GITHUB_TIMEOUT = 30000;
async function inFolder(thread, program, args, timeout) {
  if (!thread.checkout)
    throw new Error("this thread has no folder of its own to review");
  const result = await exec3(program, args, { cwd: thread.checkout.folder, on: machineOf(thread.key), timeout });
  if (result.code !== 0)
    throw new Error(result.stderr.trim() || `${program} ended with code ${result.code}`);
  return result.stdout;
}
function askGitHub(thread, host, query, fields) {
  const args = ["api", "graphql", "--hostname", host, "-f", `query=${query}`, ...fields];
  return inFolder(thread, "gh", args, GITHUB_TIMEOUT);
}
async function readBranchDiff(thread, range) {
  const args = ["-c", DIFF, "sh", range.tip ?? FOLDER, ...range.bases];
  return parseBranchDiff(await inFolder(thread, "sh", args, DIFF_TIMEOUT));
}
async function readDiscussions(thread, pull) {
  const place = pull && placeOf(pull.url);
  if (!place)
    return [];
  const fields = [`owner=${place.owner}`, `name=${place.name}`, `number=${place.number}`];
  const answer = await askGitHub(thread, place.host, DISCUSSIONS_QUERY, fields.flatMap((field) => ["-F", field]));
  return parseDiscussions(JSON.parse(answer));
}
async function postReply(thread, pull, about, body) {
  const place = placeOf(pull.url);
  if (!place)
    throw new Error(`${pull.url} is not the URL of a pull request`);
  const fields = [`discussion=${about.discussion}`, `body=${body}`].flatMap((field) => ["-f", field]);
  try {
    await askGitHub(thread, place.host, REPLY_MUTATION, fields);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    throw new Error(`GitHub did not take the reply to @${about.author}: ${reason}`);
  }
}

// src/review/rows.ts
var MAX_LINES = 5000;
var MAX_REMARK_LINES = 12;
var TAB = 4;
function untab(text) {
  if (!text.includes("\t"))
    return text;
  const parts = text.split("\t");
  const last = parts.pop() ?? "";
  let padded = "";
  for (const part of parts) {
    padded += part;
    padded += " ".repeat(TAB - padded.length % TAB);
  }
  return padded + last;
}
function wrapLine(line, columns) {
  const lines = [];
  let rest = line;
  while (rest.length > columns) {
    const space = rest.lastIndexOf(" ", columns);
    const cut = space > 0 ? space : columns;
    lines.push(rest.slice(0, cut));
    rest = rest.slice(cut).trimStart();
  }
  return [...lines, rest];
}
function wrap(text, columns) {
  const width = Math.max(1, Math.floor(columns));
  return text.split(`
`).flatMap((line) => wrapLine(untab(line), width));
}
function gone(path) {
  return { path, from: null, change: "modified", binary: false, hunks: [], added: 0, removed: 0 };
}
function reviewFiles(files, comments, discussions) {
  const entry = (file, isGone) => ({
    file,
    comments: comments.filter((comment) => comment.path === file.path),
    discussions: discussions.filter((discussion) => discussion.path === file.path),
    gone: isGone
  });
  const changed = new Set(files.map((file) => file.path));
  const spoken = [...comments, ...discussions].map((anchor) => anchor.path);
  const left = [...new Set(spoken)].filter((path) => !changed.has(path));
  return [...files.map((file) => entry(file, false)), ...left.map((path) => entry(gone(path), true))];
}
function lineKey(anchor) {
  return `line:${anchorKey(anchor)}`;
}
function body(text, columns) {
  return wrap(text, columns).map((line) => ({ text: line, head: false }));
}
function whereLine(anchor, stale) {
  return stale ? [{ text: `Line ${anchor.line}, which is not in the diff:`, head: true }] : [];
}
var POSTING = {
  none: null,
  due: "A reply on GitHub too, when you send the review:",
  done: "Posted on GitHub:"
};
function postingLine(comment) {
  const text = POSTING[comment.about?.post ?? "none"];
  return text ? [{ text, head: true }] : [];
}
function commentCard(comment, columns, stale) {
  const lines = [...whereLine(comment, stale), ...postingLine(comment), ...body(comment.body, columns)];
  return { kind: "card", key: `comment:${anchorKey(comment)}`, anchor: comment, from: "draft", lines, stale };
}
function remarkLines(remark, columns) {
  const lines = body(remark.body.trim(), columns);
  const cut = lines.length > MAX_REMARK_LINES ? [{ text: "…", head: false }] : [];
  return [{ text: `@${remark.author} on GitHub`, head: true }, ...lines.slice(0, MAX_REMARK_LINES), ...cut];
}
function discussionCard(discussion, index, columns, stale) {
  const span = discussion.start && !stale ? [{ text: `On lines ${linesOf(discussion)}:`, head: true }] : [];
  const lines = [
    ...whereLine(discussion, stale),
    ...span,
    ...discussion.remarks.flatMap((remark) => remarkLines(remark, columns))
  ];
  return {
    kind: "card",
    key: `discussion:${discussion.path}:${index}`,
    anchor: discussion,
    from: "github",
    lines,
    stale
  };
}
var NEW_SIDE = /^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))?/;
function unchangedBefore(hunks) {
  let next = 1;
  return hunks.map((hunk) => {
    const [, start = "1", count = "1"] = NEW_SIDE.exec(hunk.header) ?? [];
    const first = Number(count) === 0 ? Number(start) + 1 : Number(start);
    const gap = Math.max(0, first - next);
    next = first + Number(count);
    return gap;
  });
}
function emptyText(entry) {
  if (entry.gone)
    return "This file is no longer in the diff.";
  if (entry.file.binary)
    return "A binary file: it has no text to show.";
  return entry.file.hunks.length === 0 ? "No line of this file changed." : null;
}
function cardsOf(entry, columns, stale) {
  const cards = new Map;
  const add = (anchor, card) => {
    const key = anchorKey(anchor);
    cards.set(key, [...cards.get(key) ?? [], card]);
  };
  entry.discussions.forEach((discussion, index) => add(discussion, discussionCard(discussion, index, columns, stale)));
  for (const comment of entry.comments)
    add(comment, commentCard(comment, columns, stale));
  return cards;
}
function fileRows(entry, columns) {
  const { file } = entry;
  const lines = file.hunks.flatMap((hunk) => hunk.lines);
  const shown = new Set(lines.map((line) => anchorKey(anchorOf(file.path, line))));
  const cards = cardsOf(entry, columns, false);
  const stale = [...cardsOf(entry, columns, true)].filter(([key]) => !shown.has(key));
  const rows = stale.flatMap(([, rowsOfLine]) => rowsOfLine);
  const empty = emptyText(entry);
  if (empty)
    return [...rows, { kind: "note", key: `note:empty:${file.path}`, text: empty }];
  const gaps = unchangedBefore(file.hunks);
  let drawn = 0;
  for (const [index, hunk] of file.hunks.entries()) {
    if (drawn >= MAX_LINES)
      break;
    const gap = gaps[index] ?? 0;
    if (gap > 0)
      rows.push({
        kind: "hunk",
        key: `hunk:${file.path}:${index}`,
        text: `${gap} unchanged line${gap === 1 ? "" : "s"}`
      });
    for (const line of hunk.lines.slice(0, MAX_LINES - drawn)) {
      const anchor = anchorOf(file.path, line);
      const under = cards.get(anchorKey(anchor)) ?? [];
      const mark = { commented: false, discussed: false };
      rows.push({ kind: "line", key: lineKey(anchor), anchor, line, text: untab(line.text), ...mark }, ...under);
    }
    drawn += hunk.lines.length;
  }
  if (lines.length > MAX_LINES) {
    rows.push({
      kind: "note",
      key: `note:cut:${file.path}`,
      text: `This diff is long: only its first ${MAX_LINES} lines show.`
    });
  }
  const covered = (spans) => new Set(spans.flatMap((span) => spanRows(rows, span).map((row) => row.key)));
  const commented = covered(entry.comments);
  const discussed = covered(entry.discussions);
  return rows.map((row) => row.kind === "line" ? { ...row, commented: commented.has(row.key), discussed: discussed.has(row.key) } : row);
}
function lineRows(rows) {
  return rows.filter((row) => row.kind === "line");
}
function spanRows(rows, span) {
  const lines = lineRows(rows);
  const last = lines.findIndex((row) => row.key === lineKey(span));
  if (last < 0)
    return [];
  const from = span.start ? lineKey({ path: span.path, ...span.start }) : null;
  const first = lines.findIndex((row) => row.key === from);
  return lines.slice(first < 0 || first > last ? last : first, last + 1);
}
function spanBetween(rows, a, b) {
  const lines = lineRows(rows);
  const at = (anchor) => lines.findIndex((row) => row.key === lineKey(anchor));
  const [first, last] = at(a) <= at(b) ? [a, b] : [b, a];
  const start = anchorKey(first) === anchorKey(last) ? null : { side: first.side, line: first.line };
  return { path: last.path, side: last.side, line: last.line, start };
}
var MAX_QUOTE = 12;
function quoteOf(lines) {
  const texts = lines.slice(0, MAX_QUOTE).map((row) => row.line.text);
  return [...texts, ...lines.length > MAX_QUOTE ? ["…"] : []].join(`
`);
}
function widest(rows) {
  return rows.reduce((longest, row) => row.kind === "line" ? Math.max(longest, row.text.length) : longest, 0);
}
function fileKey(path) {
  return `file:${path}`;
}

// src/review/layout.ts
function builtFrom(entry, columns, round) {
  const said = entry.comments.map((comment) => `${anchorKey(comment)} ${comment.start?.line} ${comment.about?.post} ${comment.body}`);
  const cards = said.length + entry.discussions.length > 0;
  return JSON.stringify([round, cards ? columns : null, said, entry.discussions.length]);
}
function staleFiles(files, built, columns, round) {
  return files.filter((entry) => built.get(entry.file.path)?.signature !== builtFrom(entry, columns, round));
}
function assemble(files, built) {
  return files.flatMap((entry) => [
    { kind: "file", key: fileKey(entry.file.path), entry },
    ...built.get(entry.file.path)?.rows ?? []
  ]);
}
function offsets(heights) {
  let top = 0;
  return heights.map((height) => {
    const start = top;
    top += height;
    return start;
  });
}
function fileStarts(rows, tops) {
  return rows.flatMap((row, index) => row.kind === "file" ? [{ path: row.entry.file.path, top: tops[index] ?? 0 }] : []);
}
function fileAt(starts, scrolled) {
  const [first] = starts;
  if (!first)
    return null;
  const over = starts.filter((start) => start.top <= scrolled);
  return (over[over.length - 1] ?? first).path;
}
function rowToReveal(tops, heights, head, scrolled, screen) {
  const top = tops[head] ?? 0;
  if (top <= scrolled)
    return head;
  const fits = (row) => (tops[row] ?? 0) + (heights[row] ?? 0) <= top + screen;
  let last = head;
  while (last + 1 < tops.length && fits(last + 1))
    last++;
  return last;
}

// src/review/tree.ts
function folder(path, name) {
  return { path, name, folders: new Map, files: [] };
}
function place3(root, entry) {
  const parts = entry.file.path.split("/");
  const name = parts.pop() ?? entry.file.path;
  let at = root;
  for (const part of parts) {
    const path = at.path ? `${at.path}/${part}` : part;
    const below = at.folders.get(part) ?? folder(path, part);
    at.folders.set(part, below);
    at = below;
  }
  at.files.push({ name, entry });
}
function joined(node) {
  const [only] = node.folders.values();
  if (!only || node.folders.size > 1 || node.files.length > 0)
    return node;
  return joined({ ...only, name: `${node.name}/${only.name}` });
}
function rowsOf(node, depth, folded) {
  const folders = [...node.folders.values()].map(joined).sort((a, b) => a.name.localeCompare(b.name));
  const below = folders.flatMap((child) => {
    const open = !folded.has(child.path);
    const head = { kind: "folder", path: child.path, name: child.name, depth, open };
    return open ? [head, ...rowsOf(child, depth + 1, folded)] : [head];
  });
  const files = node.files.map(({ name, entry }) => ({ kind: "file", name, depth, entry }));
  return [...below, ...files];
}
function fileTree(files, folded) {
  const root = folder("", "");
  for (const entry of files)
    place3(root, entry);
  return rowsOf(root, 0, folded);
}
function filterFiles(files, typed) {
  const word = typed.trim().toLowerCase();
  return files.filter((entry) => entry.file.path.toLowerCase().includes(word));
}
function inTreeOrder(files) {
  return fileTree(files, new Set).flatMap((row) => row.kind === "file" ? [row.entry] : []);
}

// src/review/store.ts
import { setShared as setShared4, shared as shared3 } from "herdr";
var REVIEWS = "projects.reviews";
function readDraft(key) {
  return parseDrafts(shared3(REVIEWS))[key] ?? NO_DRAFT;
}
function saveDraft(key, draft) {
  setShared4(REVIEWS, withDraft(parseDrafts(shared3(REVIEWS)), key, draft));
}

// src/review/view.ts
import { div as div6, svg as svg3 } from "gpui-kit";
import {
  h_flex as h_flex6,
  Input as Input2,
  Scrollbar,
  Textarea,
  v_flex as v_flex5,
  v_virtual_list
} from "gpui-base";
import { settings } from "herdr";

// src/review/syntax.ts
function words(list) {
  return new Set(list.split(" "));
}
var CONSTANTS = words("true false null undefined nil None True False NaN Infinity");
var BRACES = {
  lineComment: "//",
  blockStarts: ["/*", "*"],
  quotes: "\"'`",
  keywords: words("as async await break case catch class const continue default defer delete do dyn else enum export extends " + "finally fn for from func function go if impl implements import in instanceof interface let loop match mod mut " + "new of package private protected pub public readonly return static struct super switch this throw trait try " + "type typeof use var void where while yield"),
  constants: CONSTANTS
};
var HASHES = {
  lineComment: "#",
  blockStarts: [],
  quotes: `"'`,
  keywords: words("and as assert async await break case class continue def del do done elif else end esac except export fi " + "finally for from function global if import in inherit is lambda let local module not or pass raise rec " + "require return then try while with yield"),
  constants: CONSTANTS
};
var DATA = { lineComment: "", blockStarts: [], quotes: '"', keywords: new Set, constants: CONSTANTS };
var FAMILIES = [
  [BRACES, "ts tsx mts cts js jsx mjs cjs rs go swift java kt c h cc cpp hpp cs css scss"],
  [HASHES, "py sh bash zsh fish rb nix yaml yml toml"],
  [DATA, "json jsonc"]
];
var BY_EXTENSION = new Map(FAMILIES.flatMap(([grammar, extensions]) => extensions.split(" ").map((extension) => [extension, grammar])));
function grammarOf(path) {
  return BY_EXTENSION.get(path.slice(path.lastIndexOf(".") + 1).toLowerCase()) ?? null;
}
var LONGEST = 400;
var isSpace = (char) => char === " " || char === "\t";
var isDigit = (char) => char >= "0" && char <= "9";
var isUpper = (char) => char >= "A" && char <= "Z";
var startsWord = (char) => char >= "a" && char <= "z" || isUpper(char) || char === "_" || char === "$";
var inWord = (char) => startsWord(char) || isDigit(char);
function runEnd(line, from, keeps) {
  let end = from;
  while (end < line.length && keeps(line.charAt(end)))
    end++;
  return end;
}
function stringEnd(line, from) {
  const quote = line.charAt(from);
  let at = from + 1;
  while (at < line.length && line.charAt(at) !== quote)
    at += line.charAt(at) === "\\" ? 2 : 1;
  return Math.min(at + 1, line.length);
}
function startsComment(line, at, grammar) {
  if (grammar.lineComment === "" || !line.startsWith(grammar.lineComment, at))
    return false;
  return grammar.lineComment !== "#" || at === 0 || isSpace(line.charAt(at - 1));
}
function wordKind(word, next, grammar) {
  if (grammar.keywords.has(word))
    return "keyword";
  if (grammar.constants.has(word))
    return "constant";
  if (next === "(")
    return "function";
  return isUpper(word.charAt(0)) ? "type" : "plain";
}
function pieceAt(line, at, grammar) {
  const char = line.charAt(at);
  if (startsComment(line, at, grammar))
    return { kind: "comment", end: line.length };
  if (grammar.quotes.includes(char))
    return { kind: "string", end: stringEnd(line, at) };
  if (isDigit(char))
    return { kind: "number", end: runEnd(line, at, (next) => inWord(next) || next === ".") };
  if (!startsWord(char))
    return { kind: "plain", end: at + 1 };
  const end = runEnd(line, at, inWord);
  return { kind: wordKind(line.slice(at, end), line.charAt(end), grammar), end };
}
function tokens(line, grammar) {
  if (!grammar || line.length > LONGEST)
    return [{ kind: "plain", text: line }];
  const start = line.trimStart();
  if (grammar.blockStarts.some((open) => start.startsWith(open)))
    return [{ kind: "comment", text: line }];
  const pieces = [];
  let at = 0;
  while (at < line.length) {
    const from = at;
    at = runEnd(line, at, isSpace);
    if (at === line.length)
      break;
    const { kind, end } = pieceAt(line, at, grammar);
    const text = line.slice(from, end);
    const last = pieces[pieces.length - 1];
    if (last?.kind === kind)
      last.text += text;
    else
      pieces.push({ kind, text });
    at = end;
  }
  const rest = line.slice(pieces.reduce((length, piece) => length + piece.text.length, 0));
  const last = pieces[pieces.length - 1];
  if (last)
    last.text += rest;
  return last ? pieces : [{ kind: "plain", text: line }];
}
var JOINING = "-=<>!|&+*/:.#~_?%^\\";
function apart(text) {
  const pieces = [];
  let from = 0;
  for (let at = 1;at < text.length; at++) {
    if (!JOINING.includes(text.charAt(at)) || !JOINING.includes(text.charAt(at - 1)))
      continue;
    pieces.push(text.slice(from, at));
    from = at;
  }
  return [...pieces, text.slice(from)];
}

// src/review/view.ts
var FALLBACK_FONT = "JetBrains Mono";
var FALLBACK_SIZE = 13;
var FALLBACK_WEIGHT = 500;
var FONT_LINE = 1.32;
function numberOr(value, fallback) {
  return typeof value === "number" && value > 0 ? value : fallback;
}
function readType() {
  const all = settings();
  const size = numberOr(all.font_size, FALLBACK_SIZE);
  return {
    family: text(all.font_family) ?? FALLBACK_FONT,
    size,
    weight: numberOr(all.font_weight, FALLBACK_WEIGHT),
    ligatures: all.font_ligatures === true,
    row: Math.round(2 * size * FONT_LINE * numberOr(all.terminal_line_height, 1)) / 2,
    char: size * 0.64
  };
}
function readZoom() {
  const { zoom } = settings();
  return typeof zoom === "number" && zoom > 0 ? zoom : 1;
}
var NUMBER_DIGITS = 4;
var MARK2 = 3;
var COMMENT_GAP = 4;
var COMMENT_PAD = { x: 10, y: 6 };
var DIFF_END = 16;
function numbers(type) {
  return Math.ceil((NUMBER_DIGITS + 1) * type.char);
}
function gutter(type) {
  return MARK2 + numbers(type) + Math.ceil(2 * type.char);
}
function commentColumns(width, type) {
  const room = width - gutter(type) - 2 * COMMENT_PAD.x - DIFF_END;
  return Math.max(24, Math.floor(room / type.char));
}
var FILE_GAP = 10;
var FILE_HEAD = 32;
function rowHeight(row, type) {
  if (row.kind === "file")
    return FILE_GAP + FILE_HEAD;
  return row.kind === "card" ? row.lines.length * type.row + 2 * (COMMENT_GAP + COMMENT_PAD.y) : type.row;
}
function rowHeights(rows, type) {
  return rows.map((row) => rowHeight(row, type));
}
function tint(colors, line) {
  if (line.sign === "+")
    return `${colors.ansi2}1c`;
  return line.sign === "-" ? `${colors.ansi1}1c` : null;
}
function lineNumber(colors, type, number) {
  return div6().w(numbers(type)).flex_none().text_right().text_color(colors.dim).child(number === null ? "" : String(number));
}
function lineRow(colors, type, row, active) {
  const { line } = row;
  const face = h_flex6().w_full().h(type.row).flex_none().gap(Math.ceil(2 * type.char)).cursor_pointer().hover((style) => style.bg(colors.hover)).child(h_flex6().h_full().flex_none().child(optional(div6().w(MARK2).h_full().flex_none(), edgeOf(colors, row, active), (el, color) => el.bg(color))).child(lineNumber(colors, type, line.now ?? line.old))).child(codeText(colors, type, row));
  if (active)
    return face.bg(`${colors.accent}26`);
  return optional(face, tint(colors, line), (el, color) => el.bg(color));
}
var SYNTAX = {
  plain: null,
  keyword: "ansi5",
  string: "ansi2",
  comment: "dim",
  number: "ansi1",
  function: "ansi4",
  type: "ansi3",
  constant: "ansi6"
};
function codeText(colors, type, row) {
  const pieces = tokens(row.text, grammarOf(row.anchor.path)).flatMap((piece) => {
    const color = SYNTAX[piece.kind];
    return (type.ligatures ? [piece.text] : apart(piece.text)).map((part) => {
      const span = div6().flex_none().whitespace_nowrap().child(part || " ");
      return color ? span.text_color(colors[color]) : span;
    });
  });
  return h_flex6().flex_1().min_w(0).children(pieces);
}
function edgeOf(colors, row, active) {
  if (row.commented || active)
    return colors.accent;
  if (row.discussed)
    return colors.muted;
  if (row.line.sign === "+")
    return colors.ansi2;
  return row.line.sign === "-" ? colors.ansi1 : null;
}
function foldRow(colors, type, text) {
  return h_flex6().w_full().h(type.row).flex_none().pl(gutter(type)).items_center().bg(colors.raised).text_size(type.size - 1).text_color(colors.dim).child(text);
}
function edge(colors, card) {
  if (card.stale)
    return colors.blocked;
  return card.from === "github" ? colors.muted : colors.accent;
}
function cardRow(colors, type, row, columns) {
  return div6().w_full().h(rowHeight(row, type)).flex_none().pl(gutter(type)).py(COMMENT_GAP).cursor_pointer().child(v_flex5().w(Math.ceil(columns * type.char) + 2 * COMMENT_PAD.x).h_full().px(COMMENT_PAD.x).py(COMMENT_PAD.y).rounded(6).bg(colors.raised).border_l(2).border_color(edge(colors, row)).text_color(colors.foreground).children(row.lines.map((line) => div6().h(type.row).flex_none().whitespace_nowrap().when(line.head, (el) => el.text_color(colors.muted)).child(line.text || " "))));
}
function plainRow(colors, type, text) {
  return div6().w_full().h(type.row).flex_none().px(12).truncate().text_color(colors.dim).child(text);
}
function diffPane(colors, props) {
  const { rows, type } = props;
  const draw = (row) => {
    if (row.kind === "line")
      return lineRow(colors, type, row, props.active.has(row.key));
    if (row.kind === "card")
      return cardRow(colors, type, row, props.columns);
    if (row.kind === "file")
      return cardHead(colors, type, row.entry.file);
    return row.kind === "hunk" ? foldRow(colors, type, row.text) : plainRow(colors, type, row.text);
  };
  const list = v_virtual_list("review-diff", rows.length, props.heights, (index) => rows[index]?.key ?? String(index), (range) => rows.slice(range.start, range.end).map(draw)).track_scroll(props.scroll).on_item_click(props.onPick).size_full();
  return div6().id("review-diff-box").flex_1().min_h(0).relative().font_family(type.family).text_size(type.size).font_weight(type.weight).on_size_change((size, cx) => props.onWidth(size.width / readZoom(), cx)).on_mouse_down("left", (event) => props.onPress(event.modifiers.shift)).on_scroll_wheel((_event, cx) => props.onScroll(cx)).child(div6().id("review-diff-x").size_full().overflow_x_scrollbar().child(div6().w_full().min_w(Math.ceil(props.widest * type.char) + gutter(type) + DIFF_END).h_full().child(list))).child(Scrollbar.vertical("review-diff").viewport_from_layout().absolute().inset_0()).children(props.shown ? [stickyHead(colors, type, props.shown)] : []);
}
function stickyHead(colors, type, file) {
  return div6().absolute().top(0).left(0).right(0).bg(colors.popover).child(cardHead(colors, type, file));
}
function counts(colors, added, removed) {
  const count = (amount, sign, color) => div6().flex_none().text_size(11).text_color(color).child(`${sign}${amount}`);
  return [
    ...added > 0 ? [count(added, "+", colors.ansi2)] : [],
    ...removed > 0 ? [count(removed, "−", colors.ansi1)] : []
  ];
}
function badge2(colors, amount, own) {
  const face = div6().px(5).h(16).flex().flex_none().items_center().rounded(8).text_size(10.5).font_semibold();
  if (own)
    return face.bg(colors.accent).text_color(colors.background).child(String(amount));
  return face.border_1().border_color(colors.input).text_color(colors.muted).child(String(amount));
}
var TREE_ROW = 24;
function inset(depth) {
  return 8 + depth * 14;
}
function folderRow(colors, row, onFold) {
  return h_flex6().id(`review-folder-${row.path}`).h(TREE_ROW).flex_none().pl(inset(row.depth)).pr(8).gap(6).items_center().rounded(6).cursor_pointer().text_color(colors.muted).hover((style) => style.bg(colors.hover)).on_click((_event, cx) => onFold(cx)).child(svg3(chromeIcon("folder")).size(12).flex_none()).child(div6().min_w(0).truncate().child(row.name)).child(svg3(chromeIcon(row.open ? "chevron-down" : "chevron-right")).size(10).flex_none().text_color(colors.dim));
}
function nameColor(colors, entry) {
  if (entry.gone)
    return colors.blocked;
  if (entry.file.change === "added")
    return colors.ansi2;
  return entry.file.change === "deleted" ? colors.ansi1 : colors.foreground;
}
function fileRow(colors, row, open, onOpen) {
  const { entry } = row;
  const { file } = entry;
  return h_flex6().id(`review-file-${file.path}`).h(TREE_ROW).flex_none().pl(inset(row.depth) + 18).pr(8).gap(8).items_center().rounded(6).cursor_pointer().when(open, (el) => el.bg(colors.selected)).hover((style) => style.bg(colors.hover)).on_click((_event, cx) => onOpen(cx)).child(div6().flex_1().min_w(0).truncate().text_color(nameColor(colors, entry)).child(row.name)).when(entry.discussions.length > 0, (el) => el.child(badge2(colors, entry.discussions.length, false))).when(entry.comments.length > 0, (el) => el.child(badge2(colors, entry.comments.length, true))).children(counts(colors, file.added, file.removed));
}
function fileList(colors, props) {
  const draw = (row) => row.kind === "folder" ? folderRow(colors, row, (cx) => props.onFold(row.path, cx)) : fileRow(colors, row, row.entry.file.path === props.open, (cx) => props.onOpen(row.entry.file.path, cx));
  const filter = Input2.new(props.filter).h(26).flex_none().mx(6).mt(6).px(8).rounded(6).border_1().border_color(colors.border).text_size(12).text_color(colors.foreground);
  const tree = v_flex5().id("review-files").flex_1().min_h(0).p(6).overflow_y_scrollbar().children(props.rows.map(draw)).when(props.rows.length === 0, (el) => el.child(div6().p(8).text_size(12).text_color(colors.muted).child(props.empty)));
  return v_flex5().w(300).h_full().flex_none().border_r(1).border_color(colors.border).text_size(12).child(filter).child(tree);
}
function pullTab(colors, pull, shown, onPick) {
  return h_flex6().id(`review-pull-${pull.number}`).h(24).max_w(340).min_w(0).px(8).gap(6).items_center().rounded(6).text_size(11.5).cursor_pointer().when(shown, (el) => el.bg(colors.selected)).text_color(shown ? colors.foreground : colors.muted).hover((style) => style.bg(colors.hover)).on_click((_event, cx) => onPick(cx)).child(div6().flex_none().font_medium().child(`#${pull.number}`)).child(div6().min_w(0).truncate().child(pull.title)).child(div6().flex_none().text_color(colors.dim).child(stageLabel(pull.stage)));
}
function pullStrip(colors, props) {
  if (props.choices.length < 2)
    return [];
  const tabs = props.choices.map((pull) => pullTab(colors, pull, pull.url === props.shown?.url, (cx) => props.onPick(pull, cx)));
  return [
    h_flex6().h(34).flex_none().px(10).gap(4).items_center().border_b(1).border_color(colors.border).children(tabs)
  ];
}
function reviewHead(colors, props) {
  const added = props.files.reduce((sum, file) => sum + file.added, 0);
  const removed = props.files.reduce((sum, file) => sum + file.removed, 0);
  const bar = h_flex6().h(44).flex_none().px(14).gap(8).items_center().border_b(1).border_color(colors.border).text_size(13).child(svg3(chromeIcon("git-compare")).size(14).flex_none().text_color(colors.muted)).child(div6().flex_none().font_semibold().child("Review")).child(div6().min_w(0).truncate().text_color(colors.muted).child(props.title));
  return optional(bar, props.range, (el, range) => el.child(div6().flex_none().px(6).py(1).rounded(4).border_1().border_color(colors.border).text_size(11).text_color(colors.muted).child(range))).children(counts(colors, added, removed)).child(div6().flex_1()).child(props.loading ? svg3(chromeIcon("spinner")).size(13).flex_none().text_color(colors.working).spin(900) : iconButton(colors, {
    id: "review-refresh",
    icon: "mods/projects/refresh.svg",
    tip: "Read the diff again",
    onClick: props.onRefresh
  })).child(iconButton(colors, { id: "review-close", icon: chromeIcon("x"), tip: "Close", onClick: props.onClose }));
}
function cardHead(colors, type, file) {
  const cut = file.path.lastIndexOf("/");
  const bar = h_flex6().w_full().h(FILE_HEAD).px(12).gap(8).items_center().bg(colors.raised).border_t(1).border_b(1).border_color(colors.border).text_size(type.size - 1).text_color(colors.foreground).child(div6().flex_none().child(file.path.slice(cut + 1))).child(div6().min_w(0).truncate().text_color(colors.muted).child(file.path.slice(0, cut + 1)));
  const head = optional(bar, file.from, (el, from) => el.child(div6().min_w(0).truncate().text_color(colors.dim).child(`from ${from}`))).children(counts(colors, file.added, file.removed));
  return div6().w_full().h(FILE_GAP + FILE_HEAD).flex_none().pt(FILE_GAP).child(head);
}
function composer(colors, props) {
  return v_flex5().id("review-composer").flex_none().p(10).gap(8).border_t(1).border_color(colors.border).bg(colors.chrome).child(h_flex6().gap(8).items_center().text_size(11.5).child(div6().flex_none().text_color(colors.muted).child(props.where)).child(div6().flex_1().min_w(0).truncate().font_family(props.type.family).text_color(colors.dim).child(props.code.trim()))).child(Textarea.new(props.field).h(96).p(8).rounded(8).border_1().border_color(colors.input).bg(colors.background).text_size(12.8).text_color(colors.foreground)).child(h_flex6().gap(8).justify_end().children(props.buttons.map((button) => textButton(colors, button))));
}
function reviewFoot(colors, props) {
  const bar = h_flex6().flex_none().p(10).gap(10).items_center().border_t(1).border_color(colors.border).child(Input2.new(props.note).flex_1().min_w(0).h(32).px(10).rounded(8).border_1().border_color(colors.input).bg(colors.background).text_size(12.5).text_color(colors.foreground));
  return optional(bar, props.error, (el, error) => el.child(div6().max_w(520).text_size(11.5).text_color(colors.blocked).child(error))).child(textButton(colors, props.send));
}

// src/parts/review.ts
var SHOW_EVERY = 150;
var FIRST_WIDTH = 900;
var ADDRESS = "Address this comment.";
function linesWord(span) {
  if (span.start)
    return `Lines ${linesOf(span)}`;
  return span.side === "old" ? `Line ${span.line}, which the branch removes` : `Line ${span.line}`;
}
function whereOf(target) {
  const { path } = target.anchor;
  const lines = `${path.slice(path.lastIndexOf("/") + 1)} · ${linesWord(target.anchor)}`;
  return target.about ? `${lines} · in answer to @${target.about.author} on GitHub` : lines;
}

class ReviewDialog {
  overlay;
  thread;
  field = TextareaState.new({
    placeholder: "Write a comment. Shift-click another line to comment on all the lines between.",
    rows: 4
  });
  note;
  filter = InputState3.new({ placeholder: "Filter files…" });
  scroll = VirtualListScrollHandle.new();
  handle;
  subject = null;
  diff = null;
  discussions = [];
  asked = false;
  round = 0;
  loading = false;
  error = null;
  sending = false;
  sent = false;
  open = null;
  folded = new Set;
  target = null;
  shift = false;
  width = FIRST_WIDTH;
  built = new Map;
  version = 0;
  building = false;
  drawn = null;
  constructor(overlay, thread, cx) {
    this.overlay = overlay;
    this.thread = thread;
    this.handle = cx.focus_handle();
    this.note = InputState3.new({ placeholder: "A word on the whole branch (optional)" });
    this.note.on("change", (_event, change) => change.notify());
    this.filter.on("change", (_event, change) => change.notify());
    this.note.on("blur", () => this.keepNote());
    this.field.on("submit", (event, submit) => {
      if (event.secondary)
        this.keepComment(submit);
    });
  }
  render(cx) {
    const colors = readTheme();
    const type = readType();
    const thread = this.find();
    if (thread && !this.asked)
      this.load(cx);
    const draft = readDraft(this.key());
    const files = reviewFiles(this.diff?.files ?? [], draft.comments, this.discussions);
    const ordered = inTreeOrder(files);
    const columns = commentColumns(this.width, type);
    this.build(ordered, columns, cx);
    const drawn = this.drawnOf(ordered, columns, type);
    const open = files.some((entry) => entry.file.path === this.open) ? this.open : fileAt(drawn.starts, 0);
    const branch = thread?.checkout?.branch;
    const tip = branch && (reviewRange(this.subject, branch).tip ?? branch);
    const range = tip && this.diff ? `${tip} → ${this.diff.base}` : null;
    return v_flex6().id("review").size_full().bg(colors.popover).text_color(colors.foreground).track_focus(this.handle).child(reviewHead(colors, {
      title: thread?.title ?? "This thread has ended.",
      range,
      files: this.diff?.files ?? [],
      loading: this.loading,
      onRefresh: (cx) => this.load(cx),
      onClose: () => closeOverlay4(this.overlay)
    })).children(pullStrip(colors, {
      choices: openPulls(thread?.pulls ?? []),
      shown: this.subject,
      onPick: (pull, cx) => this.turn(pull, cx)
    })).child(h_flex7().flex_1().min_h(0).items_start().child(fileList(colors, {
      rows: fileTree(filterFiles(files, this.filter.value()), this.folded),
      filter: this.filter,
      onFold: (path, cx) => this.fold(path, cx),
      open,
      empty: this.emptyText(),
      onOpen: (path, cx) => this.show(drawn, path, cx)
    })).child(this.diffSide(colors, type, drawn, files.find((entry) => entry.file.path === open)?.file ?? null))).child(reviewFoot(colors, {
      note: this.note,
      error: this.diff ? this.error : null,
      send: this.sendButton(thread, draft)
    }));
  }
  close() {
    if (this.sent)
      return;
    this.keepTyped();
    this.keepNote();
  }
  find() {
    const { snapshot, projects } = readScene();
    return threadAt(snapshot, projects, this.thread);
  }
  key() {
    return draftKey(this.thread, this.subject);
  }
  turnTo(pull) {
    this.keepTyped();
    this.keepNote();
    this.subject = pull;
    this.diff = null;
    this.discussions = [];
    this.open = null;
    this.target = null;
    this.built.clear();
    this.version++;
    this.scroll.scroll_to_item(0);
    this.field.set_value("");
    this.note.set_value(readDraft(this.key()).note);
  }
  turn(pull, cx) {
    if (pull.url === this.subject?.url)
      return;
    this.turnTo(pull);
    this.load(cx);
  }
  emptyText() {
    if (this.error && !this.diff)
      return this.error;
    if (!this.diff)
      return this.loading ? "Reading the branch…" : "No branch to review.";
    return `Nothing changed against ${this.diff.base}.`;
  }
  diffSide(colors, type, drawn, shown) {
    const side = v_flex6().flex_1().min_w(0).h_full();
    if (drawn.rows.length === 0)
      return side;
    const { target } = this;
    const pane = side.child(diffPane(colors, {
      rows: drawn.rows,
      heights: drawn.heights,
      widest: drawn.widest,
      type,
      columns: drawn.columns,
      scroll: this.scroll,
      onScroll: (cx) => this.follow(drawn, cx),
      shown,
      active: new Set(target ? spanRows(this.rowsIn(target.anchor.path), target.anchor).map((row) => row.key) : []),
      onPress: (shift) => {
        this.shift = shift;
      },
      onPick: (key, cx) => this.pick(drawn.rows, key, cx),
      onWidth: (width, cx) => this.resize(width, cx)
    }));
    if (!target)
      return pane;
    return pane.child(composer(colors, {
      where: whereOf(target),
      code: target.code.split(`
`)[0] ?? "",
      type,
      field: this.field,
      buttons: this.composerButtons(target)
    }));
  }
  composerButtons(target) {
    const remove = {
      id: "review-delete",
      label: "Delete",
      onClick: (cx) => this.removeComment(target.anchor, cx)
    };
    const address = { id: "review-address", label: "Ask to address it", onClick: (cx) => this.address(cx) };
    const cancel = { id: "review-cancel", label: "Cancel", onClick: (cx) => this.closeComposer(cx) };
    const keep = (label, post, primary) => ({
      id: `review-keep-${post}`,
      label,
      primary,
      onClick: (cx) => this.keepComment(cx, post)
    });
    const first = target.written ? [remove] : [];
    if (target.about) {
      const ask = target.written ? [] : [address];
      return [
        ...ask,
        ...first,
        cancel,
        keep("To the thread only", "none", false),
        keep("Reply on GitHub", "due", true)
      ];
    }
    return [...first, cancel, keep(target.written ? "Save" : "Comment", "none", true)];
  }
  sendLabel(draft) {
    const comments = draft.comments.length;
    const replies = duePosts(draft).length;
    if (this.sending)
      return "Sending…";
    if (comments === 0)
      return "Send review";
    return replies > 0 ? `Send review · ${comments} · ${replies} to GitHub` : `Send review · ${comments}`;
  }
  sendButton(thread, draft) {
    const empty = draft.comments.length === 0 && this.note.value().trim() === "";
    return {
      id: "review-send",
      label: this.sendLabel(draft),
      primary: true,
      disabled: empty || this.sending || !thread,
      onClick: (cx) => this.send(cx)
    };
  }
  rowsIn(path) {
    return this.built.get(path)?.rows ?? [];
  }
  build(files, columns, cx) {
    const { round } = this;
    const stale = this.building ? [] : staleFiles(files, this.built, columns, round);
    if (stale.length === 0)
      return;
    this.building = true;
    cx.spawn(async (task) => {
      let shown = Date.now();
      try {
        for (const entry of stale) {
          if (round !== this.round)
            break;
          this.built.set(entry.file.path, {
            signature: builtFrom(entry, columns, round),
            rows: fileRows(entry, columns)
          });
          this.version++;
          if (Date.now() - shown >= SHOW_EVERY) {
            shown = Date.now();
            task.notify();
          }
          await task.sleep(1);
        }
      } finally {
        this.building = false;
        task.notify();
      }
    });
  }
  drawnOf(files, columns, type) {
    const signature = `${this.version} ${files.length} ${type.size} ${columns}`;
    if (this.drawn?.signature === signature)
      return this.drawn;
    const rows = assemble(files, this.built);
    const heights = rowHeights(rows, type);
    const tops = offsets(heights);
    this.drawn = { signature, rows, columns, heights, tops, starts: fileStarts(rows, tops), widest: widest(rows) };
    return this.drawn;
  }
  follow(drawn, cx) {
    const path = fileAt(drawn.starts, this.scroll.offset().y + (drawn.heights[0] ?? 0));
    if (path === this.open)
      return;
    this.open = path;
    cx.notify();
  }
  load(cx) {
    const thread = this.find();
    if (!thread)
      return;
    if (this.subject === null)
      this.turnTo(leadPull(openPulls(thread.pulls)));
    const { subject } = this;
    const range = reviewRange(subject, thread.checkout?.branch ?? "");
    const round = ++this.round;
    const latest = () => this.round === round;
    this.asked = true;
    this.loading = true;
    this.error = null;
    cx.spawn(async (task) => {
      const show = () => task.notify();
      await Promise.all([
        this.read(readBranchDiff(thread, range), (diff) => this.diff = diff, latest).then(show),
        this.read(readDiscussions(thread, subject), (discussions) => this.discussions = discussions, latest).then(show)
      ]);
      if (latest())
        this.loading = false;
      task.notify();
    });
  }
  async read(reading, keep, latest) {
    try {
      const value = await reading;
      if (latest())
        keep(value);
    } catch (error) {
      if (latest())
        this.error = messageOf(error);
    }
  }
  show(drawn, path, cx) {
    const head = drawn.rows.findIndex((row) => row.key === fileKey(path));
    if (head < 0)
      return;
    this.open = path;
    const scrolled = this.scroll.offset().y;
    const screen = this.scroll.viewport_size().height;
    this.scroll.scroll_to_item(rowToReveal(drawn.tops, drawn.heights, head, scrolled, screen), "top");
    cx.notify();
  }
  resize(width, cx) {
    if (Math.abs(width - this.width) < 1)
      return;
    this.width = width;
    cx.notify();
  }
  pick(rows, key, cx) {
    const row = rows.find((candidate) => candidate.key === key);
    if (row?.kind !== "line" && row?.kind !== "card")
      return;
    const own = this.rowsIn(row.anchor.path);
    if (this.shift && row.kind === "line" && this.extend(own, row.anchor, cx))
      return;
    this.keepTyped();
    const written = commentAt(readDraft(this.key()), row.anchor);
    const line = own.find((candidate) => candidate.key === lineKey(row.anchor));
    this.target = {
      anchor: written ?? { path: row.anchor.path, side: row.anchor.side, line: row.anchor.line, start: null },
      pivot: row.anchor,
      code: written?.code ?? (line?.kind === "line" ? line.line.text : ""),
      written: Boolean(written),
      about: this.aboutAt(row.anchor)
    };
    this.field.set_value(written?.body ?? "");
    this.field.focus();
    cx.notify();
  }
  extend(rows, anchor, cx) {
    const { target } = this;
    if (!target || target.pivot.path !== anchor.path)
      return false;
    const span = spanBetween(rows, target.pivot, anchor);
    this.target = { ...target, anchor: span, code: quoteOf(spanRows(rows, span)), about: this.aboutAt(span) };
    if (target.written && anchorKey(span) !== anchorKey(target.anchor))
      this.moveComment(target.anchor, this.target);
    this.field.focus();
    cx.notify();
    return true;
  }
  aboutAt(anchor) {
    const [discussion] = discussionsAt(this.discussions, anchor);
    return discussion ? aboutOf(discussion) : null;
  }
  moveComment(from, to) {
    const draft = readDraft(this.key());
    const written = commentAt(draft, from);
    if (!written)
      return;
    saveDraft(this.key(), withComment(withoutComment(draft, from), to.anchor, { ...written, code: to.code }));
  }
  fold(path, cx) {
    if (!this.folded.delete(path))
      this.folded.add(path);
    cx.notify();
  }
  keepTyped(chosen) {
    const { target } = this;
    if (!target || this.field.value().trim() === "")
      return;
    const draft = readDraft(this.key());
    const post = chosen ?? commentAt(draft, target.anchor)?.about?.post ?? "none";
    const about = target.about && { ...target.about, post };
    saveDraft(this.key(), withComment(draft, target.anchor, { code: target.code, body: this.field.value(), about }));
  }
  keepNote() {
    if (this.sent || !this.asked)
      return;
    const draft = readDraft(this.key());
    if (draft.note === this.note.value())
      return;
    saveDraft(this.key(), withNote(draft, this.note.value()));
  }
  keepComment(cx, post) {
    this.keepTyped(post);
    this.closeComposer(cx);
  }
  address(cx) {
    this.field.set_value(ADDRESS);
    this.keepComment(cx, "none");
  }
  async postReplies(thread, key, pull) {
    for (const comment of duePosts(readDraft(key))) {
      if (!comment.about || !pull)
        continue;
      await postReply(thread, pull, comment.about, comment.body);
      saveDraft(key, withPosted(readDraft(key), comment));
    }
  }
  removeComment(anchor, cx) {
    saveDraft(this.key(), withoutComment(readDraft(this.key()), anchor));
    this.closeComposer(cx);
  }
  closeComposer(cx) {
    this.target = null;
    this.field.set_value("");
    this.handle.focus();
    cx.notify();
  }
  send(cx) {
    if (this.sending)
      return;
    this.keepTyped();
    this.keepNote();
    const thread = this.find();
    const key = this.key();
    const { subject } = this;
    if (!thread || isEmpty(readDraft(key)))
      return;
    const paths = (this.diff?.files ?? []).map((file) => file.path);
    this.sending = true;
    this.error = null;
    cx.spawn(async (task) => {
      const fail = (message) => {
        this.error = message;
        this.sending = false;
        task.notify();
      };
      try {
        await this.postReplies(thread, key, subject);
      } catch (error) {
        return fail(`${messageOf(error)}. Nothing went to the thread: send again, or keep that answer for the thread only.`);
      }
      try {
        await sendToThread(this.thread, reviewMessage(readDraft(key), paths, subject));
      } catch (error) {
        return fail(messageOf(error));
      }
      this.sent = true;
      saveDraft(key, NO_DRAFT);
      closeOverlay4(this.overlay);
    });
    cx.notify();
  }
}

// src/parts/thread-head.ts
import { div as div7 } from "gpui-kit";
import { h_flex as h_flex8 } from "gpui-base";
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
  const pull = leadPull(thread.pulls);
  const link = pull ? [
    iconButton(colors, {
      id: "pull-request",
      icon: chromeIcon("git-branch"),
      tip: `Open pull request #${pull.number}`,
      onClick: () => openLink(pull.url)
    })
  ] : [];
  const review = iconButton(colors, {
    id: "review",
    icon: chromeIcon("git-compare"),
    tip: "Review its branch",
    onClick: () => openReview(thread.key)
  });
  return [...thread.checkout ? [review] : [], ...link, ...canRename(thread) ? [rename] : [], resolve];
}
var threadHead = {
  render() {
    const colors = readTheme();
    const panel = readPanel();
    const { snapshot, projects } = readScene();
    const thread = threadAt(snapshot, projects, panel.thread);
    const bar = h_flex8().size_full().px(8).gap(6).items_center().bg(colors.chrome).text_size(12.5).child(iconButton(colors, { id: "back", icon: chromeIcon("chevron-left"), tip: "All threads", onClick: showThreadList })).child(statusMark(colors, thread?.status ?? null)).child(div7().flex_1().min_w(0).truncate().text_color(thread ? colors.foreground : colors.dim).child(thread?.title ?? "This thread has ended."));
    return optional(bar, thread, (el, open) => el.child(div7().flex_none().text_size(11).text_color(colors.muted).child(threadState(open, Date.now()))).children([...drawerButtons(colors, panel.drawer), ...controls(colors, open)]));
  }
};

// src/parts/thread-panel.ts
import { div as div8 } from "gpui-kit";
import { v_flex as v_flex7 } from "gpui-base";
import { setAgentOrder } from "herdr";
var AGE_REFRESH = 60000;
function emptyText2(shown) {
  if (!shown)
    return "Pick a project on the left.";
  if (leadOf(shown)?.status === "blocked")
    return "No thread yet. The orchestrator waits on you, in the middle.";
  return "No thread yet. Ask the orchestrator for some work.";
}

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
    return v_flex7().id("threads").size_full().min_h(0).px(8).pb(8).bg(colors.chrome).text_size(13).overflow_y_scrollbar().children(groups.flatMap((group) => this.group(colors, group, now))).when(threads.length === 0, (el) => el.child(div8().px(8).pt(12).text_size(12).text_color(colors.muted).child(emptyText2(shown))));
  }
  group(colors, group, now) {
    const open = !this.folded.has(group.id);
    const head = heading(colors, {
      id: group.id,
      label: group.label,
      count: group.threads.length,
      ...group.id === "waiting" && { tone: colors.blocked },
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
import { h_flex as h_flex9 } from "gpui-base";
import { window as window3 } from "herdr";
var WINDOW_BUTTONS = 76;
var EDGE = 12;
var topBar = {
  render() {
    const colors = readTheme();
    const frame = window3();
    const hasWindowButtons = frame?.platform === "macos" && !frame.fullscreen;
    return h_flex9().size_full().pl(hasWindowButtons ? WINDOW_BUTTONS : EDGE).pr(EDGE).items_center().justify_end().bg(colors.chrome).child(iconButton(colors, {
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
  return {
    part: text(given.part) ?? MAIN,
    overlay: text(given.overlay),
    project: text(given.project),
    thread: text(given.thread)
  };
}
function need(value, what) {
  if (value === null)
    throw new Error(`the projects mod needs ${what} for this part`);
  return value;
}
var PARTS = {
  top: () => topBar,
  projects: (_given, cx) => {
    startBackground(cx);
    return new ProjectList;
  },
  tabs: () => panelTabs,
  threads: (_given, cx) => new ThreadPanel(cx),
  "thread-head": () => threadHead,
  "new-project": (given, cx) => new NewProjectDialog(need(given.overlay, "its overlay"), cx),
  "rename-project": (given, cx) => new RenameProjectDialog(need(given.overlay, "its overlay"), need(given.project, "a project"), cx),
  "project-menu": (given) => new ProjectMenu(need(given.overlay, "its overlay"), need(given.project, "a project")),
  review: (given, cx) => new ReviewDialog(need(given.overlay, "its overlay"), need(given.thread, "a thread"), cx)
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
    return this.part?.render(cx) ?? div9();
  }
  close() {
    this.part?.close?.();
  }
}
export {
  Projects as default
};
