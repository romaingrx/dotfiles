/**
 * Colors for a line of code. Herdr colors code only in its `Editor`, which is
 * a whole view of one text and cannot be a row of the review's list. So this
 * reads one line at a time, by itself: enough to tell words of the language,
 * strings, comments, numbers and names from each other. It knows nothing of
 * the lines around it, as a diff shows a file in pieces.
 */

/** What a piece of a line is, by the names Herdr's own code view gives its colors. */
export type TokenKind = "plain" | "keyword" | "string" | "comment" | "number" | "function" | "type" | "constant";

export interface Token {
  readonly kind: TokenKind;
  readonly text: string;
}

/** How a family of languages writes its comments, its strings and its own words. */
export interface Grammar {
  /** What starts a comment that runs to the end of the line. */
  readonly lineComment: string;
  /** How a line starts that opens a comment of several lines, or is inside one. Empty for a family without them. */
  readonly blockStarts: readonly string[];
  /** The characters that open and close a string. */
  readonly quotes: string;
  readonly keywords: ReadonlySet<string>;
  readonly constants: ReadonlySet<string>;
}

function words(list: string): ReadonlySet<string> {
  return new Set(list.split(" "));
}

const CONSTANTS = words("true false null undefined nil None True False NaN Infinity");

/** Languages with `//` comments and braces: TypeScript, JavaScript, Rust, Go, Swift, Java, C and their kin. */
const BRACES: Grammar = {
  lineComment: "//",
  blockStarts: ["/*", "*"],
  quotes: "\"'`",
  keywords: words(
    "as async await break case catch class const continue default defer delete do dyn else enum export extends " +
      "finally fn for from func function go if impl implements import in instanceof interface let loop match mod mut " +
      "new of package private protected pub public readonly return static struct super switch this throw trait try " +
      "type typeof use var void where while yield",
  ),
  constants: CONSTANTS,
};

/** Languages with `#` comments: Python, shell, Ruby, Nix, YAML, TOML. */
const HASHES: Grammar = {
  lineComment: "#",
  blockStarts: [],
  quotes: "\"'",
  keywords: words(
    "and as assert async await break case class continue def del do done elif else end esac except export fi " +
      "finally for from function global if import in inherit is lambda let local module not or pass raise rec " +
      "require return then try while with yield",
  ),
  constants: CONSTANTS,
};

/** JSON has strings and constants, and neither comments nor words of its own. */
const DATA: Grammar = { lineComment: "", blockStarts: [], quotes: '"', keywords: new Set(), constants: CONSTANTS };

const FAMILIES: readonly (readonly [Grammar, string])[] = [
  [BRACES, "ts tsx mts cts js jsx mjs cjs rs go swift java kt c h cc cpp hpp cs css scss"],
  [HASHES, "py sh bash zsh fish rb nix yaml yml toml"],
  [DATA, "json jsonc"],
];

const BY_EXTENSION: ReadonlyMap<string, Grammar> = new Map(
  FAMILIES.flatMap(([grammar, extensions]) => extensions.split(" ").map((extension) => [extension, grammar] as const)),
);

/** The grammar for a file, from the end of its name; null for a file this does not color. */
export function grammarOf(path: string): Grammar | null {
  return BY_EXTENSION.get(path.slice(path.lastIndexOf(".") + 1).toLowerCase()) ?? null;
}

/** A line longer than this is shown plain: it is data more often than code, and would be many pieces. */
const LONGEST = 400;

const isSpace = (char: string): boolean => char === " " || char === "\t";
const isDigit = (char: string): boolean => char >= "0" && char <= "9";
const isUpper = (char: string): boolean => char >= "A" && char <= "Z";
const startsWord = (char: string): boolean =>
  (char >= "a" && char <= "z") || isUpper(char) || char === "_" || char === "$";
const inWord = (char: string): boolean => startsWord(char) || isDigit(char);

/** Where a run of characters ends that starts at `from` and holds while `keeps` says so. */
function runEnd(line: string, from: number, keeps: (char: string) => boolean): number {
  let end = from;
  while (end < line.length && keeps(line.charAt(end))) end++;
  return end;
}

/** Where a string ends that opens at `from`: after its closing quote, or at the end of the line. A `\` keeps the next character. */
function stringEnd(line: string, from: number): number {
  const quote = line.charAt(from);
  let at = from + 1;
  while (at < line.length && line.charAt(at) !== quote) at += line.charAt(at) === "\\" ? 2 : 1;
  return Math.min(at + 1, line.length);
}

/** True where a comment starts. A `#` counts at the start of a line or after a space: `$#` and `a#b` are no comments. */
function startsComment(line: string, at: number, grammar: Grammar): boolean {
  if (grammar.lineComment === "" || !line.startsWith(grammar.lineComment, at)) return false;
  return grammar.lineComment !== "#" || at === 0 || isSpace(line.charAt(at - 1));
}

/** What a word is: one of the language's own, a constant, a call when a `(` follows it, a type when it starts with a capital. */
function wordKind(word: string, next: string, grammar: Grammar): TokenKind {
  if (grammar.keywords.has(word)) return "keyword";
  if (grammar.constants.has(word)) return "constant";
  if (next === "(") return "function";
  return isUpper(word.charAt(0)) ? "type" : "plain";
}

/** The piece of a line that starts at `at`: what it is, and where it ends. */
function pieceAt(line: string, at: number, grammar: Grammar): { readonly kind: TokenKind; readonly end: number } {
  const char = line.charAt(at);
  if (startsComment(line, at, grammar)) return { kind: "comment", end: line.length };
  if (grammar.quotes.includes(char)) return { kind: "string", end: stringEnd(line, at) };
  if (isDigit(char)) return { kind: "number", end: runEnd(line, at, (next) => inWord(next) || next === ".") };
  if (!startsWord(char)) return { kind: "plain", end: at + 1 };
  const end = runEnd(line, at, inWord);
  return { kind: wordKind(line.slice(at, end), line.charAt(end), grammar), end };
}

/**
 * Cuts a line of code into pieces of one kind each. Spaces go with the piece
 * after them, and neighbours of one kind are one piece, so a line is few
 * pieces and none of them is only spaces, but for a line of spaces alone.
 */
export function tokens(line: string, grammar: Grammar | null): Token[] {
  if (!grammar || line.length > LONGEST) return [{ kind: "plain", text: line }];
  const start = line.trimStart();
  if (grammar.blockStarts.some((open) => start.startsWith(open))) return [{ kind: "comment", text: line }];
  const pieces: { kind: TokenKind; text: string }[] = [];
  let at = 0;
  while (at < line.length) {
    const from = at;
    at = runEnd(line, at, isSpace);
    if (at === line.length) break;
    const { kind, end } = pieceAt(line, at, grammar);
    const text = line.slice(from, end);
    const last = pieces[pieces.length - 1];
    if (last?.kind === kind) last.text += text;
    else pieces.push({ kind, text });
    at = end;
  }
  // Spaces at the end of the line belong to the last piece.
  const rest = line.slice(pieces.reduce((length, piece) => length + piece.text.length, 0));
  const last = pieces[pieces.length - 1];
  if (last) last.text += rest;
  return last ? pieces : [{ kind: "plain", text: line }];
}
