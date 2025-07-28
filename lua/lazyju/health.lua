local M = {}

local health = vim.health or require("health")

function M.check()
	-- Start health check
	health.start("lazyju.nvim")

	-- Check for required plugins
	if pcall(require, "plenary") then
		health.ok("plenary.nvim installed")
	else
		health.error("plenary.nvim not installed", {
			"Install plenary.nvim",
			"https://github.com/nvim-lua/plenary.nvim",
		})
	end

	-- Check for lazyju executable
	if vim.fn.executable("jjui") == 1 then
		health.ok("jjui executable found in PATH")
	else
		health.error("jjui executable not found", {
			"Install jjui",
			"Ensure jjui is in your PATH",
		})
	end
end

return M
