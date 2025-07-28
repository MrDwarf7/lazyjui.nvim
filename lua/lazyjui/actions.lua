---@class lazyjui.Actions
---@field close fun(): nil
---@field execute fun(cmd: string|table): nil
---@field open fun(winblend?: int): nil
local M = {}

function M.close()
	local Window = require("lazyjui.window")
	Window.close_floating_window()
end

---@diagnostic disable-next-line: unused-local
local function on_exit(job_id, code, event)
	local Window = require("lazyjui.window")

	if code ~= 0 then
		return
	end

	Window.close_floating_window()
end

---@param cmd string|table
function M.execute(cmd)
	vim.schedule(function()
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = on_exit,
		})
	end)
	vim.cmd("startinsert")
end

---@param winblend? int
function M.open(winblend)
	local cmd = { "jjui" }

	winblend = winblend or require("lazyjui.config").winblend
	local border_chars = require("lazyjui.config").border_chars
		or { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }

	local Window = require("lazyjui.window")
	local Utils = require("lazyjui.utils")

	if Utils.is_available(cmd) ~= true then
		vim.notify("jjui executable not found. Please install jjui and ensure it's in your PATH.", vim.log.levels.ERROR)
	end

	---@diagnostic disable-next-line: unused-local
	local win, buf = Window.open_floating_window(winblend, border_chars)
	M.execute(cmd)
end

return M
