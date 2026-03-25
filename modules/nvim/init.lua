-- Nix-managed Neovim strips the default site dir from rtp; restore it first
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site")

-- Set leader before lazy
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("options")

require("lazy").setup({ import = "plugins" }, {
  change_detection = { notify = false },
  rocks = { enabled = false },
})

-- Disable unused built-in plugins
local disabled_builtins = {
  "gzip", "netrwPlugin", "tarPlugin",
  "tohtml", "tutor", "zipPlugin",
}
for _, plugin in ipairs(disabled_builtins) do
  vim.g["loaded_" .. plugin] = 1
end

-- Copy diagnostic message to system clipboard
vim.keymap.set('n', '<leader>yd', function()
  local d = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
  if #d > 0 then
    vim.fn.system('pbcopy', d[1].message)
    print('Copied: ' .. d[1].message:sub(1, 50))
  end
end)
