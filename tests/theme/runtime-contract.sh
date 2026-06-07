#!/usr/bin/env bash
set -euo pipefail

theme_lib="${THEME_LIB:?THEME_LIB must point to romaingrx-theme-lib}"

# shellcheck source=/dev/null
source "$theme_lib"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    fail "$message: expected '$expected', got '$actual'"
  fi
}

assert_file_contents() {
  local file="$1"
  local expected="$2"
  local actual

  actual="$(<"$file")"
  assert_eq "$expected" "$actual" "$file contents"
}

assert_symlink_target() {
  local link="$1"
  local expected="$2"
  local actual

  [[ -L "$link" ]] || fail "$link should be a symlink"
  actual="$(readlink "$link")"
  assert_eq "$expected" "$actual" "$link target"
}

# Write an executable reload hook whose body is read from stdin.
#
# Hooks are executed directly by theme_reload_consumers, so the kernel resolves
# their shebang. Inside the Nix build sandbox there is no /usr/bin/env, so we
# point the shebang at the bash interpreter actually running this test ($BASH),
# which is a valid path both in the sandbox and on a developer host.
write_hook() {
  local path="$1"
  {
    printf '#!%s\n' "$BASH"
    cat
  } > "$path"
  chmod +x "$path"
}

reset_theme_env() {
  unset \
    HOME \
    ROMAINGRX_THEME_ALACRITTY_ACTIVE_THEME \
    ROMAINGRX_THEME_CONFIG \
    ROMAINGRX_THEME_CONFIG_LOADED \
    ROMAINGRX_THEME_DEFAULT_APPEARANCE \
    ROMAINGRX_THEME_GENERATED_ROOT \
    ROMAINGRX_THEME_RELOAD_HOOK_LOG \
    ROMAINGRX_THEME_RELOAD_HOOKS_DIR \
    ROMAINGRX_THEME_RUNTIME_ROOT \
    XDG_CONFIG_HOME \
    XDG_STATE_HOME

  ROMAINGRX_THEME_RELOAD_HOOKS_DIR=/nonexistent-theme-reload-hooks
}

make_theme_home() {
  local root="$1"
  local generated_root="$root/config/romaingrx/theme/generated"

  mkdir -p "$generated_root/light" "$generated_root/dark"
  printf 'light-theme\n' > "$generated_root/light/alacritty.toml"
  printf 'dark-theme\n' > "$generated_root/dark/alacritty.toml"
}

test_first_run_bootstrap_uses_dark_default() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"

  theme_bootstrap

  assert_file_contents "$root/state/theme/appearance" "dark"
  assert_symlink_target "$root/state/theme/current" "$root/config/romaingrx/theme/generated/dark"
  assert_symlink_target "$root/home/.local/share/alacritty/active-theme.toml" "$root/state/theme/current/alacritty.toml"
  assert_file_contents "$root/home/.local/share/alacritty/active-theme.toml" "dark-theme"
}

test_sync_switches_repeatedly() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"

  theme_bootstrap
  theme_sync light
  theme_sync dark
  theme_sync light

  assert_file_contents "$root/state/theme/appearance" "light"
  assert_symlink_target "$root/state/theme/current" "$root/config/romaingrx/theme/generated/light"
  assert_symlink_target "$root/home/.local/share/alacritty/active-theme.toml" "$root/state/theme/current/alacritty.toml"
  assert_file_contents "$root/home/.local/share/alacritty/active-theme.toml" "light-theme"
}

test_paths_env_extends_runtime_contract() {
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/generated/light" "$root/generated/dark" "$root/state" "$root/alacritty"
  mkdir -p "$root/hooks"
  printf 'light-theme\n' > "$root/generated/light/alacritty.toml"
  printf 'dark-theme\n' > "$root/generated/dark/alacritty.toml"

  cat > "$root/paths.env" <<EOF
ROMAINGRX_THEME_DEFAULT_APPEARANCE='light'
ROMAINGRX_THEME_GENERATED_ROOT='$root/generated'
ROMAINGRX_THEME_RELOAD_HOOK_LOG='$root/hooks.log'
ROMAINGRX_THEME_RELOAD_HOOKS_DIR='$root/hooks'
ROMAINGRX_THEME_RUNTIME_ROOT='$root/state'
ROMAINGRX_THEME_ALACRITTY_ACTIVE_THEME='$root/alacritty/active-theme.toml'
EOF

  reset_theme_env
  HOME="$root/home"
  ROMAINGRX_THEME_CONFIG="$root/paths.env"

  theme_bootstrap

  assert_file_contents "$root/state/appearance" "light"
  assert_symlink_target "$root/state/current" "$root/generated/light"
  assert_symlink_target "$root/alacritty/active-theme.toml" "$root/state/current/alacritty.toml"
  assert_file_contents "$root/alacritty/active-theme.toml" "light-theme"
  assert_eq "$root/hooks.log" "$(theme_reload_hook_log)" "reload hook log"
  assert_eq "$root/hooks" "$(theme_reload_hooks_dir)" "reload hooks dir"
}

test_stale_current_symlink_is_repaired() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"

  mkdir -p "$root/state/theme"
  ln -s "$root/missing-theme" "$root/state/theme/current"

  theme_bootstrap_state dark

  assert_file_contents "$root/state/theme/appearance" "dark"
  assert_symlink_target "$root/state/theme/current" "$root/config/romaingrx/theme/generated/dark"
}

test_non_symlink_current_is_refused() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"

  mkdir -p "$root/state/theme"
  printf 'not a symlink\n' > "$root/state/theme/current"

  if theme_bootstrap_state dark 2> "$root/error.log"; then
    fail "theme_bootstrap_state should refuse a non-symlink current path"
  fi

  grep -q 'Refusing to replace non-symlink theme current path' "$root/error.log"
  assert_file_contents "$root/state/theme/current" "not a symlink"
}

test_missing_generated_target_is_refused() {
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/config/romaingrx/theme/generated/dark"
  printf 'dark-theme\n' > "$root/config/romaingrx/theme/generated/dark/alacritty.toml"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"

  if theme_sync light 2> "$root/error.log"; then
    fail "theme_sync should fail when the generated target is missing"
  fi

  grep -q 'Missing generated theme directory' "$root/error.log"
  [[ ! -e "$root/state/theme/current" ]] || fail "current symlink should not be created for missing target"
}

test_sync_runs_reload_hooks_after_apply() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  mkdir -p "$root/hooks"
  write_hook "$root/hooks/20-order" <<'EOF'
set -euo pipefail

printf 'order=20\n' >> "${THEME_HOOK_LOG:?}"
EOF

  write_hook "$root/hooks/50-record" <<'EOF'
set -euo pipefail

{
  printf 'order=50\n'
  printf 'arg=%s\n' "${1:-}"
  printf 'env=%s\n' "${ROMAINGRX_THEME_APPEARANCE:-}"
  printf 'current=%s\n' "$(readlink "$ROMAINGRX_THEME_CURRENT")"
  printf 'generated=%s\n' "$ROMAINGRX_THEME_GENERATED_ROOT"
  printf 'runtime=%s\n' "$ROMAINGRX_THEME_RUNTIME_ROOT"
} >> "${THEME_HOOK_LOG:?}"
EOF

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"
  ROMAINGRX_THEME_RELOAD_HOOKS_DIR="$root/hooks"
  THEME_HOOK_LOG="$root/hook.log"
  export THEME_HOOK_LOG

  theme_sync light

  assert_file_contents "$root/hook.log" "order=20
order=50
arg=light
env=light
current=$root/config/romaingrx/theme/generated/light
generated=$root/config/romaingrx/theme/generated
runtime=$root/state/theme"
}

test_reload_hook_failure_is_nonfatal() {
  local root
  root="$(mktemp -d)"
  make_theme_home "$root"

  mkdir -p "$root/hooks"
  write_hook "$root/hooks/10-fail" <<'EOF'
exit 42
EOF

  # Stub `logger` on PATH to capture the syslog mirror (args + piped message).
  mkdir -p "$root/bin"
  cat > "$root/bin/logger" <<EOF
#!$BASH
{ printf 'args: %s\n' "\$*"; cat; } >> "$root/syslog.capture"
EOF
  chmod +x "$root/bin/logger"

  reset_theme_env
  HOME="$root/home"
  XDG_CONFIG_HOME="$root/config"
  XDG_STATE_HOME="$root/state"
  ROMAINGRX_THEME_RELOAD_HOOKS_DIR="$root/hooks"

  local saved_path="$PATH"
  PATH="$root/bin:$PATH"
  theme_sync light 2> "$root/error.log"
  PATH="$saved_path"

  assert_file_contents "$root/state/theme/appearance" "light"
  assert_symlink_target "$root/state/theme/current" "$root/config/romaingrx/theme/generated/light"
  grep -q 'Warning: theme reload hook failed' "$root/error.log"
  grep -q 'Warning: theme reload hook failed' "$root/state/theme/reload-hooks.log"
  # Mirrored to the system log via `logger -t romaingrx-theme`.
  grep -q 'romaingrx-theme' "$root/syslog.capture"
  grep -q 'Warning: theme reload hook failed' "$root/syslog.capture"
}

test_first_run_bootstrap_uses_dark_default
test_sync_switches_repeatedly
test_paths_env_extends_runtime_contract
test_stale_current_symlink_is_repaired
test_non_symlink_current_is_refused
test_missing_generated_target_is_refused
test_sync_runs_reload_hooks_after_apply
test_reload_hook_failure_is_nonfatal

printf 'ok - romaingrx-theme-lib runtime contract\n'
