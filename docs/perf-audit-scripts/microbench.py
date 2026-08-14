#!/usr/bin/env python3
"""Micro-benchmark individual shell commands by true subtree CPU (os.times())."""
import os
import subprocess
import sys
import time

CMDS = [
    ("networksetup -listallhardwareports", ["networksetup", "-listallhardwareports"]),
    ("scutil --nc list", ["scutil", "--nc", "list"]),
    ("netstat -ibn", ["netstat", "-ibn"]),
    ("ipconfig getifaddr en0", ["ipconfig", "getifaddr", "en0"]),
    ("ps -eo pcpu,user", ["ps", "-eo", "pcpu,user"]),
    ("ps -Axo pcpu,user,ucomm", ["ps", "-Axo", "pcpu,user,ucomm"]),
    ("ps axo %cpu,ucomm", ["ps", "axo", "%cpu,ucomm"]),
    ("whoami", ["whoami"]),
    ("sysctl -n machdep.cpu.thread_count", ["sysctl", "-n", "machdep.cpu.thread_count"]),
    ("pmset -g batt", ["pmset", "-g", "batt"]),
    ("defaults read -g AppleInterfaceStyle", ["defaults", "read", "-g", "AppleInterfaceStyle"]),
    ("date +%s", ["date", "+%s"]),
    ("uname -s", ["uname", "-s"]),
    ("aerospace list-modes --current", ["/run/current-system/sw/bin/aerospace", "list-modes", "--current"]),
    ("sketchybar --set clock label=x", ["sketchybar", "--set", "clock", "label=x"]),
    ("/bin/bash -c ':'  (bare fork+exec)", ["/bin/bash", "-c", ":"]),
    ("ifconfig en0", ["ifconfig", "en0"]),
    ("system_profiler SPAirPortDataType", ["system_profiler", "SPAirPortDataType"]),
    ("wdutil info", ["wdutil", "info"]),
]

n = int(sys.argv[1]) if len(sys.argv) > 1 else 40
devnull = subprocess.DEVNULL
print(f"{'command':<44} {'ms/call':>9} {'wall_ms':>9}  note")
print("-" * 86)
for label, argv in CMDS:
    try:
        subprocess.run(argv, stdout=devnull, stderr=devnull, timeout=20)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print(f"{label:<44} {'—':>9} {'—':>9}  NOT AVAILABLE")
        continue
    reps = n if "system_profiler" not in label and "wdutil" not in label else max(3, n // 10)
    c0 = os.times()
    t0 = time.time()
    for _ in range(reps):
        subprocess.run(argv, stdout=devnull, stderr=devnull)
    t1 = time.time()
    c1 = os.times()
    sub = (c1.children_user - c0.children_user) + (c1.children_system - c0.children_system)
    print(f"{label:<44} {sub / reps * 1000:9.1f} {(t1 - t0) / reps * 1000:9.1f}  n={reps}")
