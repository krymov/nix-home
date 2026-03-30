return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    keys = {
      { "<leader>xr", function() require("kulala").run() end, ft = { "http", "rest" }, desc = "Run request" },
      { "<leader>xa", function() require("kulala").run_all() end, ft = { "http", "rest" }, desc = "Run all requests" },
      { "<leader>xc", function() require("kulala").copy() end, ft = { "http", "rest" }, desc = "Copy as cURL" },
      { "<leader>xp", function() require("kulala").scratchpad() end, ft = { "http", "rest" }, desc = "Scratchpad" },
    },
    opts = {
      default_view = "body",
    },
    config = function(_, opts)
      require("kulala").setup(opts)

      vim.api.nvim_create_user_command("Http", function() require("kulala").run() end, {})
      vim.api.nvim_create_user_command("HttpAll", function() require("kulala").run_all() end, {})
      vim.api.nvim_create_user_command("HttpCurl", function() require("kulala").copy() end, {})
    end,
  },
}
