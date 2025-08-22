---@class lazyjui
local M = {
	opts = {},
}

M.Window = nil
M.Config = nil
M.Utils = nil

local Config = require("lazyjui.config")
local Window = require("lazyjui.window")
local Utils = require("lazyjui.utils")
local Actions = require("lazyjui.actions")

M.__has_init = false

function M.setup(opts)
	opts = opts or {}
	M.opts = vim.tbl_deep_extend("force", M.opts, opts)
	-- Call setup to init
	Config.setup(M.opts)

	-- Assignments for each sub-section/sub-module

	M.Config = Config
	M.Window = Window
	M.Utils = Utils
	M.Actions = Actions

	Actions.Window = M.Window

	M.__has_init = true

	-- Create user command
	vim.api.nvim_create_user_command("LazyJui", M.open, {})
	---@return lazyjui
	return M
end

function M.open()
	M.Actions.open(M)
end

function M.close()
	M.Actions.close()
end

---@type lazyjui
return M
