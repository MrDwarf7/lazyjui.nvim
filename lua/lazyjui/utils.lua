---@alias Key string: number any
---@alias Value string: number any

---@class lazyjui.Utils
---@field is_available fun(cmd: string|table): boolean
---@field string_to_table fun(str: string): string[]
local M = {}

---@param cmd string|string[]
---@return boolean
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

---@param str string
---@return string[]
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

---@return lazyjui.Utils
return M
