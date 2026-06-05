local M = {}

local uv = vim.uv or vim.loop

local DEFAULT_APPEARANCE = "dark"
local APPEARANCE_FILE = "appearance"
local COLORSCHEMES = {
  light = "catppuccin-latte",
  dark = "catppuccin-mocha",
}

local state_dir = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state"))
  .. "/theme"
local appearance_file = state_dir .. "/" .. APPEARANCE_FILE
local watcher
local pending = false
local notified_colorscheme_error = false
local initialized = false

local function is_appearance(value)
  return value == "light" or value == "dark"
end

local function normalize(value)
  value = vim.trim(value or "")
  return is_appearance(value) and value or DEFAULT_APPEARANCE
end

local function close_watcher()
  if not watcher then
    return
  end

  pcall(watcher.stop, watcher)
  pcall(watcher.close, watcher)
  watcher = nil
end

local function notify_colorscheme_error(colorscheme, err)
  if notified_colorscheme_error then
    return
  end

  notified_colorscheme_error = true
  vim.notify(
    "Failed to apply colorscheme " .. colorscheme .. ": " .. err,
    vim.log.levels.WARN
  )
end

local function schedule_apply()
  if pending then
    return
  end

  pending = true
  vim.defer_fn(function()
    pending = false
    M.apply()
  end, 50)
end

function M.appearance()
  local ok, lines = pcall(vim.fn.readfile, appearance_file)
  if ok and lines[1] then
    return normalize(lines[1])
  end

  return normalize(vim.o.background)
end

function M.colorscheme()
  return COLORSCHEMES[M.appearance()]
end

function M.apply()
  local appearance = M.appearance()
  local colorscheme = COLORSCHEMES[appearance]

  vim.o.background = appearance

  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok and not notified_colorscheme_error then
    notify_colorscheme_error(colorscheme, err)
  elseif ok then
    notified_colorscheme_error = false
  end

  return ok
end

function M.watch()
  close_watcher()

  vim.fn.mkdir(state_dir, "p")
  watcher = uv.new_fs_event()
  if not watcher then
    return
  end

  local ok = pcall(
    watcher.start,
    watcher,
    state_dir,
    {},
    vim.schedule_wrap(function(err, filename)
      if err then
        return
      end

      if not filename or filename == APPEARANCE_FILE then
        schedule_apply()
      end
    end)
  )

  if not ok then
    close_watcher()
  end

  return ok
end

function M.stop()
  close_watcher()
end

function M.setup()
  if initialized then
    return
  end

  initialized = true
  local group = vim.api.nvim_create_augroup("romaingrx_theme", { clear = true })

  vim.api.nvim_create_user_command("ThemeSync", function()
    M.apply()
  end, { desc = "Apply theme from shared appearance state" })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.stop,
  })

  M.watch()
  schedule_apply()
end

return M
