import type { ExecResult } from "herdr";
import { fail, ok, type Result } from "./result";

/**
 * What a program printed, from how its run went. A run that failed says why in
 * words: what the program wrote on stderr, else its exit code, else that it
 * could not start. `name` is what those words call the program.
 */
export function outputOf(ran: Result<ExecResult>, name: string): Result<string> {
  if (!ran.ok) return fail(ran.error || `${name} could not start`);
  const { code, stdout, stderr } = ran.value;
  return code === 0 ? ok(stdout) : fail(stderr.trim() || `${name} ended with code ${code}`);
}
