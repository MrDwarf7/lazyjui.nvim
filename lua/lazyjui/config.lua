---@class lazyjui.Config
local M = {}

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
	opts = opts or {}

	---@type lazyjui.Default
	local new_conf = vim.tbl_deep_extend("force", default_config, opts)

	for k, v in pairs(new_conf) do
		M[k] = v
	end
	M.__has_init = true
end

----@return lazyjui.Config
return M
