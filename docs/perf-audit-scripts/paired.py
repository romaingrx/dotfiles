#!/usr/bin/env python3
"""Paired-difference analysis of the alternating top A/B.

Absolute system load drifts far more between windows than the effect size (pair 1
ORIGINAL was 228.6% of one core, pair 2 was 289.6% — 61 points of drift against a
~15 point signal). Absolute means are therefore useless here. Each pair measures
ORIGINAL and FIXED close together in time, so the PAIRED DIFFERENCE cancels the
drift, and that is the only valid statistic.

Reports mean paired delta, spread, and a paired t-statistic so the claim can be
stated with the right amount of confidence rather than the convenient amount.
"""
import re
import statistics
import sys

txt = open(sys.argv[1]).read()
orig = [float(x) for x in re.findall(r"ORIGINAL config : ([\d.]+)%", txt)]
fixed = [float(x) for x in re.findall(r"FIXED    config : ([\d.]+)%", txt)]
n = min(len(orig), len(fixed))
orig, fixed = orig[:n], fixed[:n]
deltas = [f - o for o, f in zip(orig, fixed)]

print(f"### Paired analysis, n={n} pairs (% of ONE core)\n")
print(f"{'pair':<6}{'ORIGINAL':>11}{'FIXED':>11}{'delta':>10}")
for i, (o, f, d) in enumerate(zip(orig, fixed, deltas), 1):
    print(f"{i:<6}{o:11.2f}{f:11.2f}{d:+10.2f}")

print()
print(f"  absolute ORIGINAL: mean {statistics.mean(orig):7.2f}"
      f"  spread {max(orig) - min(orig):6.2f}   <- drift dwarfs the effect")
print(f"  PAIRED DELTA     : mean {statistics.mean(deltas):+7.2f}"
      f"  spread {max(deltas) - min(deltas):6.2f}   <- drift cancels")

if n >= 2:
    sd = statistics.stdev(deltas)
    se = sd / (n ** 0.5)
    t = statistics.mean(deltas) / se if se else float("inf")
    print(f"  sd {sd:.2f}, se {se:.2f}, paired t = {t:+.2f}")
    print()
    allneg = all(d < 0 for d in deltas)
    if allneg and abs(t) > 4:
        v = "CONFIRMED — every pair negative, effect well clear of the noise"
    elif allneg and abs(t) > 2:
        v = "SUPPORTED — every pair negative, but n=3; treat magnitude as approximate"
    elif allneg:
        v = "SUGGESTIVE — direction consistent, magnitude not resolved at this n"
    else:
        v = "NOT RESOLVED — pairs disagree in sign; drift exceeds the effect"
    print(f"  VERDICT: {v}")
    print(f"  os.times()+ps A/B predicted: -16.33 (11.87 forks + 4.46 induced daemons)")
