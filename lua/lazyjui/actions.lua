---@class lazyjui.Actions
local M = {
	__name = "Actions",
	__debug = false,
	Window = nil,
}

M.__index = M

-- M.Window = nil

function M:close()
	self.Window:close_floating_window()
end

---@param _ number The `job_id` of the job that exited
---@param code number
---@param __ string The `event` that triggered the exit
---@return nil
---@diagnostic disable-next-line: unused-local
local function on_exit(_, code, __)
	if code ~= 0 then
		return
	end

	M.Window:close_floating_window()
end

function M:execute(cmd)
	vim.schedule(function()
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = on_exit,
		})
	end)
	vim.cmd("startinsert")
end

function M:open(utils, config)
	if not utils.is_available(config.cmd) then
		vim.notify("jjui executable not found. Please install jjui and ensure it's in your PATH.", vim.log.levels.ERROR)
	end

	-- We can do some form of caching later using the return values I reckon

	---@diagnostic disable-next-line: unused-local
	local win, buf = self.Window:open_floating_window(config)
	self:execute(config.cmd)
end

function M.setup(window)
	-- Initialize submodules
	if not M.Window then
		M.Window = window or require("lazyjui.window")
		return M
	end
	return M
end

---@type lazyjui.Actions
return setmetatable(M, {
	__call = function(_, ...)
		return M.setup(...)
	end,
	__name = M.__name,
	__debug = M.__debug,
})
