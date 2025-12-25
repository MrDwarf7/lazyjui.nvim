---@class lazyjui.Utils
local M = {
	__name = "Utils",
	__debug = false,
}

function M.is_available(cmd)
	-- Cast/as to remove warnings as we're mutating type inside the func
	-- we don't return the `cmd` anyway
	-- local cmd_in = cmd --[[@as string|table]]

	if type(cmd) == "string" then
		cmd = M.string_to_table(cmd)
	end

	if type(cmd) ~= "table" or #cmd == 0 then
		return false
	end

	if #cmd == 0 then
		return false
	end

	cmd = table.concat(cmd, " ")
	if not cmd or cmd == "" then
		return false
	end

	local executable = string.match(cmd, "^(%S+)")

	if executable then
		return vim.fn.executable(executable) == 1
	end

	return vim.fn.executable(cmd) == 1
end

function M.string_to_table(str)
	if type(str) ~= "string" or str == "" then
		local t = {}
		table.insert(t, "jjui")
		return t
	end

	local command
	if type(str) == "string" then
		command = {}
		for arg in str:gmatch("%S+") do
			table.insert(command, arg)
		end
	else
		command = str
	end
	return command
end

--- Function to notify messages, aware of fast events
---@param msg MsgData|string The message to notify
---@param level number The log level (e.g., vim.log.levels.INFO)
---@param opts table? Additional options for the notification
local function fast_event_aware_notify(msg, level, opts) --[[@cast msg string]]
	-- force cast to shut linter up
	if vim.in_fast_event() then
		vim.schedule(function()
			vim.notify(msg, level, opts)
		end)
	else
		vim.notify(msg, level, opts)
	end
end

---@private
function M.info(msg)
	-- fast_event_aware_notify(msg, vim.log.levels.INFO, { title = "Info" })
	fast_event_aware_notify(msg, vim.log.levels.INFO, {})
end

---@private
function M.warn(msg)
	-- fast_event_aware_notify(msg, vim.log.levels.WARN, { title = "Warning" })
	fast_event_aware_notify(msg, vim.log.levels.WARN, {})
end

---@private
function M.err(msg)
	-- fast_event_aware_notify(msg, vim.log.levels.ERROR, { title = "Error" })
	fast_event_aware_notify(msg, vim.log.levels.ERROR, {})
end

function M.notify(msg, level)
	assert(type(msg) ~= "nil", "Message cannot be nil")

	if type(msg) ~= "string" then
		msg = vim.inspect(msg)
	end

	if type(level) == "nil" then
		level = vim.log.levels.INFO
	elseif type(level) == "number" then
		level = vim.log.levels[level] or vim.log.levels.INFO
	elseif type(level) == "string" then
		level = string.lower(level)
	else
		level = vim.log.levels.INFO
	end

	-- level = string.lower(level) or vim.log.levels.INFO
	M[level](msg)
end

function M.deep_print(msg, objects)
	if not type(objects) == "nil" and objects then
		vim.print(msg .. vim.inspect(objects))
	end
	vim.print(vim.inspect(msg))
end

-- return M
---@type lazyjui.Utils
return setmetatable(M, {
	__call = function(_, _)
		return M
	end,
	---@package
	__debug = M.__debug,
})
