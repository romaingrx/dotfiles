local colors = require("colors")
local settings = require("settings")

-- Add events for workspace changes
sbar.add("event", "aerospace_workspace_change")
sbar.add("event", "window_focus")
sbar.add("event", "space_change")

-- Keep track of all spaces
local spaces = {}

-- Get all workspaces from aerospace
sbar.exec("aerospace list-workspaces --all", function(workspaces)
  for workspace in string.gmatch(workspaces, "[^\r\n]+") do
    local space = sbar.add("item", "space." .. workspace, {
      position = "left",
      padding_left = 2,
      padding_right = 2,
      background = {
        color = colors.workspace.inactive,
        corner_radius = 5,
        height = 20,
        drawing = true,
        border_color = colors.workspace.border,
      },
      label = {
        string = workspace,
        padding_left = 4,
        padding_right = 4,
      },
      click_script = "aerospace workspace " .. workspace,
    })

    -- Store space in our table
    spaces[workspace] = space

    -- Subscribe to workspace events
    space:subscribe({"aerospace_workspace_change", "window_focus", "space_change"}, function(env)
      -- Get focused workspace from the event
      local focused = env.FOCUSED_WORKSPACE or ""
      local is_active = focused == workspace

      -- Update space appearance
      space:set({
        background = {
          color = is_active and colors.workspace.active or colors.workspace.inactive,
        },
        label = {
          drawing = true,
          string = workspace,
        },
      })
    end)
  end
end)

-- Add a bracket around all spaces
sbar.add("bracket", "spaces", { "/space\\..*/" }, {
  background = {
    color = colors.bg1,
    border_color = colors.black,
    border_width = 1,
  },
}) 