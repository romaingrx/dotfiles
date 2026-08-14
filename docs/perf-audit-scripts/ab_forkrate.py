#!/usr/bin/env python3
"""A/B the two sketchybar configs by DIRECT FORK COUNT.

This is the measurement the audit's headline number actually needed. The 12.85%
figure came from os.times() child accounting; this counts the processes themselves,
via libproc proc_listallpids() sampled in-process at ~1.6 ms. Validated at 97%
capture rate against 300 injected forks.

Swaps ~/.config/sketchybar between the live config and the worktree config,
alternating, and restores under try/finally. ~/.dotfiles is never touched.

All forking done by this script (the config swap) happens during the settle period,
never inside a measurement window.
"""
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from forkcount import count_forks  # noqa: E402

HOME = os.path.expanduser("~")
LINK = f"{HOME}/.config/sketchybar"
WORKTREE = "/Users/romaingrx/.dotfiles/.claude/worktrees/perf-audit/config/sketchybar"
LABEL = "org.nixos.sketchybar"
UID = os.getuid()

ORIG = os.readlink(LINK)
WINDOW = float(sys.argv[1]) if len(sys.argv) > 1 else 30
PAIRS = int(sys.argv[2]) if len(sys.argv) > 2 else 3


def bar_is_fixed():
    out = subprocess.run(["sketchybar", "--query", "bar"], capture_output=True, text=True).stdout
    return "wifi.speed" not in out


def use(which):
    target = WORKTREE if which == "fixed" else ORIG
    os.replace_sym = None
    tmp = LINK + ".swap"
    os.symlink(target, tmp)
    os.rename(tmp, LINK)
    subprocess.run(["launchctl", "kickstart", "-k", f"gui/{UID}/{LABEL}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(10)  # settle: config reload spawns a burst, keep it out of the window
    got = "fixed" if bar_is_fixed() else "orig"
    if got != which:
        raise SystemExit(f"!! wanted {which} config, bar reports {got} — aborting")


def restore():
    print("\n=== RESTORE ===")
    try:
        tmp = LINK + ".swap"
        if os.path.islink(tmp):
            os.unlink(tmp)
        os.symlink(ORIG, tmp)
        os.rename(tmp, LINK)
        subprocess.run(["launchctl", "kickstart", "-k", f"gui/{UID}/{LABEL}"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(8)
        ok = os.readlink(LINK) == ORIG and not bar_is_fixed()
        print(f"  RESTORE {'OK — original config active (wifi.speed present)' if ok else 'PROBLEM'}"
              f", pid {subprocess.run(['pgrep', '-x', 'sketchybar'], capture_output=True, text=True).stdout.strip()}")
        if not ok:
            print(f"  !! fix with: ln -sfn '{ORIG}' '{LINK}' && launchctl kickstart -k gui/{UID}/{LABEL}")
    except Exception as e:  # noqa: BLE001
        print(f"  !! RESTORE FAILED: {e}\n  !! ln -sfn '{ORIG}' '{LINK}' && launchctl kickstart -k gui/{UID}/{LABEL}")


def main():
    print(f"### Direct fork-rate A/B — {PAIRS} alternating pairs, {WINDOW:.0f}s windows")
    print("# instrument: libproc proc_listallpids sampled in-process (never forks), 97% capture\n")
    o_rates, f_rates = [], []
    try:
        for i in range(1, PAIRS + 1):
            use("orig")
            n, el, _ = count_forks(WINDOW)
            o = n / el * 60
            o_rates.append(o)
            print(f"  pair {i}  ORIGINAL : {o:8.0f} forks/min")

            use("fixed")
            n, el, _ = count_forks(WINDOW)
            f = n / el * 60
            f_rates.append(f)
            print(f"  pair {i}  FIXED    : {f:8.0f} forks/min   (delta {f - o:+8.0f}, {(f - o) / o * 100:+5.1f}%)")
    finally:
        restore()

    if not o_rates or not f_rates:
        return
    import statistics
    om, fm = statistics.mean(o_rates), statistics.mean(f_rates)
    deltas = [f - o for o, f in zip(o_rates, f_rates)]
    dm = statistics.mean(deltas)
    print()
    print(f"  mean ORIGINAL : {om:8.0f} forks/min  (system-wide, includes non-sketchybar background)")
    print(f"  mean FIXED    : {fm:8.0f} forks/min")
    print(f"  PAIRED DELTA  : {dm:+8.0f} forks/min   ({dm / om * 100:+.1f}% of all system forks)")
    if len(deltas) > 1:
        sd = statistics.stdev(deltas)
        se = sd / len(deltas) ** 0.5
        print(f"  sd {sd:.0f}, se {se:.0f}, paired t = {dm / se:+.1f}"
              if se else "  (zero variance)")
        print(f"  all pairs same sign: {all(d < 0 for d in deltas)}")
    print()
    print("  Cross-check against the audit's os.times() cost model:")
    print("    predicted sketchybar forks/min  OLD ~1644, NEW ~140  -> delta ~-1500")
    print(f"    measured delta                  {dm:+.0f}")
    if dm:
        print(f"    implied ms of CPU per fork      {(12.85 - 0.98) / 100 * 60 * 1000 / abs(dm):.1f} ms"
              "   (audit's per-command table: bare bash fork 1.8, ps 22, scutil 24)")


if __name__ == "__main__":
    main()
