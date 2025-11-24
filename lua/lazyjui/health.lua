---@class lazyjui.Health
local M = {
	__name = "Health",
	__debug = false,
}

function M.check()
	local health = vim.health or require("health")
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

---@type lazyjui.Health
return setmetatable(M, {
	---@package
	__index = M,
	__name = M.__name,
	__debug = M.__debug,
})
