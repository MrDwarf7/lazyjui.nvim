---@class lazyjui.Config
local M = {
	__name = "Config",
	__debug = false,
}

---@type lazyjui.Default
local default_config = {
	border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	cmd = { "jjui" },
	height = 0.8,
	hide_only = false,
	use_default_keymaps = true,
	width = 0.9,
	winblend = 0,
}

---@package
M.__index = M

---@package
M.__has_init = false

function M.setup(opts)
	---@type lazyjui.Default
	local new_conf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(new_conf) do
		M[k] = v
	end

	return setmetatable(M, {
		__index = M,
		__has_init = true,
	})
end

---@type lazyjui.Config
return setmetatable(M, {
	__call = function(_, ...)
		return M.setup(...)
	end,
	__index = M.__index,
	__has_init = M.__has_init,
})
