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

function M.get_nested(tbl, path)
	local val = tbl
	for _, key in ipairs(path) do
		val = val[key]
		if val == nil then
			return nil
		end
	end
	return val
end

function M.set_nested(tbl, path, value)
	local cur = tbl
	for i = 1, #path - 1 do
		local key = path[i]
		cur[key] = cur[key] or {}
		cur = cur[key]
	end
	cur[path[#path]] = value
end

---@param mut_opts lazyjui.Default|lazyjui.Opts|lazyjui.Config
---@param deprecations table<string, string[]>
---@param warned table<string, boolean>
-- ---@return table
function M.migrate_deprecated(mut_opts, deprecations, warned)
	if not mut_opts or not next(mut_opts) then
		return
	end

	for old_key, new_path in pairs(deprecations) do
		if mut_opts[old_key] ~= nil then
			if not warned[old_key] then
				local new_str = table.concat(new_path, ".")
				vim.notify(
					("[lazyjui] Config option '%s' is deprecated. Please use 'opts.%s = ...' instead."):format(
						old_key,
						new_str
					),
					vim.log.levels.WARN,
					{ title = "lazyjui - Deprecated Option" }
				)
				warned[old_key] = true
			end

			-- Only migrate if new nested value isn't already set (ie: prefer new)
			if M.get_nested(mut_opts, new_path) == nil then
				M.set_nested(mut_opts, new_path, mut_opts[old_key])
			end

			-- Clean up old root key so it isn't held in memory
			mut_opts[old_key] = nil
		end
	end
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
