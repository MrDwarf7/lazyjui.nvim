---@class lazyjui.Config.mod: lazyjui.Config
local M = {}

---@class lazyjui.Config
---@field border_chars? string[]
---@field cmd? string|string[]
---@field use_default_keymaps? boolean
---@field height int
---@field width int
---@field winblend int
local default_config = {
	cmd = { "jjui" },
	border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	height = 0.8,
	use_default_keymaps = true,
	width = 0.9,
	winblend = 0,
	hide_only = false,
}
M.__index = M
M.__has_init = false

---@param opts? lazyjui.Config
function M.setup(opts)
	opts = opts or {}

	local new_conf = vim.tbl_deep_extend("force", default_config, opts)

	for k, v in pairs(new_conf) do
		M[k] = v
	end
	M.__has_init = true
end

---@return lazyjui.Config
return M
