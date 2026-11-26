import { isRecord, text } from "./parse";

const STAGE_WORDS = {
  draft: "draft",
  review: "in review",
  changes: "changes requested",
  landing: "landing",
  merged: "merged",
  closed: "closed",
} as const;

/** Where a pull request stands, as the person sees it. */
export type PullStage = keyof typeof STAGE_WORDS;

export interface Pull {
  readonly number: number;
  readonly url: string;
  readonly stage: PullStage;
  /** The branch it merges into. */
  readonly base: string;
  /** Its own branch. */
  readonly head: string;
}

/** What a pull request is asked for by: a URL its thread declared, or the branch in a thread's folder. */
export type PullRef =
  { readonly kind: "declared"; readonly url: string } | { readonly kind: "branch"; readonly terminal: string };

/** The pull requests as last read, by `refKey`. A cache the mod can build again. */
export type Pulls = Readonly<Record<string, Pull>>;

/** A thread's pull requests, the lowest of a stack first. */
export type Stack = readonly Pull[];

/** The repository of a pull request, and its number there. */
export interface PullPlace {
  readonly host: string;
  readonly owner: string;
  readonly name: string;
  readonly number: number;
}

/** The fields `gh pr view --json` is asked for. */
export const PULL_FIELDS = "number,url,state,isDraft,reviewDecision,autoMergeRequest,baseRefName,headRefName";

/** How many pull requests a thread declares at most. `report.sh` holds the same number. */
export const MAX_DECLARED = 8;

/** A pull request's URL as `gh pr create` prints it. `report.sh` writes this form into the label. */
const PULL_URL = /^https:\/\/([^/\s]+)\/([^/\s]+)\/([^/\s]+)\/pull\/(\d+)$/;

function isStage(word: unknown): word is PullStage {
  return typeof word === "string" && word in STAGE_WORDS;
}

/**
 * A review that asks for changes, or that is still required, comes before a
 * merge that is set to happen by itself: someone must act first. Landing is
 * approved, or set to merge with no review asked: nothing is left to do.
 */
function stageOf(raw: Readonly<Record<string, unknown>>): PullStage {
  if (raw.state === "MERGED") return "merged";
  if (raw.state === "CLOSED") return "closed";
  if (raw.isDraft === true) return "draft";
  if (raw.reviewDecision === "CHANGES_REQUESTED") return "changes";
  if (raw.reviewDecision === "APPROVED") return "landing";
  if (raw.reviewDecision === "REVIEW_REQUIRED") return "review";
  return isRecord(raw.autoMergeRequest) ? "landing" : "review";
}

/**
 * Reads what `gh pr view --json` prints, or a stored pull request; null for
 * anything else. One stored without its branches is not one: it is read again.
 */
export function parsePull(value: unknown): Pull | null {
  if (!isRecord(value) || typeof value.number !== "number" || typeof value.url !== "string") return null;
  const base = text(value.base) ?? text(value.baseRefName);
  const head = text(value.head) ?? text(value.headRefName);
  if (!base || !head) return null;
  return {
    number: value.number,
    url: value.url,
    stage: isStage(value.stage) ? value.stage : stageOf(value),
    base,
    head,
  };
}

/** Reads the stored pull requests; anything that is not one is dropped. */
export function parsePulls(value: unknown): Pulls {
  if (!isRecord(value)) return {};
  const pulls = Object.entries(value).map(([key, pull]) => [key, parsePull(pull)] as const);
  return Object.fromEntries(pulls.filter((entry): entry is readonly [string, Pull] => entry[1] !== null));
}

/** Reads the `pulls` label of a thread's terminal: the URLs it declared. A word that is no such URL is dropped. */
export function parseDeclared(label: unknown): string[] {
  if (typeof label !== "string") return [];
  const urls = label.split(/\s+/).filter((word) => PULL_URL.test(word));
  return [...new Set(urls)].slice(0, MAX_DECLARED);
}

/** Where a pull request is on its host, read from its URL; null for a URL of another form. */
export function placeOf(url: string): PullPlace | null {
  const [, host, owner, name, number] = PULL_URL.exec(url) ?? [];
  return host && owner && name && number ? { host, owner, name, number: Number(number) } : null;
}

/**
 * The pull requests to ask for on behalf of a thread: the ones it declared,
 * else the one of the branch in its folder. A declared list wins over the
 * guess: one the thread dropped must not come back while its branch is
 * checked out.
 */
export function refsOf(terminal: string, declared: readonly string[]): PullRef[] {
  if (declared.length === 0) return [{ kind: "branch", terminal }];
  return declared.map((url) => ({ kind: "declared", url }));
}

/** The key of a reference in the cache: the URL, or the terminal's address for its branch. */
export function refKey(ref: PullRef): string {
  return ref.kind === "declared" ? ref.url : ref.terminal;
}

/**
 * How many pull requests of the set lie under one: each step goes to the one
 * whose branch it merges into. The count stops at the set's size, against a
 * set whose branches point at each other.
 */
function depth(pull: Pull, pulls: readonly Pull[]): number {
  let steps = 0;
  let below = pulls.find((other) => other.head === pull.base);
  while (below && steps < pulls.length) {
    steps++;
    const { base } = below;
    below = pulls.find((other) => other.head === base);
  }
  return steps;
}

/**
 * Puts pull requests in the order of their stack, the lowest first. Those at
 * one height (two on one base, or a stack whose lower part was merged and
 * that now targets the main branch) go by number, the order they were made in.
 */
export function orderStack(pulls: readonly Pull[]): Stack {
  const depths = new Map(pulls.map((pull) => [pull, depth(pull, pulls)]));
  return [...pulls].sort((a, b) => (depths.get(a) ?? 0) - (depths.get(b) ?? 0) || a.number - b.number);
}

/** The pull requests of some references that the cache has, as a stack. */
export function stackOf(refs: readonly PullRef[], known: Pulls): Stack {
  const found = refs.map((ref) => known[refKey(ref)]).filter((pull) => pull !== undefined);
  return orderStack([...new Map(found.map((pull) => [pull.url, pull])).values()]);
}

/** The stages in the order they call for the person: one to review first, one that is done last. */
const LEAD_ORDER: readonly PullStage[] = ["review", "changes", "draft", "landing", "merged", "closed"];

/**
 * The pull request that says where a stack stands: the lowest one of the
 * stage that most calls for the person. So a stack is ready for review when
 * any of it is, and lands only when all of it is approved or merged.
 */
export function leadPull(stack: Stack): Pull | null {
  for (const stage of LEAD_ORDER) {
    const pull = stack.find((candidate) => candidate.stage === stage);
    if (pull) return pull;
  }
  return null;
}

/** The pull requests that can still change: not merged, not closed. */
export function openPulls(stack: Stack): Stack {
  return stack.filter((pull) => pull.stage !== "merged" && pull.stage !== "closed");
}

/** A pull request in a few words: "#123 in review". */
export function pullLabel(pull: Pull): string {
  return `#${pull.number} ${STAGE_WORDS[pull.stage]}`;
}

/** A stack in a few words: neighbours at one stage share its words, as in "#1 merged, #2 #3 in review". */
export function stackLabel(stack: Stack): string | null {
  const runs: { numbers: string[]; stage: PullStage }[] = [];
  for (const pull of stack) {
    const last = runs[runs.length - 1];
    if (last?.stage === pull.stage) last.numbers.push(`#${pull.number}`);
    else runs.push({ numbers: [`#${pull.number}`], stage: pull.stage });
  }
  return runs.length ? runs.map((run) => `${run.numbers.join(" ")} ${STAGE_WORDS[run.stage]}`).join(", ") : null;
}
