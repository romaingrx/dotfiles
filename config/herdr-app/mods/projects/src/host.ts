// The mod's boundary with the machine and the app. Each call here can fail for
// a reason that is no bug: a program is not installed, a machine is away, the
// app refuses a command. So each gives a result, and none throws.

import { exec, hc, readTextFile, run } from "herdr";
import { outputOf } from "./exit";
import { attempt, attemptSync, type Outcome, type Result } from "./result";

/** Where a program runs and how long it may take, as `exec` takes them. */
type ExecOptions = NonNullable<Parameters<typeof exec>[2]>;

export interface RunOptions extends ExecOptions {
  /** What a failure calls the program, when its command says too little. */
  readonly name?: string;
}

/** Runs a program to its end, and gives what it printed. */
export async function runProgram(program: string, args: string[], options: RunOptions = {}): Promise<Result<string>> {
  const { name = program, ...where } = options;
  return outputOf(await attempt(() => exec(program, args, where)), name);
}

/** Runs `hc`, Herdr's core, and gives what it printed. */
export async function core(args: string[]): Promise<Result<string>> {
  return outputOf(await attempt(() => hc(args)), `hc ${args[0]}`);
}

/** Reads a text file: null for one that is not there. */
export function readText(path: string): Promise<Result<string | null>> {
  return attempt(() => readTextFile(path));
}

/** Runs a command of the app. Herdr refuses one it cannot take, such as a layout that nests too deep. */
export function runCommand(name: string, args: Record<string, unknown>): Outcome {
  return attemptSync(() => run(name, args));
}
