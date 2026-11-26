/** Drops the status glyph or spinner an agent puts before its title or its message. */
export function stripGlyph(text: string): string {
  return text.replace(/^[^\p{L}\p{N}\p{Ps}\p{Pi}]+/u, "").trim();
}
