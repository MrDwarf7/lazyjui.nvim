---@alias int number -- represents a signed number type
---@alias uint number -- represents an unsigned number type

---@class lazyjui
---@field close fun(): nil
---@field open fun( winblend?: int)
---@field setup fun(opts?: lazyjui.Config): nil
local M = {}

---@param opts? lazyjui.Config
function M.setup(opts)
	-- local Health = require("lazyjui.health")
	local Config = require("lazyjui.config")

	Config.setup(opts)

	-- Create user command
	vim.api.nvim_create_user_command("LazyJui", M.open, {})
end

---@param winblend? int
---@return nil
function M.open(winblend)
	-- local actions = require("lazyjui.actions").open(cmd, winblend)
	-- actions.open(cmd, winblend)
	return require("lazyjui.actions").open(winblend)
end

function M.close()
	require("lazyjui.actions").close()
end

return M
