---@param cmd string
---@return boolean
local function is_available(cmd)
	if type(cmd) ~= "string" or cmd == "" then
		return false
	end
	return vim.fn.executable(cmd) == 1
end

---@alias Key string: number any
---@alias Value string: number any

---@generic K: Key, V: Value
---@return table<K, function>
return {
	is_available = is_available,
}
