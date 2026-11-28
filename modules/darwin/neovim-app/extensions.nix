# The file extensions Neovim.app opens by default. macOS has a type for those
# in `typed`; the app declares one for those in `untyped`, because a handler
# can only be set for a declared type. Check where a new one goes with
# `mdls -name kMDItemContentType file.ext`: a `dyn.` type means untyped.
{
  typed = [
    "bash"
    "c"
    "cpp"
    "css"
    "diff"
    "h"
    "hpp"
    "js"
    "json"
    "md"
    "mjs"
    "mts"
    "patch"
    "py"
    "sh"
    "ts"
    "txt"
    "yaml"
    "yml"
    "zsh"
  ];
  untyped = [
    "cjs"
    "conf"
    "cts"
    "env"
    "fish"
    "go"
    "ini"
    "jsonc"
    "jsx"
    "lock"
    "lua"
    "mdx"
    "nix"
    "pyi"
    "rs"
    "scss"
    "sql"
    "toml"
    "tsx"
  ];
}
