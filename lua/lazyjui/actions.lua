---@class lazyjui.Actions
---@field Window lazyjui.Window
----@field close fun(opts?: lazyjui): nil
---@field close fun(): nil
---@field execute fun(cmd: string|table): nil
---@field open fun(opts?: lazyjui): nil
local M = {}

M.Window = nil

function M.close()
	M.Window.close_floating_window()
end

----@param job_id number
---@param code number
----@param event string
---@return nil
---@diagnostic disable-next-line: unused-local
local function on_exit(_, code, _)
	if code ~= 0 then
		return
	end

	M.Window.close_floating_window()
end

function M.execute(cmd)
	vim.schedule(function()
		vim.fn.jobstart(cmd, {
			term = true,
			on_exit = on_exit,
		})
	end)
	vim.cmd("startinsert")
end

function M.open(opts)
	if not opts.Utils.is_available(opts.Config.cmd) then
		vim.notify("jjui executable not found. Please install jjui and ensure it's in your PATH.", vim.log.levels.ERROR)
	end

	-- We can do some form of caching later using the return values I reckon

	---@diagnostic disable-next-line: unused-local
	local win, buf = M.Window.open_floating_window(opts.Config)
	M.execute(opts.Config.cmd)
end

---@return lazyjui.Actions
return M
