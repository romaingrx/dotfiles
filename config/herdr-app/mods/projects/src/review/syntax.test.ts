import { describe, expect, test } from "bun:test";
import { grammarOf, tokens } from "./syntax";

/** The pieces of a line of a file, as `kind:text` words; a plain piece is its text alone. */
function pieces(path: string, line: string): string[] {
  return tokens(line, grammarOf(path)).map((token) =>
    token.kind === "plain" ? token.text : `${token.kind}:${token.text}`,
  );
}

describe("the colors of a line of code", () => {
  test("tell the language's words, names, strings, numbers and comments apart", () => {
    expect(pieces("a.ts", `  const total = sum(items, 42); // all of them`)).toEqual([
      "keyword:  const",
      " total =",
      "function: sum",
      "(items,",
      "number: 42",
      ");",
      "comment: // all of them",
    ]);
    expect(pieces("a.ts", `export class Review implements Part {`)).toEqual([
      "keyword:export class",
      "type: Review",
      "keyword: implements",
      "type: Part",
      " {",
    ]);
    expect(pieces("a.ts", "return value === null ? `none` : 'some';")).toEqual([
      "keyword:return",
      " value ===",
      "constant: null",
      " ?",
      "string: `none`",
      " :",
      "string: 'some'",
      ";",
    ]);
  });

  test("keep every character of the line, in order", () => {
    const lines = [`  if (a) { return "x\\"y"; }  `, "\tlet x = 1;", "   ", "", `const s = "not closed`, "a // b // c"];
    for (const line of lines) {
      expect(
        tokens(line, grammarOf("a.ts"))
          .map((token) => token.text)
          .join(""),
      ).toBe(line);
    }
  });

  test("read a string to its closing quote, and a comment mark inside it as a part of it", () => {
    expect(pieces("a.ts", `const url = "http://example.test"; // home`)).toEqual([
      "keyword:const",
      " url =",
      `string: "http://example.test"`,
      ";",
      "comment: // home",
    ]);
    expect(pieces("a.ts", `say("a \\" b")`)).toEqual(["function:say", "(", `string:"a \\" b"`, ")"]);
  });

  test("take a line of a comment of several lines as a comment", () => {
    expect(pieces("a.ts", "  /** The rows of a file. */")).toEqual(["comment:  /** The rows of a file. */"]);
    expect(pieces("a.ts", "   * and its second line")).toEqual(["comment:   * and its second line"]);
  });

  test("know languages with # comments, where a # inside a word is no comment", () => {
    expect(pieces("a.py", "def area(self):  # of the shape")).toEqual([
      "keyword:def",
      "function: area",
      "(self):",
      "comment:  # of the shape",
    ]);
    expect(pieces("a.sh", `echo "$#" a#b`)).toEqual(["echo", `string: "$#"`, " a#b"]);
    expect(pieces("flake.nix", "  inherit pkgs; # all")).toEqual(["keyword:  inherit", " pkgs;", "comment: # all"]);
  });

  test("color the strings and the constants of data, and nothing else", () => {
    expect(pieces("a.json", `  "place": "none", "size": 320, "on": true`)).toEqual([
      `string:  "place"`,
      ":",
      `string: "none"`,
      ",",
      `string: "size"`,
      ":",
      "number: 320",
      ",",
      `string: "on"`,
      ":",
      "constant: true",
    ]);
  });

  test("leave a file they do not know, and a very long line, plain", () => {
    expect(pieces("notes.md", "const a = 1; // not code here")).toEqual(["const a = 1; // not code here"]);
    expect(pieces("Makefile", "all: build")).toEqual(["all: build"]);
    const long = `const a = "${"x".repeat(500)}";`;
    expect(pieces("a.ts", long)).toEqual([long]);
    expect(grammarOf("A.TS")).toBe(grammarOf("a.ts"));
    expect(grammarOf("noextension")).toBeNull();
  });
});
