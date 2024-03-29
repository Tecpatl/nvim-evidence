local lazypath = vim.fn.stdpath("data") .. "/lazy"
vim.notify = print
vim.opt.rtp:append(".")
vim.opt.rtp:append(lazypath .. "/plenary.nvim")
vim.opt.rtp:append(lazypath .. "/nvim-treesitter")
vim.opt.rtp:append(lazypath .. "/sqlite.lua")
vim.opt.rtp:append(lazypath .. "/telescope.nvim")
vim.opt.rtp:append(lazypath .. "/nvim_rocks")

vim.opt.swapfile = false
A = function(...)
  print(vim.inspect(...))
end

