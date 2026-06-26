{ pkgs, repoRoot, ... }:
let
  inherit (pkgs) lib;

  colors = import (repoRoot + "/lib/theme/colors.nix") { };
  theme = import (repoRoot + "/lib/theme") { };

  # ---------------------------------------------------------------------------
  # lib/theme/colors.nix unit tests
  #
  # PR changes: removed hexToRgbList, the `rgb` field on mkColor output, and
  # the `hexRaw` / `rgbTuple` format helpers.  The remaining surface –
  # mkColor, format.hex, format.hyprRgb, format.hyprRgba, format.argb – must
  # continue to work correctly.
  # ---------------------------------------------------------------------------

  redColor = colors.mkColor "ff0000";
  whiteColor = colors.mkColor "ffffff";
  blackColor = colors.mkColor "000000";

  colorTests = lib.runTests {
    # mkColor – retained fields
    testMkColorHexField = {
      expr = redColor.hex;
      expected = "ff0000";
    };

    testMkColorHashField = {
      expr = redColor.hash;
      expected = "#ff0000";
    };

    testMkColorHexAndHashConsistent = {
      expr = "#${redColor.hex}";
      expected = redColor.hash;
    };

    testMkColorWhite = {
      expr = whiteColor.hash;
      expected = "#ffffff";
    };

    testMkColorBlack = {
      expr = blackColor.hash;
      expected = "#000000";
    };

    # mkColor – rgb field must NOT be present (regression: was removed in PR)
    testMkColorNoRgbField = {
      expr = redColor ? rgb;
      expected = false;
    };

    # format.hex
    testFormatHex = {
      expr = colors.format.hex redColor;
      expected = "#ff0000";
    };

    testFormatHexWhite = {
      expr = colors.format.hex whiteColor;
      expected = "#ffffff";
    };

    # format.hyprRgb
    testFormatHyprRgb = {
      expr = colors.format.hyprRgb redColor;
      expected = "rgb(ff0000)";
    };

    testFormatHyprRgbBlack = {
      expr = colors.format.hyprRgb blackColor;
      expected = "rgb(000000)";
    };

    # format.hyprRgba
    testFormatHyprRgba = {
      expr = colors.format.hyprRgba redColor "ff";
      expected = "rgba(ff0000ff)";
    };

    testFormatHyprRgbaTransparent = {
      expr = colors.format.hyprRgba redColor "00";
      expected = "rgba(ff000000)";
    };

    testFormatHyprRgbaPartialAlpha = {
      expr = colors.format.hyprRgba redColor "80";
      expected = "rgba(ff000080)";
    };

    # format.argb – macOS color format 0xAARRGGBB (jankyborders, SketchyBar)
    testFormatArgbOpaque = {
      expr = colors.format.argb redColor "ff";
      expected = "0xffff0000";
    };

    testFormatArgbTransparent = {
      expr = colors.format.argb blackColor "00";
      expected = "0x00000000";
    };

    testFormatArgbWhiteOpaque = {
      expr = colors.format.argb whiteColor "ff";
      expected = "0xffffffff";
    };

    # Removed format helpers must NOT be present (regression: removed in PR)
    testFormatNoHexRaw = {
      expr = colors.format ? hexRaw;
      expected = false;
    };

    testFormatNoRgbTuple = {
      expr = colors.format ? rgbTuple;
      expected = false;
    };

    # format attrset must contain exactly the four retained helpers
    testFormatAttrNames = {
      expr = builtins.attrNames colors.format;
      expected = [
        "argb"
        "hex"
        "hyprRgb"
        "hyprRgba"
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # lib/theme/default.nix unit tests
  #
  # PR changes: removed `colors`, `mkTheme`, `palettes`, and `format` from the
  # public exports.  Only `appearances`, `fonts`, and `appearanceNames` remain.
  # ---------------------------------------------------------------------------

  themeTests = lib.runTests {
    # Retained exports
    testThemeHasAppearances = {
      expr = theme ? appearances;
      expected = true;
    };

    testThemeHasFonts = {
      expr = theme ? fonts;
      expected = true;
    };

    testThemeHasAppearanceNames = {
      expr = theme ? appearanceNames;
      expected = true;
    };

    # appearances must contain exactly the dark and light variants
    testThemeAppearancesHasDark = {
      expr = theme.appearances ? dark;
      expected = true;
    };

    testThemeAppearancesHasLight = {
      expr = theme.appearances ? light;
      expected = true;
    };

    testThemeAppearanceNamesContainsDark = {
      expr = builtins.elem "dark" theme.appearanceNames;
      expected = true;
    };

    testThemeAppearanceNamesContainsLight = {
      expr = builtins.elem "light" theme.appearanceNames;
      expected = true;
    };

    testThemeAppearanceNamesLength = {
      expr = builtins.length theme.appearanceNames;
      expected = 2;
    };

    # Removed exports must NOT be present (regressions for removals in PR)
    testThemeNoColors = {
      expr = theme ? colors;
      expected = false;
    };

    testThemeNoMkTheme = {
      expr = theme ? mkTheme;
      expected = false;
    };

    testThemeNoPalettes = {
      expr = theme ? palettes;
      expected = false;
    };

    testThemeNoFormat = {
      expr = theme ? format;
      expected = false;
    };

    # The public surface must have exactly three keys
    testThemeAttrNames = {
      expr = builtins.sort builtins.lessThan (builtins.attrNames theme);
      expected = [
        "appearanceNames"
        "appearances"
        "fonts"
      ];
    };
  };

  # ---------------------------------------------------------------------------
  # lib/mkFileWatcher.nix unit tests (Linux-only)
  #
  # PR changes: removed initialLaunch, enabled, wantedBy, after, requires, and
  # environment parameters; the output is now always Linux-only via
  # lib.mkIf pkgs.stdenv.isLinux; WantedBy and After are hardcoded to
  # graphical-session.target; Environment is now a simple PATH list.
  # ---------------------------------------------------------------------------

  mockConfig = {
    home = {
      profileDirectory = "/home/testuser/.nix-profile";
      username = "testuser";
    };
  };

  mkFileWatcher = import (repoRoot + "/lib/mkFileWatcher.nix") {
    inherit lib pkgs;
    config = mockConfig;
  };

  # lib.mkIf returns { _type = "if"; condition = <bool>; content = <value>; }.
  # Accessing .content gives the actual attrset without going through the
  # module system.
  watcherResult = mkFileWatcher {
    name = "testwatch";
    serviceName = "test-svc";
    restartCommand = "echo restart-test";
    watchPaths = [ "/tmp/watch-me" ];
  };

  watcherResultRecursive = mkFileWatcher {
    name = "rwatch";
    serviceName = "rsvc";
    restartCommand = "echo r";
    watchPaths = [
      "/tmp/a"
      "/tmp/b"
    ];
    recursive = true;
    debounceMs = 200;
    description = "custom description";
  };

  watcherResultNonRecursive = mkFileWatcher {
    name = "nrwatch";
    serviceName = "nrsvc";
    restartCommand = "echo nr";
    watchPaths = [ "/tmp/c" ];
    recursive = false;
  };

  # Structural (eval-time) tests – no file reads, no IFD.
  fileWatcherStructuralTests =
    lib.optionals pkgs.stdenv.isLinux
      (
        let
          svcConfig = watcherResult.content.systemd.user.services."testwatch-watcher";
          rSvcConfig = watcherResultRecursive.content.systemd.user.services."rwatch-watcher";
        in
        lib.runTests {
          # Unit description defaults to "${serviceName} file watcher"
          testServiceDefaultDescription = {
            expr = svcConfig.Unit.Description;
            expected = "test-svc file watcher";
          };

          testServiceCustomDescription = {
            expr = rSvcConfig.Unit.Description;
            expected = "custom description";
          };

          # After is hardcoded to graphical-session.target (no longer configurable)
          testServiceAfterTarget = {
            expr = svcConfig.Unit.After;
            expected = [ "graphical-session.target" ];
          };

          # WantedBy is hardcoded to graphical-session.target (no longer configurable)
          testServiceWantedBy = {
            expr = svcConfig.Install.WantedBy;
            expected = [ "graphical-session.target" ];
          };

          testServiceType = {
            expr = svcConfig.Service.Type;
            expected = "simple";
          };

          testServiceRestart = {
            expr = svcConfig.Service.Restart;
            expected = "always";
          };

          testServiceRestartSec = {
            expr = svcConfig.Service.RestartSec;
            expected = 3;
          };

          # Environment is now a simple list (was an attrset in old code)
          testServiceEnvironmentIsList = {
            expr = builtins.isList svcConfig.Service.Environment;
            expected = true;
          };

          testServiceEnvironmentLength = {
            expr = builtins.length svcConfig.Service.Environment;
            expected = 1;
          };

          testServiceEnvironmentStartsWithPath = {
            expr = lib.hasPrefix "PATH=" (builtins.head svcConfig.Service.Environment);
            expected = true;
          };

          # PATH must include the profile directory from config.home.profileDirectory
          testServiceEnvironmentIncludesProfileDir = {
            expr = lib.hasInfix mockConfig.home.profileDirectory (builtins.head svcConfig.Service.Environment);
            expected = true;
          };

          # PATH must include the per-user profile path that embeds config.home.username
          testServiceEnvironmentIncludesUsername = {
            expr = lib.hasInfix mockConfig.home.username (builtins.head svcConfig.Service.Environment);
            expected = true;
          };

          # ExecStart must be a non-empty string (the store path of the watcher script)
          testServiceExecStartNonEmpty = {
            expr = svcConfig.Service.ExecStart != "";
            expected = true;
          };

          # Removed parameters – passing them must be rejected at eval time.
          # builtins.tryEval catches unexpected-argument errors.
          testRemovedParamInitialLaunch = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              initialLaunch = true;
            })).success;
            expected = false;
          };

          testRemovedParamEnabled = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              enabled = false;
            })).success;
            expected = false;
          };

          testRemovedParamWantedBy = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              wantedBy = [ "default.target" ];
            })).success;
            expected = false;
          };

          testRemovedParamAfter = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              after = [ "default.target" ];
            })).success;
            expected = false;
          };

          testRemovedParamRequires = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              requires = [ "foo.service" ];
            })).success;
            expected = false;
          };

          testRemovedParamEnvironment = {
            expr = (builtins.tryEval (mkFileWatcher {
              name = "x";
              serviceName = "y";
              restartCommand = "z";
              watchPaths = [ "/tmp" ];
              environment = {
                FOO = "bar";
              };
            })).success;
            expected = false;
          };
        }
      );

  # ---------------------------------------------------------------------------
  # Build helper: convert lib.runTests results into a pkgs.runCommand check.
  # Failures are embedded in the shell script at eval time; if any test
  # failed, the runCommand exits 1 immediately at build time.
  # ---------------------------------------------------------------------------

  mkCheck =
    name: results:
    let
      failMsg =
        lib.concatMapStringsSep "\n" (
          t: "  FAIL ${t.name}: got ${builtins.toJSON t.result}, expected ${builtins.toJSON t.expected}"
        ) results;
    in
    pkgs.runCommand name { } (
      if results == [ ] then
        ''echo "${name}: all tests passed" && touch "$out"''
      else
        ''
          echo "=== ${name} FAILURES ==="
          printf '%s\n' ${lib.escapeShellArg failMsg}
          exit 1
        ''
    );

in
{
  lib-colors-unit = mkCheck "lib-colors-unit" colorTests;
  lib-theme-default-unit = mkCheck "lib-theme-default-unit" themeTests;
}
# Script-content checks and structural checks are Linux-only (inotify / systemd).
// lib.optionalAttrs pkgs.stdenv.isLinux {
  lib-mkFileWatcher-unit = mkCheck "lib-mkFileWatcher-unit" fileWatcherStructuralTests;

  # Build-time script content checks (grep inside pkgs.runCommand to avoid IFD).
  lib-mkFileWatcher-script =
    let
      svcConfig = watcherResult.content.systemd.user.services."testwatch-watcher";
      rSvcConfig = watcherResultRecursive.content.systemd.user.services."rwatch-watcher";
      nrSvcConfig = watcherResultNonRecursive.content.systemd.user.services."nrwatch-watcher";
    in
    pkgs.runCommand "lib-mkFileWatcher-script"
      { nativeBuildInputs = [ pkgs.gnugrep ]; }
      ''
        # Default debounce is 500 ms
        grep -q 'sleep 0\.500' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: default debounce 500 ms not found in script"; exit 1; }

        # Custom debounce (200 ms) appears in the recursive watcher script
        grep -q 'sleep 0\.200' ${rSvcConfig.Service.ExecStart} \
          || { echo "FAIL: custom debounce 200 ms not found in recursive script"; exit 1; }

        # Recursive flag (-r) is present in the recursive watcher
        grep -q 'inotifywait -r' ${rSvcConfig.Service.ExecStart} \
          || { echo "FAIL: -r flag not found in recursive script"; exit 1; }

        # Non-recursive watcher must NOT contain -r
        grep -q 'inotifywait -r' ${nrSvcConfig.Service.ExecStart} \
          && { echo "FAIL: -r flag unexpectedly found in non-recursive script"; exit 1; } \
          || true

        # restartCommand appears verbatim in the script
        grep -q 'echo restart-test' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: restartCommand not found in script"; exit 1; }

        # watchPath appears in the script
        grep -q '/tmp/watch-me' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: watchPath /tmp/watch-me not found in script"; exit 1; }

        # serviceName appears in the script (used in echo messages)
        grep -q 'test-svc' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: serviceName test-svc not found in script"; exit 1; }

        # Default event list includes create,modify,delete,moved_to
        grep -q 'create,modify,delete,moved_to' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: default watch events not found in script"; exit 1; }

        # SIGTERM / SIGINT trap is present for graceful shutdown
        grep -q 'trap cleanup SIGTERM SIGINT' ${svcConfig.Service.ExecStart} \
          || { echo "FAIL: signal trap not found in script"; exit 1; }

        echo "lib-mkFileWatcher-script: all script-content checks passed"
        touch "$out"
      '';
}