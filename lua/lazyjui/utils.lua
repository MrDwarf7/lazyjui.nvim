---@alias Key string: number any
---@alias Value string: number any

---@class lazyjui.Utils
---@field is_available fun(cmd: string|table): boolean
---@field string_to_table fun(str: string): string[]
local M = {}

---@param cmd table
---@return boolean
function M.is_available(cmd)
	-- We take in a table -> check it -> table to string, run

	if type(cmd) == "string" then
		cmd = M.string_to_table(cmd)
	end

	if type(cmd) ~= "table" or #cmd == 0 then
		return false
	end

	if #cmd == 0 then
		return false
	end

	local as_string = table.concat(cmd, " ")
	if not as_string or as_string == "" then
		return false
	end
	return vim.fn.executable(as_string) == 1
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

return M
