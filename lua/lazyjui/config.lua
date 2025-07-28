---@class lazyjui.Config.mod: lazyjui.Config
local M = {}

---@class lazyjui.Config
---@field border_chars? string[]
----@field mappings? lazyjui.Config.mappings
---@field use_default_keymaps? boolean
---@field height int
---@field width int
---@field winblend int
local default_config = {
	border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	height = 0.8,
	use_default_keymaps = true,
	width = 0.9,
	winblend = 0,
}

---@param opts? lazyjui.Config
function M.setup(opts)
	opts = opts or {}

	local new_conf = vim.tbl_deep_extend("force", opts, default_config)

	for k, v in pairs(new_conf) do
		M[k] = v
	end
end

return M
