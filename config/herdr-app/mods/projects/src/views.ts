import { isRecord } from "./parse";

/** What each project had open in the right panel: a thread's address, or null for the list. */
export type Views = Readonly<Record<string, string | null>>;

/** Reads the stored views; anything that is not one is dropped. */
export function parseViews(value: unknown): Views {
  if (!isRecord(value)) return {};
  const entries = Object.entries(value).filter(
    (entry): entry is [string, string | null] => typeof entry[1] === "string" || entry[1] === null,
  );
  return Object.fromEntries(entries);
}

export function withView(views: Views, project: string, thread: string | null): Views {
  return { ...views, [project]: thread };
}

/** The thread a project had open, if it is still one of its threads. */
export function rememberedThread(views: Views, project: string, threads: readonly string[]): string | null {
  const thread = views[project] ?? null;
  return thread !== null && threads.includes(thread) ? thread : null;
}
