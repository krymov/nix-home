local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.scrolloff = 4

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Display
opt.termguicolors = true
opt.wrap = false

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Persistence
opt.undofile = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- Markdown-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.conceallevel = 2
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
  end,
})

-- Strip trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable then return end
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

-- Visual indent reselect (no built-in equivalent)
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
