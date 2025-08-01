---@alias int number -- represents a signed number type
---@alias uint number -- represents an unsigned number type

---@class lazyjui
---@field close fun(): nil
---@field open fun(): nil
---@field setup fun(opts?: lazyjui.Config): nil
---@field Config lazyjui.Config
---@field Window lazyjui.Window
---@field Utils lazyjui.Utils
local M = {}

M.Config = nil
M.Window = nil
M.Utils = nil

local Config = require("lazyjui.config")
local Window = require("lazyjui.window")
local Utils = require("lazyjui.utils")
local Actions = require("lazyjui.actions")

M.__has_init = false

-- How to expose the config so it shows for people filling in 'opts'?

---@param opts? lazyjui.Config
---@return nil
function M.setup(opts)
	-- Call setup to init
	Config.setup(opts)

	-- Assignments for each sub-section/sub-module
	M.Config = Config
	M.Window = Window
	M.Utils = Utils
	M.Actions = Actions

	Actions.Window = M.Window

	M.__has_init = true

	-- Create user command
	vim.api.nvim_create_user_command("LazyJui", M.open, {})
	return M
end

--- Calls the open function from Actions
--- and opens the LazyJui interface.
---
---@params nil
---@return nil
function M.open()
	M.Actions.open(M)
end

--- Closes the close function from Actions
---
---@params nil
---@return nil
function M.close()
	M.Actions.close()
end

---@return lazyjui
return M
