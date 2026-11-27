# Subtract Before You Add

Apply when sequencing an addition, refactor, or rewrite. Remove dead code, redundant validators, and stub references first, then build on the simpler base.

When evolving a system, remove complexity first, then build. Default to subtraction.

Make simplification a continual investment. Leave the design slightly simpler and more capable behind the same or smaller surface than you found it.

- Sequence removal before construction
- Cut before you polish (get to the minimum before investing in quality)
- Design for observed usage, not speculative edge cases
- No speculative validators, parsers, or guards beyond what the spec demands
- Simplify prompts (remove redundant instructions, excessive templates)
- When a reference has no novel content, delete it rather than leaving a stub
- Minimize the diff. Make the smallest change that solves the problem. Fewer lines beat "elegant" boilerplate

For the full treatment, use the `ponytail` skill (laziest working solution) and the `ponytail-review` skill (over-engineering review).

You skipped this when your diff adds lines to an area that still holds dead code, unused guards, or stub references you could have deleted first.
