---@class lazyjui.Utils
local M = {}

---@package
M.__index = M

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

return M
