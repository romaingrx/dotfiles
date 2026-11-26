import { setShared, shared } from "herdr";
import { NO_DRAFT, parseDrafts, withDraft, type Draft } from "./draft";

/** The shared key of the reviews the person writes: they outlive the review's dialog and the app. */
const REVIEWS = "projects.reviews";

export function readDraft(thread: string): Draft {
  return parseDrafts(shared(REVIEWS))[thread] ?? NO_DRAFT;
}

export function saveDraft(thread: string, draft: Draft): void {
  setShared(REVIEWS, withDraft(parseDrafts(shared(REVIEWS)), thread, draft));
}
