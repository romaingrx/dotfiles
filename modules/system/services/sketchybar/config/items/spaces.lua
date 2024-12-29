local colors = require("colors")
local settings = require("settings")

-- Add events for workspace changes
sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "window_focus")
sbar.add("event", "space_change")

-- Get all workspaces from aerospace
sbar.exec("aerospace list-workspaces --all", function(workspaces)
  for workspace in string.gmatch(workspaces, "[^\r\n]+") do
    local space = sbar.add("item", "space." .. workspace, {
      position = "left",
      background = {
        color = colors.workspace.inactive,
        corner_radius = 5,
        height = 20,
        drawing = true,
        border_color = colors.workspace.border,
      },
      label = workspace,
      click_script = "aerospace workspace " .. workspace,
    })

    -- Subscribe to workspace events
    space:subscribe({"aerospace_workspace_change", "window_focus", "space_change"}, function(env)
      -- Get current workspace
      sbar.exec("aerospace list-workspaces --current", function(current)
        current = current:gsub("%s+", "")  -- Remove whitespace
        local is_active = current == workspace
        space:set({
          background = {
            color = is_active and colors.workspace.active or colors.workspace.inactive,
          }
        })
      end)
    end)
  end
end) 