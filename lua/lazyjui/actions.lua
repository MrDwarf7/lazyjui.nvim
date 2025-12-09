---@class lazyjui.Actions
local M = {
	__name = "Actions",
	__debug = false,
	Window = nil,
	cmd = nil,
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

function M:execute()
	assert(self.cmd, "No command set internally to execute")
	assert(type(self.cmd) == "table", "Command must be a table of strings")

	vim.schedule(function()
		vim.fn.jobstart(self.cmd, {
			term = true,
			on_exit = on_exit,
		})
	end)
end

function M:open(utils, config)
	if (not M.cmd) and (not utils.is_available(config.cmd)) then
		vim.notify("jjui executable not found. Please install jjui and ensure it's in your PATH.", vim.log.levels.ERROR)
	end

	-- We can do some form of caching later using the return values I reckon
	M.cmd = config.cmd

	---@diagnostic disable-next-line: unused-local
	local win, buf = self.Window:open_floating_window(config)
	assert(win, "Failed to open floating window")
	assert(buf, "Failed to create buffer for floating window")

	self:execute()
	vim.cmd("startinsert")
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
