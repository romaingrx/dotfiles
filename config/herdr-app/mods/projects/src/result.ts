/**
 * What a step that can fail gives back: its value, or why it failed, in words
 * the person can read. Whoever calls the step decides what the person sees of
 * a failure. Only a bug or a broken setup throws.
 */
export type Result<T> = { readonly ok: true; readonly value: T } | { readonly ok: false; readonly error: string };

/** The result of a step that is run for what it does: nobody reads its value. */
export type Outcome = Result<unknown>;

export function ok<T>(value: T): Result<T> {
  return { ok: true, value };
}

export function fail(error: string): Result<never> {
  return { ok: false, error };
}

/** A step that had nothing to do, or nothing to give back. */
export const DONE: Outcome = ok(null);

function messageOf(thrown: unknown): string {
  return thrown instanceof Error ? thrown.message : String(thrown);
}

/**
 * Waits for work that says it failed with a rejected promise, as the app's own
 * functions do. What it rejects with, or throws before it starts, becomes a
 * failure. With `attemptSync`, this is the one place that catches.
 */
export async function attempt<T>(work: () => Promise<T>): Promise<Result<T>> {
  try {
    return ok(await work());
  } catch (thrown) {
    return fail(messageOf(thrown));
  }
}

/** Runs a step that says it failed with a throw, as the reading of JSON does. */
export function attemptSync<T>(step: () => T): Result<T> {
  try {
    return ok(step());
  } catch (thrown) {
    return fail(messageOf(thrown));
  }
}

function flat<T>(nested: Result<Result<T>>): Result<T> {
  return nested.ok ? nested.value : nested;
}

/**
 * Runs a step that gives a result, at the edge of work that nothing waits
 * for: a task, a notice of its own. A bug in the step has nobody above to
 * show it and would leave the person waiting, so here it is a failure too,
 * and the person sees it as they see any other.
 */
export async function settle<T>(step: () => Promise<Result<T>> | Result<T>): Promise<Result<T>> {
  return flat(await attempt(async () => step()));
}

/** `settle` for a step that ends at once, such as the handler of a click. */
export function settleSync<T>(step: () => Result<T>): Result<T> {
  return flat(attemptSync(step));
}

/** Waits for steps that run at once: the first failure in their order, else every value. */
export async function all<T>(steps: readonly Promise<Result<T>>[]): Promise<Result<T[]>> {
  const values: T[] = [];
  for (const result of await Promise.all(steps)) {
    if (!result.ok) return result;
    values.push(result.value);
  }
  return ok(values);
}
