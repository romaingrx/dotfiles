import { attemptSync, type Result } from "./result";

/** A value the app or the core gave, before its fields are read. */
export type Raw = Readonly<Record<string, unknown>>;

/** True for a plain object. A list is not one. */
export function isRecord(value: unknown): value is Raw {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** The value as an object to read fields from: an empty one for anything else. */
export function asRecord(value: unknown): Raw {
  return isRecord(value) ? value : {};
}

/** A string that is not empty, else null. */
export function text(value: unknown): string | null {
  return typeof value === "string" && value !== "" ? value : null;
}

/** Reads the JSON a program printed or a file holds. What it holds is still to be read, field by field. */
export function parseJson(json: string): Result<unknown> {
  return attemptSync((): unknown => JSON.parse(json));
}
