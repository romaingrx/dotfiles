import { describe, expect, test } from "bun:test";
import type { Pull } from "../pulls";
import { baseRefs, parseBranchDiff, parseDiff, rangeLabel, reviewRange, type DiffFile } from "./diff";
import {
  anchorOf,
  commentAt,
  draftKey,
  duePosts,
  inOrder,
  isEmpty,
  NO_DRAFT,
  parseDrafts,
  reviewMessage,
  withComment,
  withDraft,
  withNote,
  withoutComment,
  withPosted,
  type About,
  type Anchor,
  type Span,
  type Comment,
  type Draft,
} from "./draft";
import { aboutOf, discussionsAt, parseDiscussions, type Discussion } from "./discussions";
import {
  fileRows,
  lineKey,
  MAX_LINES,
  MAX_REMARK_LINES,
  fileKey,
  unchangedBefore,
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
import { assemble, builtFrom, fileAt, fileStarts, offsets, rowToReveal, staleFiles } from "./layout";
import { isPickable, targetAt, whereOf } from "./target";
import { fileTree, filterFiles, inTreeOrder } from "./tree";

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

/** The lower layer of a stack, on the main branch. */
const LAYER: Pull = {
  number: 136,
  url: "https://example.test/o/r/pull/136",
  title: "The lower layer",
  stage: "review",
  base: "main",
  head: "low",
};

function only(text: string): DiffFile {
  const [file, ...rest] = parseDiff(text);
  if (!file || rest.length > 0) throw new Error("expected one file");
  return file;
}

/** What an answer to the first comment of the discussion `D1` is about. It is for the thread only. */
const ABOUT: About = {
  author: "ana",
  url: "https://example.test/pull/7#r1",
  quote: "Rename this.",
  discussion: "D1",
  post: "none",
};

function comment(fields: Partial<Comment> & Pick<Comment, "path" | "line">): Comment {
  return { side: "new", start: null, code: "", body: "Fix this.", about: null, ...fields };
}

function discussion(fields: Partial<Discussion> & Pick<Discussion, "path" | "line">): Discussion {
  const remarks = [{ author: "ana", body: "Rename this.", url: "https://example.test/pull/7#r1" }];
  return { id: "D1", side: "new", start: null, outdated: false, remarks, ...fields };
}

function texts(rows: readonly Row[]): string[] {
  return rows.map((row) => (row.kind === "card" ? `> ${row.lines.map((line) => line.text).join(" / ")}` : row.text));
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

  test("is read from the folder for the layer that is checked out, and from its branch for a lower one", () => {
    expect(reviewRange(null, "top")).toEqual({ bases: baseRefs(null), tip: null });
    expect(reviewRange({ ...LAYER, head: "top", base: "low" }, "top")).toEqual({ bases: baseRefs("low"), tip: null });
    expect(reviewRange(LAYER, "top")).toEqual({ bases: baseRefs("main"), tip: "low" });
  });

  test("names what it compares once the branch is known and the diff is read", () => {
    expect(rangeLabel(null, "top", "origin/main")).toBe("top → origin/main");
    expect(rangeLabel(LAYER, "top", "origin/main")).toBe("low → origin/main");
    expect(rangeLabel({ ...LAYER, head: "top" }, "top", "main")).toBe("top → main");
    expect(rangeLabel(LAYER, undefined, "origin/main")).toBeNull();
    expect(rangeLabel(LAYER, "top", undefined)).toBeNull();
  });
});

describe("a draft review", () => {
  const line: Span = { path: "src/app.ts", side: "new", line: 2, start: null };

  test("has one comment a line; no words remove it", () => {
    const written = { code: "const b = 3;", about: null };
    const first = withComment(NO_DRAFT, line, { ...written, body: "  Why 3?  " });
    expect(first.comments).toEqual([{ ...line, ...written, body: "Why 3?" }]);
    const again = withComment(first, line, { ...written, body: "Name it." });
    expect(again.comments.map((entry) => entry.body)).toEqual(["Name it."]);
    expect(commentAt(again, line)?.body).toBe("Name it.");
    expect(commentAt(again, { ...line, side: "old" })).toBeUndefined();
    expect(withComment(again, line, { ...written, body: "  " }).comments).toEqual([]);
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
    const draft = withComment(NO_DRAFT, line, { code: "code", body: "Fix this.", about: { ...ABOUT, post: "due" } });
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
    const kept = { ...line, code: "x", body: "ok", about: null };
    expect(parseDrafts(stored)).toEqual({ t1: { note: "", comments: [kept] } });
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
    expect(reviewMessage(draft, ["a.ts", "b.ts"], null)).toBe(
      [
        "Review of your branch: 2 comments.",
        "Close. Two things.",
        "1. a.ts:3 (a line the branch removes)\n   Keep this.",
        "2. b.ts:9\n   > return b;\n   Return early.\n   See a.ts.",
      ].join("\n\n"),
    );
    expect(reviewMessage(withNote(NO_DRAFT, "All good."), [], null)).toBe("Review of your branch.\n\nAll good.");
  });

  test("is kept and sent for one pull request of a stack", () => {
    expect(draftKey("t7", null)).toBe("t7");
    expect(draftKey("t7", LAYER)).toBe("t7#136");
    expect(draftKey("t7", { ...LAYER, number: 137 })).not.toBe(draftKey("t7", LAYER));
    expect(reviewMessage(withNote(NO_DRAFT, "All good."), [], LAYER)).toBe(
      "Review of pull request #136 (https://example.test/o/r/pull/136).\n\nAll good.",
    );
    expect(reviewMessage({ note: "", comments: [comment({ path: "a.ts", line: 1 })] }, ["a.ts"], LAYER)).toStartWith(
      "Review of pull request #136 (https://example.test/o/r/pull/136): 1 comment.\n\n1. a.ts:1\n",
    );
  });

  test("says which comment on GitHub a comment answers", () => {
    const answer = comment({
      path: "a.ts",
      line: 3,
      code: "const a = 1;",
      body: "Address this comment.",
      about: ABOUT,
    });
    expect(reviewMessage({ note: "", comments: [answer] }, ["a.ts"], null)).toBe(
      [
        "Review of your branch: 1 comment.",
        [
          "1. a.ts:3",
          "   > const a = 1;",
          "   In answer to @ana on GitHub (https://example.test/pull/7#r1):",
          "   > Rename this.",
          "   Address this comment.",
        ].join("\n"),
      ].join("\n\n"),
    );
    expect(reviewMessage({ note: "", comments: [comment({ path: "a.ts", line: 1 })] }, ["a.ts"], null)).toStartWith(
      "Review of your branch: 1 comment.\n\n1. a.ts:1\n",
    );
  });

  test("knows which answers are still to be posted on GitHub, and posts none twice", () => {
    const due = comment({ path: "a.ts", line: 3, body: "Good point.", about: { ...ABOUT, post: "due" } });
    const forThread = comment({ path: "a.ts", line: 9, about: ABOUT });
    const draft: Draft = { note: "", comments: [due, forThread, comment({ path: "b.ts", line: 1 })] };
    expect(duePosts(draft)).toEqual([due]);
    const posted = withPosted(draft, due);
    expect(duePosts(posted)).toEqual([]);
    expect(posted.comments.map((entry) => entry.about?.post ?? null)).toEqual(["done", "none", null]);
    expect(withPosted(draft, { path: "b.ts", side: "new", line: 1 })).toEqual(draft);
    expect(parseDrafts(JSON.parse(JSON.stringify({ t1: posted }))).t1).toEqual(posted);
    expect(reviewMessage({ note: "", comments: [posted.comments[0] ?? due] }, ["a.ts"], null)).toContain(
      "In answer to @ana on GitHub (https://example.test/pull/7#r1), where this answer is posted too:",
    );
  });

  test("reads an answer of an unknown kind as one for the thread only", () => {
    const stored = {
      t1: { note: "", comments: [{ ...line, code: "", body: "ok", about: { ...ABOUT, post: "soon" } }] },
    };
    expect(parseDrafts(stored).t1?.comments[0]?.about?.post).toBe("none");
    const old = {
      t1: { note: "", comments: [{ ...line, code: "", body: "ok", about: { author: "ana", url: "u", quote: "" } }] },
    };
    expect(parseDrafts(old).t1?.comments[0]?.about).toBeNull();
  });
});

describe("the discussions of a pull request on GitHub", () => {
  const thread = (fields: Record<string, unknown>) => ({
    id: "D1",
    isResolved: false,
    isOutdated: false,
    path: "src/app.ts",
    line: 3,
    originalLine: 2,
    diffSide: "RIGHT",
    comments: {
      nodes: [{ author: { login: "ana" }, body: "Rename this.\nIt reads badly.", url: "https://example.test/r1" }],
    },
    ...fields,
  });
  const answer = (nodes: unknown[]) => ({ data: { repository: { pullRequest: { reviewThreads: { nodes } } } } });

  test("are read from GitHub's answer: the open ones that have a line and a comment", () => {
    const removed = { author: null, body: "Why?", url: "https://example.test/r2" };
    const read = parseDiscussions(
      answer([
        thread({}),
        thread({ isResolved: true }),
        thread({
          id: "D2",
          line: null,
          isOutdated: true,
          diffSide: "LEFT",
          comments: { nodes: [removed, { body: "" }] },
        }),
        thread({ line: null, originalLine: null }),
        thread({ id: null }),
        thread({ comments: { nodes: [] } }),
        "oops",
      ]),
    );
    expect(read).toEqual([
      {
        id: "D1",
        path: "src/app.ts",
        side: "new",
        line: 3,
        start: null,
        outdated: false,
        remarks: [{ author: "ana", body: "Rename this.\nIt reads badly.", url: "https://example.test/r1" }],
      },
      {
        id: "D2",
        path: "src/app.ts",
        side: "old",
        line: 2,
        start: null,
        outdated: true,
        remarks: [{ ...removed, author: "ghost" }],
      },
    ]);
    expect(parseDiscussions({ errors: [] })).toEqual([]);
    expect(parseDiscussions(null)).toEqual([]);
  });

  test("know the first line of a discussion on several lines, and its side", () => {
    const starts = (fields: Record<string, unknown>) => parseDiscussions(answer([thread(fields)]))[0]?.start;
    expect(starts({ startLine: 1 })).toEqual({ side: "new", line: 1 });
    expect(starts({ startLine: 1, startDiffSide: "LEFT" })).toEqual({ side: "old", line: 1 });
    expect(starts({ startLine: null, originalStartLine: 2, diffSide: "LEFT" })).toEqual({ side: "old", line: 2 });
    expect(starts({ startLine: null, originalStartLine: null })).toBeNull();
  });

  test("are found by their line, and name what an answer is about", () => {
    const talks = [discussion({ path: "a.ts", line: 3 }), discussion({ path: "a.ts", line: 3, side: "old" })];
    expect(discussionsAt(talks, { path: "a.ts", side: "new", line: 3 })).toEqual([talks[0] as Discussion]);
    expect(discussionsAt(talks, { path: "a.ts", side: "new", line: 4 })).toEqual([]);
    const long = discussion({
      path: "a.ts",
      line: 1,
      remarks: [{ author: "ana", body: `${"x".repeat(200)}\nmore`, url: "u" }],
    });
    expect(aboutOf(talks[0] as Discussion)).toEqual(ABOUT);
    expect(aboutOf(long)?.quote).toBe(`${"x".repeat(160)}…`);
    expect(aboutOf(discussion({ path: "a.ts", line: 1, remarks: [] }))).toBeNull();
  });
});

describe("the rows of a file", () => {
  const file = only(MODIFIED);

  test("are its hunks and lines, with a comment under its line", () => {
    const on = comment({ path: "src/app.ts", line: 2, body: "Why 3?" });
    const [entry] = reviewFiles([file], [on], []);
    if (!entry) throw new Error("expected a file");
    const rows = fileRows(entry, 40);
    expect(texts(rows)).toEqual([
      "const a = 1;",
      "const b = 2;",
      "const b = 3;",
      "> Why 3?",
      "const c = 4;",
      "return a;",
      "}",
      "15 unchanged lines",
      "old",
      "new",
    ]);
    const commented = rows.filter((row) => row.kind === "line" && row.commented).map((row) => row.key);
    expect(commented).toEqual([lineKey(on)]);
    expect(new Set(rows.map((row) => row.key)).size).toBe(rows.length);
    expect(widest(rows)).toBe("const a = 1;".length);
  });

  test("start with the cards whose line is not in the diff", () => {
    const [entry] = reviewFiles([file], [comment({ path: "src/app.ts", line: 99, body: "Old." })], []);
    if (!entry) throw new Error("expected a file");
    const [first] = fileRows(entry, 60);
    expect(first).toMatchObject({ kind: "card", from: "draft", stale: true });
    expect(texts([first as Row])).toEqual(["> Line 99, which is not in the diff: / Old."]);
  });

  test("say over an answer that it is a reply on GitHub too", () => {
    const card = (post: About["post"]) => {
      const answer = comment({ path: "src/app.ts", line: 3, body: "Good point.", about: { ...ABOUT, post } });
      const [entry] = reviewFiles([file], [answer], []);
      if (!entry) throw new Error("expected a file");
      return texts(fileRows(entry, 60).filter((row) => row.kind === "card"));
    };
    expect(card("none")).toEqual(["> Good point."]);
    expect(card("due")).toEqual(["> A reply on GitHub too, when you send the review: / Good point."]);
    expect(card("done")).toEqual(["> Posted on GitHub: / Good point."]);
  });

  test("mark each line of a discussion on several lines, and say its lines on its card", () => {
    const talk = discussion({ path: "src/app.ts", line: 4, start: { side: "old", line: 2 } });
    const [entry] = reviewFiles([file], [comment({ path: "src/app.ts", line: 1 })], [talk]);
    if (!entry) throw new Error("expected a file");
    const rows = fileRows(entry, 60);
    const marks = rows.flatMap((row) => (row.kind === "line" ? [`${row.text} ${row.commented} ${row.discussed}`] : []));
    expect(marks.slice(0, 6)).toEqual([
      "const a = 1; true false",
      "const b = 2; false true",
      "const b = 3; false true",
      "const c = 4; false true",
      "return a; false true",
      "} false false",
    ]);
    const card = rows.find((row) => row.kind === "card" && row.from === "github");
    expect(texts(card ? [card] : [])).toEqual(["> On lines 2-4: / @ana on GitHub / Rename this."]);
  });

  test("show a discussion on GitHub under its line, before the person's answer", () => {
    const remarks = [
      { author: "ana", body: "Rename this.", url: "https://example.test/pull/7#r1" },
      {
        author: "bo",
        body: Array.from({ length: MAX_REMARK_LINES + 3 }, (_, index) => `line ${index}`).join("\n"),
        url: "u",
      },
    ];
    const talk = discussion({ path: "src/app.ts", line: 3, remarks });
    const answer = comment({ path: "src/app.ts", line: 3, body: "Address this comment." });
    const [entry] = reviewFiles([file], [answer], [talk, discussion({ path: "src/app.ts", line: 3 })]);
    if (!entry) throw new Error("expected a file");
    const rows = fileRows(entry, 60);
    const at = rows.findIndex((row) => row.key === lineKey(talk));
    const under = rows.slice(at + 1, at + 4);
    expect(under.map((row) => (row.kind === "card" ? row.from : row.kind))).toEqual(["github", "github", "draft"]);
    const [first] = under;
    if (first?.kind !== "card") throw new Error("expected a card");
    expect(first.lines.filter((line) => line.head).map((line) => line.text)).toEqual([
      "@ana on GitHub",
      "@bo on GitHub",
    ]);
    expect(first.lines).toHaveLength(2 + 1 + MAX_REMARK_LINES + 1);
    expect(first.lines.at(-1)?.text).toBe("…");
    expect(new Set(rows.map((row) => row.key)).size).toBe(rows.length);
  });

  test("keep a file that only has comments or discussions left, after the files of the diff", () => {
    const files = reviewFiles(
      [file],
      [comment({ path: "gone.ts", line: 4 })],
      [discussion({ path: "old.ts", line: 8 })],
    );
    expect(
      files.map((entry) => [entry.file.path, entry.gone, entry.comments.length, entry.discussions.length]),
    ).toEqual([
      ["src/app.ts", false, 0, 0],
      ["gone.ts", true, 1, 0],
      ["old.ts", true, 0, 1],
    ]);
    const [, gone, old] = files;
    if (!gone || !old) throw new Error("expected three files");
    expect(texts(fileRows(gone, 60))).toEqual([
      "> Line 4, which is not in the diff: / Fix this.",
      "This file is no longer in the diff.",
    ]);
    expect(texts(fileRows(old, 60))[0]).toBe("> Line 8, which is not in the diff: / @ana on GitHub / Rename this.");
  });

  test("say how many lines the branch did not change lie over a hunk", () => {
    const hunk = (header: string) => ({ header, lines: [] });
    expect(unchangedBefore(file.hunks)).toEqual([0, 15]);
    expect(unchangedBefore([hunk("@@ -8,3 +8,4 @@ fn"), hunk("@@ -20 +21 @@"), hunk("@@ -40,2 +41,0 @@")])).toEqual([
      7, 9, 20,
    ]);
    expect(unchangedBefore([hunk("@@ -0,0 +1,3 @@")])).toEqual([0]);
    expect(unchangedBefore([])).toEqual([]);
  });

  test("say why a file has no line to show", () => {
    const rowsOf = (text: string) =>
      texts(fileRows({ file: only(text), comments: [], discussions: [], gone: false }, 60));
    expect(rowsOf(BINARY)).toEqual(["A binary file: it has no text to show."]);
    expect(rowsOf(RENAMED)).toEqual(["No line of this file changed."]);
  });

  test("stop after the first lines of a long diff", () => {
    const lines = Array.from({ length: MAX_LINES + 10 }, (_, index) => `+line ${index}`).join("\n");
    const long = only(
      `diff --git a/big.txt b/big.txt\n--- /dev/null\n+++ b/big.txt\n@@ -0,0 +1,${MAX_LINES + 10} @@\n${lines}\n`,
    );
    const rows = fileRows({ file: long, comments: [], discussions: [], gone: false }, 60);
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
    expect(untab("a\t\tb\tc\t")).toBe("a       b   c   ");
    expect(untab("no tab here")).toBe("no tab here");
    expect(untab("")).toBe("");
  });
});

describe("a comment on several lines", () => {
  const file = only(MODIFIED);
  const rows = fileRows({ file, comments: [], discussions: [], gone: false }, 60);
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
    const [entry] = reviewFiles([file], [comment({ ...span, body: "Too long." })], []);
    if (!entry) throw new Error("expected a file");
    const drawn = fileRows(entry, 60);
    expect(drawn.filter((row) => row.kind === "line" && row.commented).map((row) => row.key)).toEqual(
      [at("new", 2), at("new", 3), at("new", 4)].map(lineKey),
    );
    const card = drawn.findIndex((row) => row.kind === "card");
    expect(drawn[card - 1]?.key).toBe(lineKey(at("new", 4)));
  });

  test("is told to the thread with its lines and their text", () => {
    const span = spanBetween(rows, at("new", 2), at("new", 3));
    const code = quoteOf(spanRows(rows, span));
    const draft = withComment(NO_DRAFT, span, { code, body: "One name for both.", about: null });
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
    const quote = quoteOf(
      spanRows(fileRows({ file: long, comments: [], discussions: [], gone: false }, 60), all),
    ).split("\n");
    expect(quote).toHaveLength(13);
    expect(quote.at(-1)).toBe("…");
  });
});

describe("the lines a comment is written on", () => {
  const file = only(MODIFIED);
  const at = (side: "old" | "new", line: number): Anchor => ({ path: "src/app.ts", side, line });
  const said = [
    comment({ path: "src/app.ts", line: 3, start: { side: "new", line: 2 }, code: "two lines", body: "Why?" }),
  ];
  const [entry] = reviewFiles([file], said, [discussion({ path: "src/app.ts", line: 4 })]);
  if (!entry) throw new Error("expected a file");
  const rows = fileRows(entry, 60);

  test("open from a line or from a card under it, and from no other row", () => {
    const kinds = rows.filter(isPickable).map((row) => row.kind);
    expect(new Set(kinds)).toEqual(new Set(["line", "card"]));
    expect(rows.some((row) => row.kind === "hunk" && isPickable(row))).toBe(false);
    expect(isPickable(undefined)).toBe(false);
  });

  test("are one line with its text, for a line without a comment", () => {
    expect(targetAt(rows, at("new", 4), undefined, ABOUT)).toEqual({
      anchor: { ...at("new", 4), start: null },
      pivot: at("new", 4),
      code: "return a;",
      written: false,
      about: ABOUT,
    });
    expect(targetAt(rows, at("new", 90), undefined, null).code).toBe("");
  });

  test("are the lines of the comment that ends there, with the text it quoted", () => {
    const [written] = said;
    const target = targetAt(rows, at("new", 3), written, null);
    expect(target).toMatchObject({ pivot: at("new", 3), code: "two lines", written: true, about: null });
    expect(target.anchor).toMatchObject({ ...at("new", 3), start: { side: "new", line: 2 } });
  });

  test("are named by their file, their numbers and what they answer", () => {
    const one = targetAt(rows, at("new", 4), undefined, null);
    expect(whereOf(one)).toBe("app.ts · Line 4");
    expect(whereOf(targetAt(rows, at("old", 2), undefined, null))).toBe("app.ts · Line 2, which the branch removes");
    expect(whereOf(targetAt(rows, at("new", 3), said[0], null))).toBe("app.ts · Lines 2-3");
    expect(whereOf({ ...one, about: ABOUT })).toBe("app.ts · Line 4 · in answer to @ana on GitHub");
  });
});

describe("the tree of a review's files", () => {
  const entry = (path: string): ReviewFile => ({
    file: { ...only(MODIFIED), path },
    comments: [],
    discussions: [],
    gone: false,
  });
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

  test("keeps the files whose path has what is typed in the filter", () => {
    const paths = (typed: string) => filterFiles(files, typed).map((file) => file.file.path);
    expect(paths("MODS")).toEqual(["config/app/mods/a.ts", "config/app/mods/src/b.ts"]);
    expect(paths("  ")).toHaveLength(files.length);
    expect(paths("nope")).toEqual([]);
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

  test("gives the files in the order it lists them, whatever is folded", () => {
    expect(inTreeOrder(files).map((file) => file.file.path)).toEqual([
      "config/app/mods/src/b.ts",
      "config/app/mods/a.ts",
      "config/app/x.ts",
      "docs/guide/one.md",
      "README.md",
    ]);
    expect(inTreeOrder([])).toEqual([]);
    expect(fileTree([], new Set())).toEqual([]);
  });
});

describe("the review's files in one scroll", () => {
  const entry = (path: string): ReviewFile => ({
    file: { ...only(MODIFIED), path },
    comments: [],
    discussions: [],
    gone: false,
  });
  const files = [entry("a.ts"), entry("b.ts"), { ...entry("gone.ts"), file: { ...only(BINARY), path: "gone.ts" } }];
  const build = (some: readonly ReviewFile[], columns: number, round: number) =>
    new Map(
      some.map((file) => [
        file.file.path,
        { signature: builtFrom(file, columns, round), rows: fileRows(file, columns) },
      ]),
    );
  const built = build(files, 60, 1);
  const rows = assemble(files, built);

  test("are one list: each file's opening row, then its own rows, with a key of its own for every row", () => {
    const opens = rows.flatMap((row, index) => (row.kind === "file" ? [`${index} ${row.entry.file.path}`] : []));
    expect(opens).toEqual(["0 a.ts", "10 b.ts", "20 gone.ts"]);
    expect(rows.map((row) => row.key)).toContain(fileKey("b.ts"));
    expect(new Set(rows.map((row) => row.key)).size).toBe(rows.length);
    expect(assemble([], built)).toEqual([]);
  });

  test("show a file that is not built yet by its opening row alone", () => {
    const some = assemble(files, build(files.slice(0, 1), 60, 1));
    expect(some.map((row) => row.kind).slice(9)).toEqual(["line", "file", "file"]);
  });

  test("are built again for a file when what is said about it changes, or the read it is of", () => {
    const stale = (some: readonly ReviewFile[], columns: number, round: number) =>
      staleFiles(some, built, columns, round).map((file) => file.file.path);
    expect(stale(files, 60, 1)).toEqual([]);
    expect(stale(files, 60, 2)).toEqual(["a.ts", "b.ts", "gone.ts"]);
    expect(stale([...files, entry("new.ts")], 60, 1)).toEqual(["new.ts"]);
    const said = { ...entry("b.ts"), comments: [comment({ path: "b.ts", line: 2 })] };
    expect(stale([entry("a.ts"), said], 60, 1)).toEqual(["b.ts"]);
    // Only a file with a card is cut to the width.
    expect(stale(files, 90, 1)).toEqual([]);
    const withCard = build([said], 60, 1);
    expect(staleFiles([said], withCard, 60, 1)).toEqual([]);
    expect(staleFiles([said], withCard, 90, 1)).toEqual([said]);
  });

  test("ask the list for the row that brings a file's head to the top", () => {
    // Ten rows of 20: a screen of 60 shows three of them.
    const heights = Array.from({ length: 10 }, () => 20);
    const tops = offsets(heights);
    const row = (head: number, scrolled: number) => rowToReveal(tops, heights, head, scrolled, 60);
    // A head over the screen comes to the top by itself.
    expect(row(2, 100)).toBe(2);
    expect(row(2, 40)).toBe(2);
    // A head on screen or under it: the last row of the screen that starts at the head.
    expect(row(2, 0)).toBe(4);
    expect(row(5, 0)).toBe(7);
    // Near the end there are fewer rows than a screen.
    expect(row(8, 0)).toBe(9);
    expect(row(9, 0)).toBe(9);
  });

  test("say which file is on show for how far the list is scrolled", () => {
    const tops = offsets(rows.map((row) => (row.kind === "file" ? 40 : 20)));
    expect(tops.slice(0, 3)).toEqual([0, 40, 60]);
    const starts = fileStarts(rows, tops);
    expect(starts).toEqual([
      { path: "a.ts", top: 0 },
      { path: "b.ts", top: 40 + 9 * 20 },
      { path: "gone.ts", top: 2 * (40 + 9 * 20) },
    ]);
    expect(fileAt(starts, 0)).toBe("a.ts");
    expect(fileAt(starts, 219)).toBe("a.ts");
    expect(fileAt(starts, 220)).toBe("b.ts");
    expect(fileAt(starts, 100_000)).toBe("gone.ts");
    expect(fileAt(starts.slice(1), 0)).toBe("b.ts");
    expect(fileAt([], 0)).toBeNull();
  });
});
