import { setShared, shared } from "herdr";
import { NO_DRAFT, parseDrafts, withDraft, type Draft } from "./draft";

/** The shared key of the reviews the person writes: they outlive the review's dialog and the app. */
const REVIEWS = "projects.reviews";

/** The draft at a key that `draftKey` made. */
export function readDraft(key: string): Draft {
  return parseDrafts(shared(REVIEWS))[key] ?? NO_DRAFT;
}

export function saveDraft(key: string, draft: Draft): void {
  setShared(REVIEWS, withDraft(parseDrafts(shared(REVIEWS)), key, draft));
}
