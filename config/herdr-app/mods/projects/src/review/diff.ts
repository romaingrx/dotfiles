import type { Pull } from "../pulls";

/** What a line of a diff does: the branch adds it, removes it, or keeps it. */
export type Sign = "+" | "-" | " ";

export interface DiffLine {
  readonly sign: Sign;
  /** Its number in the base's file; null for a line the branch adds. */
  readonly old: number | null;
  /** Its number in the branch's file; null for a line the branch removes. */
  readonly now: number | null;
  readonly text: string;
}

export interface Hunk {
  /** The `@@` line that opens it. */
  readonly header: string;
  readonly lines: readonly DiffLine[];
}

export type Change = "added" | "deleted" | "modified" | "renamed";

export interface DiffFile {
  readonly path: string;
  /** Its path in the base, for a file the branch moved. */
  readonly from: string | null;
  readonly change: Change;
  readonly binary: boolean;
  readonly hunks: readonly Hunk[];
  readonly added: number;
  readonly removed: number;
}

/** A thread's branch against its base. */
export interface BranchDiff {
  /** The ref the branch is compared with. */
  readonly base: string;
  readonly files: readonly DiffFile[];
}

/** The usual names of a repository's main branch, as a remote and a local one. */
const USUAL_BASES = ["origin/HEAD", "origin/main", "origin/master", "main", "master"];

/**
 * The refs a branch may be compared with, best first: the base of its pull
 * request, then the repository's main branch. The first one the repository has
 * is the base.
 */
export function baseRefs(pullBase: string | null): string[] {
  const named = pullBase ? [`origin/${pullBase}`, pullBase] : [];
  return [...new Set([...named, ...USUAL_BASES])];
}

/** What the review of one layer of a thread's work reads. */
export interface ReviewRange {
  /** The refs to compare with, best first. */
  readonly bases: readonly string[];
  /** The branch to read; null reads the folder, with what is not committed. */
  readonly tip: string | null;
}

/**
 * What to read for a pull request of a thread whose folder is on `branch`.
 * The layer that is checked out is read from the folder; a lower layer of a
 * stack is read from its own branch, so only what it committed.
 */
export function reviewRange(pull: Pull | null, branch: string): ReviewRange {
  const tip = pull && pull.head !== branch ? pull.head : null;
  return { bases: baseRefs(pull?.base ?? null), tip };
}

const NO_FILE = "/dev/null";
const FILE = "diff --git ";
/** Git puts a path with a quote, a tab or a line break in it between quotes. */
const QUOTED = /^"(.*)"$/;
const HUNK = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/;

/** A file while its lines are read: its header first, then its hunks. */
interface OpenFile {
  path: string;
  from: string | null;
  change: Change;
  binary: boolean;
  hunks: { header: string; lines: DiffLine[] }[];
}

/** Where the open hunk stands: the number of its next line on each side, and how many lines it still has there. */
interface Cursor {
  old: number;
  now: number;
  oldLeft: number;
  nowLeft: number;
}

/** The path of `a/<path> b/<path>`, when both are the same path. A path may hold spaces. */
function samePath(pair: string): string | null {
  const path = pair.slice("a/".length, (pair.length - " ".length) / 2);
  return pair === `a/${path} b/${path}` ? path : null;
}

/** The path of a `--- a/<path>` or `+++ b/<path>` line; null for no file. Git ends a path that has a space with a tab. */
function sidePath(line: string): string | null {
  const path = line.slice(4).replace(/\t$/, "").replace(QUOTED, "$1");
  return path === NO_FILE ? null : path.slice(2);
}

/** Opens a file at its `diff --git` line. The lines after it name the file better when they are there. */
function openFile(line: string): OpenFile {
  const pair = line.slice(FILE.length);
  return { path: samePath(pair) ?? pair, from: null, change: "modified", binary: false, hunks: [] };
}

/** Reads one line of a file's header into the file. */
function readHeader(file: OpenFile, line: string): void {
  if (line.startsWith("new file mode")) file.change = "added";
  else if (line.startsWith("deleted file mode")) file.change = "deleted";
  else if (line.startsWith("rename from ")) file.from = line.slice("rename from ".length);
  else if (line.startsWith("rename to ")) {
    file.path = line.slice("rename to ".length);
    file.change = "renamed";
  } else if (line.startsWith("Binary files ") || line === "GIT binary patch") file.binary = true;
  else if (line.startsWith("--- ") || line.startsWith("+++ ")) file.path = sidePath(line) ?? file.path;
}

/** Opens a hunk at its `@@` line. A side without a count has one line. */
function openHunk(file: OpenFile, line: string, sizes: RegExpExecArray): Cursor {
  file.hunks.push({ header: line, lines: [] });
  return {
    old: Number(sizes[1]),
    oldLeft: Number(sizes[2] ?? 1),
    now: Number(sizes[3]),
    nowLeft: Number(sizes[4] ?? 1),
  };
}

/** Reads one line of the open hunk. `\ No newline at end of file` is no line of the file. */
function readLine(lines: DiffLine[], line: string, at: Cursor): void {
  const text = line.slice(1);
  if (line.startsWith("+")) {
    lines.push({ sign: "+", old: null, now: at.now++, text });
    at.nowLeft--;
  } else if (line.startsWith("-")) {
    lines.push({ sign: "-", old: at.old++, now: null, text });
    at.oldLeft--;
  } else if (!line.startsWith("\\")) {
    lines.push({ sign: " ", old: at.old++, now: at.now++, text });
    at.oldLeft--;
    at.nowLeft--;
  }
}

function count(lines: readonly DiffLine[], sign: Sign): number {
  return lines.filter((line) => line.sign === sign).length;
}

function closeFile(file: OpenFile): DiffFile {
  const lines = file.hunks.flatMap((hunk) => hunk.lines);
  return {
    ...file,
    from: file.change === "renamed" ? file.from : null,
    added: count(lines, "+"),
    removed: count(lines, "-"),
  };
}

/**
 * Reads what `git diff` prints. A hunk's header says how many lines it has on
 * each side, and the lines are counted against it: a removed line that reads
 * `-- a/file` looks like a file's header.
 */
export function parseDiff(text: string): DiffFile[] {
  const files: OpenFile[] = [];
  let at: Cursor = { old: 0, now: 0, oldLeft: 0, nowLeft: 0 };
  for (const line of text.split("\n")) {
    const file = files[files.length - 1];
    const hunk = file?.hunks[file.hunks.length - 1];
    const sizes = HUNK.exec(line);
    if (hunk && (at.oldLeft > 0 || at.nowLeft > 0)) readLine(hunk.lines, line, at);
    else if (line.startsWith(FILE)) files.push(openFile(line));
    else if (file && sizes) at = openHunk(file, line, sizes);
    else if (file) readHeader(file, line);
  }
  return files.map(closeFile);
}

/** Reads what the diff script prints: the base it found on the first line, then the diff. */
export function parseBranchDiff(output: string): BranchDiff {
  const [base = "", ...diff] = output.split("\n");
  return { base, files: parseDiff(diff.join("\n")) };
}
