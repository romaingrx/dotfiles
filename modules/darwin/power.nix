# Display sleep.
#
# nix-darwin has no typed option for this. Its `power` module covers only
# restartAfterPowerFailure and restartAfterFreeze, and nothing anywhere in the
# tree shells out to pmset, so this goes through a postActivation script.
#
# postActivation is the correct hook: activation now runs entirely as root
# (extraUserActivation / preUserActivation / postUserActivation were removed and
# are an eval error), and /usr/bin is on the activation PATH, so pmset needs
# neither sudo nor an absolute path.
{
  system.activationScripts.postActivation.text = ''
    echo "configuring display sleep..." >&2
    # goddard was set to displaysleep=180 on BOTH power sources, against macOS
    # defaults of 2 (battery) and 10 (AC) — the panel, the single largest draw
    # on the machine, went three hours before sleeping while unattended.
    #
    # Found in the August 2026 idle-power audit; see docs/perf-audit-2026-08.md.
    # Unlike the rest of that audit these numbers are a judgement call, not a
    # measurement: the saving is real but was never quantified in milliwatts,
    # because that needs `sudo powermetrics`. Tune to taste.
    pmset -b displaysleep 5
    pmset -c displaysleep 30
  '';
}
