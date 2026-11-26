import { isRecord, text } from "./parse";

/** Where a pull request stands, as the person sees it. */
export type PullStage = "draft" | "review" | "changes" | "landing" | "merged" | "closed";

/** The pull request of the branch a thread works on. */
export interface Pull {
  readonly number: number;
  readonly url: string;
  readonly stage: PullStage;
  /** The branch it merges into. Null for one stored before the mod read that. */
  readonly base: string | null;
}

/** The pull requests of the threads that have one, by the thread's terminal address. */
export type Pulls = Readonly<Record<string, Pull>>;

/** The fields `gh pr view --json` is asked for. */
export const PULL_FIELDS = "number,url,state,isDraft,reviewDecision,autoMergeRequest,baseRefName";

const STAGE_WORDS: Readonly<Record<PullStage, string>> = {
  draft: "draft",
  review: "in review",
  changes: "changes requested",
  landing: "landing",
  merged: "merged",
  closed: "closed",
};

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

/** Reads what `gh pr view --json` prints, or a stored pull request; null for anything else. */
export function parsePull(value: unknown): Pull | null {
  if (!isRecord(value) || typeof value.number !== "number" || typeof value.url !== "string") return null;
  const stored = typeof value.stage === "string" && value.stage in STAGE_WORDS ? (value.stage as PullStage) : null;
  const base = text(value.base) ?? text(value.baseRefName);
  return { number: value.number, url: value.url, stage: stored ?? stageOf(value), base };
}

/** Reads the stored pull requests; anything that is not one is dropped. */
export function parsePulls(value: unknown): Pulls {
  if (!isRecord(value)) return {};
  const pulls = Object.entries(value).map(([address, pull]) => [address, parsePull(pull)] as const);
  return Object.fromEntries(pulls.filter((entry): entry is readonly [string, Pull] => entry[1] !== null));
}

/** A pull request in a few words: "#123 in review". */
export function pullLabel(pull: Pull): string {
  return `#${pull.number} ${STAGE_WORDS[pull.stage]}`;
}
