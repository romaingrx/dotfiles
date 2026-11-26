import { asRecord, text } from "../parse";
import { anchorKey, type About, type Anchor } from "./draft";

/** One comment of a discussion on GitHub. */
export interface Remark {
  readonly author: string;
  readonly body: string;
  readonly url: string;
}

/** A discussion of the pull request on GitHub: the comments people left on one line of a file. */
export interface Discussion extends Anchor {
  /** What GitHub calls it: a reply names it. */
  readonly id: string;
  /** Set when the line it was left on changed since: its line number is the one it had then. */
  readonly outdated: boolean;
  readonly remarks: readonly Remark[];
}

/** Asks GitHub for the discussions of a pull request, with whether each one is settled. */
export const DISCUSSIONS_QUERY = `query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line originalLine diffSide
          comments(first: 50) { nodes { author { login } body url } }
        }
      }
    }
  }
}`;

/** Adds a comment to a discussion, in the name of whoever `gh` is signed in as. */
export const REPLY_MUTATION = `mutation($discussion: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: $discussion, body: $body }) {
    comment { url }
  }
}`;

function nodes(value: unknown): unknown[] {
  const list = asRecord(value).nodes;
  return Array.isArray(list) ? list : [];
}

function parseRemark(value: unknown): Remark | null {
  const raw = asRecord(value);
  const body = text(raw.body);
  const url = text(raw.url);
  // GitHub names no author for an account that is gone.
  return body && url ? { author: text(asRecord(raw.author).login) ?? "ghost", body, url } : null;
}

/** Null for a discussion that is settled, or that has no line or no comment to show. */
function parseDiscussion(value: unknown): Discussion | null {
  const raw = asRecord(value);
  const id = text(raw.id);
  const path = text(raw.path);
  const line = raw.line ?? raw.originalLine;
  const remarks = nodes(raw.comments)
    .map(parseRemark)
    .filter((remark) => remark !== null);
  if (raw.isResolved === true || !id || !path || typeof line !== "number" || remarks.length === 0) return null;
  return { id, path, side: raw.diffSide === "LEFT" ? "old" : "new", line, outdated: raw.isOutdated === true, remarks };
}

/** Reads GitHub's answer to the query: the discussions that are still open. */
export function parseDiscussions(answer: unknown): Discussion[] {
  const pull = asRecord(asRecord(asRecord(answer).data).repository).pullRequest;
  return nodes(asRecord(pull).reviewThreads)
    .map(parseDiscussion)
    .filter((discussion) => discussion !== null);
}

/** How much of a comment on GitHub a comment of the review quotes. */
const QUOTE = 160;

/**
 * What a comment of the review answers when its line has a discussion: the
 * comment that opened it. The answer goes to the thread only, until the person
 * says it is a reply on GitHub too.
 */
export function aboutOf(discussion: Discussion): About | null {
  const [first] = discussion.remarks;
  if (!first) return null;
  const start = first.body.trim().split("\n")[0] ?? "";
  const quote = start.length > QUOTE ? `${start.slice(0, QUOTE)}…` : start;
  return { author: first.author, url: first.url, quote, discussion: discussion.id, post: "none" };
}

/** The discussions on one line. People can start more than one there. */
export function discussionsAt(discussions: readonly Discussion[], anchor: Anchor): Discussion[] {
  const key = anchorKey(anchor);
  return discussions.filter((discussion) => anchorKey(discussion) === key);
}
