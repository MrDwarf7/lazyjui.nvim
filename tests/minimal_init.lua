-- Minimal init file for running tests with plenary.nvim
-- Usage: nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

-- Add the plugin itself to runtimepath
vim.opt.rtp:append(vim.fn.getcwd())

-- Add plenary.nvim to runtimepath (cloned by CI or manually)
local plenary_path = os.getenv("PLENARY_PATH") or vim.fn.getcwd() .. "/.deps/plenary.nvim"
vim.opt.rtp:append(plenary_path)

-- Load plenary plugin files so PlenaryBustedDirectory command is registered
vim.cmd("runtime plugin/plenary.vim")

-- Ensure plenary is loadable
local ok, _ = pcall(require, "plenary")
if not ok then
	error("plenary.nvim not found. Clone it to " .. plenary_path .. " or set PLENARY_PATH env var.")
end
