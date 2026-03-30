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

      local function set_keymaps(buf)
        local map = function(lhs, fn, desc)
          vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc })
        end
        map("<leader>xr", k.run, "Run request")
        map("<leader>xa", k.run_all, "Run all requests")
        map("<leader>xc", k.copy, "Copy as cURL")
        map("<leader>xp", k.scratchpad, "Scratchpad")
      end

      -- Set keymaps for the current buffer (lazy.nvim loads on ft, so we already missed the event)
      set_keymaps(0)

      -- Set keymaps for future buffers
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "http", "rest" },
        callback = function(ev)
          set_keymaps(ev.buf)
        end,
      })
    end,
  },
}
