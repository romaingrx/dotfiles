-- Launch the `hunk` review UI (https://github.com/modem-dev/hunk) in a floating
-- terminal. On start, hunk registers a local session daemon, so once a review
-- is open here any agent (pi-hunk, or one using the hunk-review skill) can
-- inspect, navigate, and annotate the *live* session from another terminal --
-- which is why `--watch` is the interesting one for agent workflows.
--
-- hunk itself is installed via home-manager (modules/home/programs/hunk.nix);
-- this file only wires up editor shortcuts. Uses snacks.nvim (a LazyVim dep):
-- `interactive` (default) drops into insert so keys reach hunk and closes the
-- float on a clean exit.

local function open_hunk(args)
  if vim.fn.executable("hunk") == 0 then
    vim.notify(
      "`hunk` not found on PATH -- rebuild home-manager to install it.",
      vim.log.levels.ERROR,
      { title = "hunk" }
    )
    return
  end
  local root = vim.fs.root(0, ".git") or vim.uv.cwd()
  Snacks.terminal.open(vim.list_extend({ "hunk" }, args), {
    cwd = root,
    win = {
      position = "float",
      width = 0.9,
      height = 0.9,
      border = "rounded",
      title = " hunk " .. table.concat(args, " ") .. " ",
      title_pos = "center",
    },
  })
end

local function launch(args)
  return function()
    open_hunk(args)
  end
end

-- Prompt for a ref/commit and open `hunk show <ref>`. pi-hunk's `/hunk review`
-- can't target a ref itself, but it attaches read-only to any live Hunk session
-- for the repo -- so this doubles as a way to hand an agent a specific commit.
local function launch_ref()
  return function()
    vim.ui.input({ prompt = "hunk show (ref): ", default = "main" }, function(ref)
      ref = ref and vim.trim(ref) or ""
      if ref ~= "" then
        open_hunk({ "show", ref })
      end
    end)
  end
end

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        -- Icon resolved through mini.icons (LazyVim's provider) so it stays
        -- colored and consistent with the rest of the which-key groups.
        { "<leader>h", group = "hunk", icon = { cat = "filetype", name = "diff" } },
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>hd", launch({ "diff" }), desc = "Review working tree" },
      { "<leader>hw", launch({ "diff", "--watch" }), desc = "Review working tree (live, for agents)" },
      { "<leader>hs", launch({ "show" }), desc = "Review last commit" },
      { "<leader>hr", launch_ref(), desc = "Review a ref/commit (prompts)" },
    },
  },
}
