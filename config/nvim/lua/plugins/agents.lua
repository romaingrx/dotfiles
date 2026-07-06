return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "agents", icon = "" },
      },
    },
  },
  {
    "RobertTLange/agents.nvim",
    cmd = {
      "Agents",
      "AgentsToggle",
      "AgentsCycle",
      "AgentsOpen",
      "AgentsClose",
      "AgentsKill",
      "AgentsSend",
      "AgentsSelect",
      "AgentsStatus",
      "AgentsHealth",
    },
    keys = {
      { "<leader>aa", "<cmd>AgentsToggle<cr>", desc = "Toggle agent" },
      { "<leader>ac", "<cmd>AgentsCycle<cr>", desc = "Cycle agents" },
      { "<leader>ap", "<cmd>AgentsSelect<cr>", desc = "Pick session" },
      { "<leader>ax", "<cmd>AgentsKill<cr>", desc = "Kill agent" },
      { "<leader>a?", "<cmd>AgentsHealth<cr>", desc = "Health check" },
      {
        "<leader>as",
        function()
          local save = vim.fn.getreg('"')
          vim.cmd('noautocmd normal! "vy')
          local text = vim.fn.getreg("v")
          vim.fn.setreg('"', save)
          vim.cmd("AgentsSend " .. text:gsub("\n", " "))
        end,
        mode = "v",
        desc = "Send selection",
      },
    },
    opts = {
      default_agent = "claude",
      yolo = true,
      ui = {
        layout = "float",
        width = 0.85,
        height = 0.85,
        border = "rounded",
      },
      keymaps = {
        toggle = "<C-;>",
        next_agent = "<C-,>",
        close = "<C-q>",
      },
    },
    config = function(_, opts)
      require("agents").setup(opts)

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function()
          local o = { buffer = true }
          vim.keymap.set("t", "<C-\\>", [[<C-\><C-n>]], vim.tbl_extend("force", o, { desc = "Term: normal mode" }))
          vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], vim.tbl_extend("force", o, { desc = "Term: win left" }))
          vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], vim.tbl_extend("force", o, { desc = "Term: win down" }))
          vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], vim.tbl_extend("force", o, { desc = "Term: win up" }))
          vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], vim.tbl_extend("force", o, { desc = "Term: win right" }))
        end,
      })
    end,
  },
}
