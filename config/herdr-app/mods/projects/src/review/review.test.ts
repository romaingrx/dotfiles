import { describe, expect, test } from "bun:test";
import { baseRefs, parseBranchDiff, parseDiff, type DiffFile } from "./diff";
import {
  anchorOf,
  commentAt,
  inOrder,
  isEmpty,
  NO_DRAFT,
  parseDrafts,
  reviewMessage,
  withComment,
  withDraft,
  withNote,
  withoutComment,
  type Anchor,
  type Span,
  type Comment,
  type Draft,
} from "./draft";
import {
  fileRows,
  lineKey,
  MAX_LINES,
  quoteOf,
  reviewFiles,
  spanBetween,
  spanRows,
  untab,
  widest,
  wrap,
  type ReviewFile,
  type Row,
} from "./rows";
import { fileTree, firstFile } from "./tree";

const MODIFIED = `diff --git a/src/app.ts b/src/app.ts
index 1111111..2222222 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -1,4 +1,5 @@ export function app() {
 const a = 1;
-const b = 2;
+const b = 3;
+const c = 4;
 return a;
 }
@@ -20 +21 @@
-old
+new
\\ No newline at end of file
`;

const ADDED = `diff --git a/notes/to do.md b/notes/to do.md
new file mode 100644
index 0000000..3333333
--- /dev/null
+++ b/notes/to do.md\t
@@ -0,0 +1,2 @@
+--- a/not a header
+second
`;

const DELETED = `diff --git a/gone.ts b/gone.ts
deleted file mode 100644
index 4444444..0000000
--- a/gone.ts
+++ /dev/null
@@ -1 +0,0 @@
-bye
`;

const RENAMED = `diff --git a/old name.ts b/new name.ts
similarity index 100%
rename from old name.ts
rename to new name.ts
`;

const BINARY = `diff --git a/logo.png b/logo.png
index 5555555..6666666 100644
Binary files a/logo.png and b/logo.png differ
`;

function only(text: string): DiffFile {
  const [file, ...rest] = parseDiff(text);
  if (!file || rest.length > 0) throw new Error("expected one file");
  return file;
}

function comment(fields: Partial<Comment> & Pick<Comment, "path" | "line">): Comment {
  return { side: "new", start: null, code: "", body: "Fix this.", ...fields };
}

function texts(rows: readonly Row[]): string[] {
  return rows.map((row) => (row.kind === "comment" ? `> ${row.lines.join(" / ")}` : row.text));
}

describe("a branch's diff", () => {
  test("is read file by file, with each line's number on both sides", () => {
    const file = only(MODIFIED);
    expect(file).toMatchObject({
      path: "src/app.ts",
      from: null,
      change: "modified",
      binary: false,
      added: 3,
      removed: 2,
    });
    expect(file.hunks.map((hunk) => hunk.header)).toEqual(["@@ -1,4 +1,5 @@ export function app() {", "@@ -20 +21 @@"]);
    expect(file.hunks[0]?.lines).toEqual([
      { sign: " ", old: 1, now: 1, text: "const a = 1;" },
      { sign: "-", old: 2, now: null, text: "const b = 2;" },
      { sign: "+", old: null, now: 2, text: "const b = 3;" },
      { sign: "+", old: null, now: 3, text: "const c = 4;" },
      { sign: " ", old: 3, now: 4, text: "return a;" },
      { sign: " ", old: 4, now: 5, text: "}" },
    ]);
    expect(file.hunks[1]?.lines).toEqual([
      { sign: "-", old: 20, now: null, text: "old" },
      { sign: "+", old: null, now: 21, text: "new" },
    ]);
  });

  test("knows a new file, a deleted one, a moved one and a binary one", () => {
    expect(only(ADDED)).toMatchObject({ path: "notes/to do.md", change: "added", added: 2, removed: 0 });
    expect(only(DELETED)).toMatchObject({ path: "gone.ts", change: "deleted", added: 0, removed: 1 });
    expect(only(RENAMED)).toMatchObject({ path: "new name.ts", from: "old name.ts", change: "renamed", hunks: [] });
    expect(only(BINARY)).toMatchObject({ path: "logo.png", binary: true, hunks: [] });
  });

  test("keeps a file apart whose path git quotes", () => {
    const quoted = `diff --git "a/odd\\"name.ts" "b/odd\\"name.ts"\n--- "a/odd\\"name.ts"\n+++ "b/odd\\"name.ts"\n@@ -1 +1 @@\n-a\n+b\n`;
    const files = parseDiff(MODIFIED + quoted);
    expect(files.map((file) => [file.path, file.added])).toEqual([
      ["src/app.ts", 3],
      ['odd\\"name.ts', 1],
    ]);
  });

  test("takes a line that looks like a header as a line of its hunk", () => {
    expect(only(ADDED).hunks[0]?.lines.map((line) => line.text)).toEqual(["--- a/not a header", "second"]);
  });

  test("reads every file of one output, and the base before them", () => {
    const diff = parseBranchDiff(`origin/main\n${MODIFIED}${ADDED}${DELETED}${RENAMED}${BINARY}`);
    expect(diff.base).toBe("origin/main");
    expect(diff.files.map((file) => file.path)).toEqual([
      "src/app.ts",
      "notes/to do.md",
      "gone.ts",
      "new name.ts",
      "logo.png",
    ]);
    expect(parseBranchDiff("origin/main\n")).toEqual({ base: "origin/main", files: [] });
  });

  test("is against the pull request's base first, then the main branch", () => {
    expect(baseRefs("feat/base")).toEqual([
      "origin/feat/base",
      "feat/base",
      "origin/HEAD",
      "origin/main",
      "origin/master",
      "main",
      "master",
    ]);
    expect(baseRefs("main")).toEqual(["origin/main", "main", "origin/HEAD", "origin/master", "master"]);
    expect(baseRefs(null)[0]).toBe("origin/HEAD");
  });
});

describe("a draft review", () => {
  const line: Span = { path: "src/app.ts", side: "new", line: 2, start: null };

  test("has one comment a line; no words remove it", () => {
    const first = withComment(NO_DRAFT, line, "const b = 3;", "  Why 3?  ");
    expect(first.comments).toEqual([{ ...line, code: "const b = 3;", body: "Why 3?" }]);
    const again = withComment(first, line, "const b = 3;", "Name it.");
    expect(again.comments.map((entry) => entry.body)).toEqual(["Name it."]);
    expect(commentAt(again, line)?.body).toBe("Name it.");
    expect(commentAt(again, { ...line, side: "old" })).toBeUndefined();
    expect(withComment(again, line, "", "  ").comments).toEqual([]);
    expect(withoutComment(again, line).comments).toEqual([]);
  });

  test("points at the base's file for a line the branch removes", () => {
    expect(anchorOf("a.ts", { sign: "-", old: 7, now: null, text: "" })).toEqual({
      path: "a.ts",
      side: "old",
      line: 7,
    });
    expect(anchorOf("a.ts", { sign: "+", old: null, now: 9, text: "" })).toEqual({
      path: "a.ts",
      side: "new",
      line: 9,
    });
    expect(anchorOf("a.ts", { sign: " ", old: 3, now: 4, text: "" })).toEqual({ path: "a.ts", side: "new", line: 4 });
  });

  test("is stored by thread; an empty one is dropped", () => {
    const draft = withComment(NO_DRAFT, line, "code", "Fix this.");
    const drafts = withDraft({}, "t2", draft);
    expect(parseDrafts(JSON.parse(JSON.stringify(drafts)))).toEqual({ t2: draft });
    expect(withDraft(drafts, "t1", withNote(NO_DRAFT, "Good."))).toEqual({
      t1: { note: "Good.", comments: [] },
      t2: draft,
    });
    expect(withDraft(drafts, "t2", NO_DRAFT)).toEqual({});
    expect(isEmpty(withNote(NO_DRAFT, "  "))).toBe(true);
  });

  test("is read back without what is not a comment", () => {
    const stored = {
      t1: {
        note: 3,
        comments: [
          { ...line, code: "x", body: "ok" },
          { path: "a", side: "up", line: 1, code: "", body: "no" },
          "oops",
        ],
      },
      t2: "oops",
    };
    expect(parseDrafts(stored)).toEqual({ t1: { note: "", comments: [{ ...line, code: "x", body: "ok" }] } });
    expect(parseDrafts(null)).toEqual({});
  });

  test("goes through the files as the diff lists them, then down each file", () => {
    const comments = [
      comment({ path: "b.ts", line: 9 }),
      comment({ path: "gone.ts", line: 1 }),
      comment({ path: "a.ts", line: 30 }),
      comment({ path: "b.ts", line: 2 }),
    ];
    const order = inOrder(comments, ["b.ts", "a.ts"]).map((entry) => `${entry.path}:${entry.line}`);
    expect(order).toEqual(["b.ts:2", "b.ts:9", "a.ts:30", "gone.ts:1"]);
  });

  test("is sent as one message, with the file, the line and the line's text of each comment", () => {
    const draft: Draft = {
      note: " Close. Two things. ",
      comments: [
        comment({ path: "b.ts", line: 9, code: "  return b;", body: "Return early.\nSee a.ts." }),
        comment({ path: "a.ts", line: 3, side: "old", code: "", body: "Keep this." }),
      ],
    };
    expect(reviewMessage(draft, ["a.ts", "b.ts"])).toBe(
      [
        "Review of your branch: 2 comments.",
        "Close. Two things.",
        "1. a.ts:3 (a line the branch removes)\n   Keep this.",
        "2. b.ts:9\n   > return b;\n   Return early.\n   See a.ts.",
      ].join("\n\n"),
    );
    expect(reviewMessage(withNote(NO_DRAFT, "All good."), [])).toBe("Review of your branch.\n\nAll good.");
    expect(reviewMessage({ note: "", comments: [comment({ path: "a.ts", line: 1 })] }, ["a.ts"])).toStartWith(
      "Review of your branch: 1 comment.\n\n1. a.ts:1\n",
    );
  });
});

describe("the rows of a file", () => {
  const file = only(MODIFIED);

  test("are its hunks and lines, with a comment under its line", () => {
    const on = comment({ path: "src/app.ts", line: 2, body: "Why 3?" });
    const [entry] = reviewFiles([file], [on]);
    if (!entry) throw new Error("expected a file");
    const rows = fileRows(entry, 40);
    expect(texts(rows)).toEqual([
      "@@ -1,4 +1,5 @@ export function app() {",
      "const a = 1;",
      "const b = 2;",
      "const b = 3;",
      "> Why 3?",
      "const c = 4;",
      "return a;",
      "}",
      "@@ -20 +21 @@",
      "old",
      "new",
    ]);
    const commented = rows.filter((row) => row.kind === "line" && row.commented).map((row) => row.key);
    expect(commented).toEqual([lineKey(on)]);
    expect(new Set(rows.map((row) => row.key)).size).toBe(rows.length);
    expect(widest(rows)).toBe("@@ -1,4 +1,5 @@ export function app() {".length);
  });

  test("start with the comments whose line is no longer in the diff", () => {
    const [entry] = reviewFiles([file], [comment({ path: "src/app.ts", line: 99, body: "Old." })]);
    if (!entry) throw new Error("expected a file");
    const [first] = fileRows(entry, 60);
    expect(first).toMatchObject({
      kind: "comment",
      stale: true,
      lines: ["Line 99, which is no longer in the diff:", "Old."],
    });
  });

  test("keep a file that only has comments left, after the files of the diff", () => {
    const files = reviewFiles([file], [comment({ path: "gone.ts", line: 4 })]);
    expect(files.map((entry) => [entry.file.path, entry.gone, entry.comments.length])).toEqual([
      ["src/app.ts", false, 0],
      ["gone.ts", true, 1],
    ]);
    const last = files[1];
    if (!last) throw new Error("expected a file");
    expect(texts(fileRows(last, 60))).toEqual([
      "> Line 4, which is no longer in the diff: / Fix this.",
      "This file is no longer in the diff.",
    ]);
  });

  test("say why a file has no line to show", () => {
    const rowsOf = (text: string) => texts(fileRows({ file: only(text), comments: [], gone: false }, 60));
    expect(rowsOf(BINARY)).toEqual(["A binary file: it has no text to show."]);
    expect(rowsOf(RENAMED)).toEqual(["No line of this file changed."]);
  });

  test("stop after the first lines of a long diff", () => {
    const lines = Array.from({ length: MAX_LINES + 10 }, (_, index) => `+line ${index}`).join("\n");
    const long = only(
      `diff --git a/big.txt b/big.txt\n--- /dev/null\n+++ b/big.txt\n@@ -0,0 +1,${MAX_LINES + 10} @@\n${lines}\n`,
    );
    const rows = fileRows({ file: long, comments: [], gone: false }, 60);
    expect(rows.filter((row) => row.kind === "line")).toHaveLength(MAX_LINES);
    expect(rows.at(-1)).toMatchObject({ kind: "note" });
  });

  test("cut a comment into lines that fit, between words where they can", () => {
    expect(wrap("one two three four", 9)).toEqual(["one two", "three", "four"]);
    expect(wrap("abcdefghij", 4)).toEqual(["abcd", "efgh", "ij"]);
    expect(wrap("first\n\nlast", 20)).toEqual(["first", "", "last"]);
    expect(wrap("short", 0)).toEqual(["s", "h", "o", "r", "t"]);
  });

  test("draw a tab as the spaces to the next tab stop", () => {
    expect(untab("\tx")).toBe("    x");
    expect(untab("ab\tc")).toBe("ab  c");
    expect(untab("abcd\te")).toBe("abcd    e");
  });
});

describe("a comment on several lines", () => {
  const file = only(MODIFIED);
  const rows = fileRows({ file, comments: [], gone: false }, 60);
  const at = (side: "old" | "new", line: number): Anchor => ({ path: "src/app.ts", side, line });
  const texts = (span: Span) => spanRows(rows, span).map((row) => row.text);

  test("goes from the line picked first to the other one, whichever the diff lists first", () => {
    const down = spanBetween(rows, at("old", 2), at("new", 4));
    expect(down).toEqual({ path: "src/app.ts", side: "new", line: 4, start: { side: "old", line: 2 } });
    expect(spanBetween(rows, at("new", 4), at("old", 2))).toEqual(down);
    expect(spanBetween(rows, at("new", 3), at("new", 3))).toEqual({ ...at("new", 3), start: null });
    expect(texts(down)).toEqual(["const b = 2;", "const b = 3;", "const c = 4;", "return a;"]);
  });

  test("covers its last line when the diff does not show its first one, and none when it shows neither", () => {
    expect(texts({ ...at("new", 3), start: { side: "new", line: 90 } })).toEqual(["const c = 4;"]);
    expect(texts({ ...at("new", 90), start: { side: "new", line: 2 } })).toEqual([]);
    expect(texts({ ...at("new", 1), start: null })).toEqual(["const a = 1;"]);
  });

  test("marks each of its lines, and shows under the last one", () => {
    const span = spanBetween(rows, at("new", 2), at("new", 4));
    const [entry] = reviewFiles([file], [comment({ ...span, body: "Too long." })]);
    if (!entry) throw new Error("expected a file");
    const drawn = fileRows(entry, 60);
    expect(drawn.filter((row) => row.kind === "line" && row.commented).map((row) => row.key)).toEqual(
      [at("new", 2), at("new", 3), at("new", 4)].map(lineKey),
    );
    const card = drawn.findIndex((row) => row.kind === "comment");
    expect(drawn[card - 1]?.key).toBe(lineKey(at("new", 4)));
  });

  test("is told to the thread with its lines and their text", () => {
    const span = spanBetween(rows, at("new", 2), at("new", 3));
    const code = quoteOf(spanRows(rows, span));
    const draft = withComment(NO_DRAFT, span, code, "One name for both.");
    expect(parseDrafts(JSON.parse(JSON.stringify({ t1: draft }))).t1).toEqual(draft);
    expect(reviewMessage(draft, ["src/app.ts"])).toBe(
      [
        "Review of your branch: 1 comment.",
        "1. src/app.ts:2-3\n   > const b = 3;\n   > const c = 4;\n   One name for both.",
      ].join("\n\n"),
    );
  });

  test("quotes the first lines of a long one", () => {
    const added = Array.from({ length: 14 }, (_, index) => `+line ${index}`).join("\n");
    const long = only(`diff --git a/big.txt b/big.txt\n--- /dev/null\n+++ b/big.txt\n@@ -0,0 +1,14 @@\n${added}\n`);
    const all: Span = { path: "big.txt", side: "new", line: 14, start: { side: "new", line: 1 } };
    const quote = quoteOf(spanRows(fileRows({ file: long, comments: [], gone: false }, 60), all)).split("\n");
    expect(quote).toHaveLength(13);
    expect(quote.at(-1)).toBe("…");
  });
});

describe("the tree of a review's files", () => {
  const entry = (path: string): ReviewFile => ({ file: { ...only(MODIFIED), path }, comments: [], gone: false });
  const files = [
    "README.md",
    "config/app/mods/a.ts",
    "config/app/mods/src/b.ts",
    "config/app/x.ts",
    "docs/guide/one.md",
  ].map(entry);
  const shape = (folded: string[] = []) =>
    fileTree(files, new Set(folded)).map(
      (row) => `${"  ".repeat(row.depth)}${row.name}${row.kind === "folder" ? "/" : ""}`,
    );

  test("has the folders of a folder first, then its files; a folder with one folder in it takes one row", () => {
    expect(shape()).toEqual([
      "config/app/",
      "  mods/",
      "    src/",
      "      b.ts",
      "    a.ts",
      "  x.ts",
      "docs/guide/",
      "  one.md",
      "README.md",
    ]);
  });

  test("shows nothing under a folded folder", () => {
    expect(shape(["config/app/mods"])).toEqual([
      "config/app/",
      "  mods/",
      "  x.ts",
      "docs/guide/",
      "  one.md",
      "README.md",
    ]);
    expect(shape(["config/app", "docs/guide"])).toEqual(["config/app/", "docs/guide/", "README.md"]);
    expect(fileTree(files, new Set(["config/app"])).find((row) => row.kind === "folder")).toMatchObject({
      path: "config/app",
      open: false,
    });
  });

  test("opens on its first file from the top, whatever is folded", () => {
    expect(firstFile(files)?.file.path).toBe("config/app/mods/src/b.ts");
    expect(firstFile([])).toBeUndefined();
    expect(fileTree([], new Set())).toEqual([]);
  });
});
