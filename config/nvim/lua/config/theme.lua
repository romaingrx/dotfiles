local M = {}

local uv = vim.uv or vim.loop

local state_dir = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state"))
  .. "/theme"
local appearance_file = state_dir .. "/appearance"
local colorschemes = {
  light = "catppuccin-latte",
  dark = "catppuccin-mocha",
}

local watcher
local pending = false
local initialized = false
local notified_error = false

local function valid_appearance(value)
  return value == "light" or value == "dark"
end

local function read_appearance()
  local ok, lines = pcall(vim.fn.readfile, appearance_file)
  local value = ok and lines[1] and vim.trim(lines[1])

  if valid_appearance(value) then
    return value
  end

  return valid_appearance(vim.o.background) and vim.o.background or "dark"
end

local function apply()
  local appearance = read_appearance()
  local colorscheme = colorschemes[appearance]

  vim.o.background = appearance

  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if ok then
    notified_error = false
  elseif not notified_error then
    notified_error = true
    vim.notify(
      "Failed to apply colorscheme " .. colorscheme .. ": " .. err,
      vim.log.levels.WARN
    )
  end
end

local function schedule_apply()
  if pending then
    return
  end

  pending = true
  vim.defer_fn(function()
    pending = false
    apply()
  end, 50)
end

local function stop_watcher()
  if not watcher then
    return
  end

  pcall(watcher.stop, watcher)
  pcall(watcher.close, watcher)
  watcher = nil
end

local function start_watcher()
  stop_watcher()
  vim.fn.mkdir(state_dir, "p")

  watcher = uv.new_fs_event()
  if not watcher then
    return
  end

  local ok = pcall(watcher.start, watcher, state_dir, {}, function(err, filename)
    if not err and (not filename or filename == "appearance") then
      vim.schedule(schedule_apply)
    end
  end)

  if not ok then
    stop_watcher()
  end
end

function M.setup()
  if initialized then
    return
  end

  initialized = true

  vim.api.nvim_create_user_command("ThemeSync", apply, {
    desc = "Apply theme from shared appearance state",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("romaingrx_theme", { clear = true }),
    callback = stop_watcher,
  })

  start_watcher()
  schedule_apply()
end

return M
