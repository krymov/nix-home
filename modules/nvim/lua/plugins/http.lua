return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    opts = {
      default_view = "body",
    },
    config = function(_, opts)
      local k = require("kulala")
      k.setup(opts)

      vim.api.nvim_create_user_command("Http", function() k.run() end, {})
      vim.api.nvim_create_user_command("HttpAll", function() k.run_all() end, {})
      vim.api.nvim_create_user_command("HttpCurl", function() k.copy() end, {})

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "http", "rest" },
        callback = function(ev)
          local map = function(lhs, fn, desc)
            vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = desc })
          end
          map("<leader>xr", k.run, "Run request")
          map("<leader>xa", k.run_all, "Run all requests")
          map("<leader>xc", k.copy, "Copy as cURL")
          map("<leader>xp", k.scratchpad, "Scratchpad")
        end,
      })
    end,
  },
}
