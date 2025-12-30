---@class lazyjui.Config
local M = {
	__name = "Config",
	__debug = false,

	border = {
		chars = { "", "", "", "", "", "", "", "" },
		thickness = 0,
		winhl_str = "",
	},

	cmd = { "jjui" },
	height = 0.8,
	hide_only = false,
	use_default_keymaps = true,
	width = 0.9,
	winblend = 0,
}

---@package
M.__has_init = false

---@package
--- Represents deprecated config options mapping to their new paths
---@type table<string, string[]>
local deprecated = {
	border_chars = { "border", "chars" },
	border_thickness = { "border", "thickness" },
	border_winhl_str = { "border", "winhl_str" },
	border_winhl = { "border", "winhl_str" },
}
---@package
--- Represents which deprecated options have already been warned about
---@type table<string, boolean>
local warned = {}

function M.setup(opts)
	---@type lazyjui.Default|lazyjui.Config Initial user config opts
	opts = opts or {}

	require("lazyjui.utils").migrate_deprecated(opts, deprecated, warned)

	---@type lazyjui.Config After merging user opts with default config
	M = vim.tbl_deep_extend("force", M, opts)

	M.__has_init = true
	return M
end

---@type lazyjui.Config
return setmetatable(M, {
	---@package
	__index = function(_, key)
		return rawget(M, key)
	end,

	---@package
	__newindex = function()
		vim.error("Attempt to modify read-only lazyjui.Config")
	end,

	__call = function(_, ...)
		return M.setup(...)
	end,
	-- __has_init = M.__has_init,
})
