---@class lazyjui.Window
local M = {
	__name = "Window",
	__debug = false,
	buffer = nil,
	loaded = false,
	previous_window = nil,
	window = nil,
	autocmd_group = nil,
	autocmd_group_has_init = nil,
}

---@class lazyjui.Window.StateUpdate
---@field loaded boolean
---@field buffer Int|nil
---@field window Int|nil
---@field previous_window Int|nil

--- Updates self (Window) via a StateUpdate table.
---
--- The StateUpdate table must contain the following fields:
--- * `loaded`
--- * `buffer`
--- * `window`
--- * `previous_window`
---
--- Anything not included will be set to nil due to Lua table semantics.
---
---@param state_up lazyjui.Window.StateUpdate
---@return nil
function M:state_update(state_up)
	self.loaded = state_up.loaded
	self.buffer = state_up.buffer or nil
	self.window = state_up.window or nil
	self.previous_window = state_up.previous_window or nil
end

--- Small local function for bulk setting options via
--- the usge of vim.wo, vim.bo and vim.api.nvim_set_hl.
---@param winblend Int Example: 0 (opaque) to 100 (fully transparent)
---@param winhl_str? string Example: "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat"
---@return nil
local function buffer_opts(winblend, winhl_str)
	vim.bo.filetype = "lazyjui"
	vim.wo.signcolumn = "no"
	vim.wo.cursorcolumn = false
	vim.bo.bufhidden = "hide"

	-- before the nvim_set_hl calls
	vim.wo.winhl = winhl_str or nil -- "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat"
	vim.api.nvim_set_hl(0, "LazyJui", { link = "Normal", default = true })
	vim.api.nvim_set_hl(0, "LazyJuiFloat", { link = "Normal", default = true })

	vim.wo.winblend = winblend or 0 -- apply user opacity
end

local function clamp_min_max(min, max_of_val, val)
	return math.max(min, math.min(max_of_val, val))
end

---@param border_chars_array table Example: { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
---@return table<string, Char> Example: { topleft = "╭", top = "─", topright = "╮", right = "│", botright = "╯", bot = "─", botleft = "╰", left = "│" }
local function set_border_chars(border_chars_array)
	local bchars = {}
	-- if emtpy table
	if type(border_chars_array) == "table" and (#border_chars_array <= 1) or vim.tbl_isempty(border_chars_array) then
		bchars = {
			topleft = "",
			top = "",
			topright = "",
			right = "",
			botright = "",
			bot = "",
			botleft = "",
			left = "",
		}
	-- it's a table, and actually has (8) elements
	elseif #border_chars_array == 8 and type(border_chars_array) == "table" then
		bchars = {
			topleft = border_chars_array[1] or "╔",
			top = border_chars_array[2] or "═",
			topright = border_chars_array[3] or "╗",
			right = border_chars_array[8] or "║",
			botright = border_chars_array[5] or "╝",
			bot = border_chars_array[6] or "═",
			botleft = border_chars_array[7] or "╚",
			left = border_chars_array[4] or "║",
		}
	end
	return bchars
end

---@param width number Example: 0.9 for 90% of screen width
---@param height number Example: 0.8 for 80% of screen height
---@return table Example: vim.api.nvim_open_win options table
local function set_content_win_opts(width, height)
	return {
		anchor = nil,
		relative = "editor",
		style = "minimal",
		row = nil,
		col = nil,
		width = width,
		height = height,
		zindex = nil,
		noautocmd = nil,
		focusable = true,
		border = nil,
	}
end

---@param config_border_chars Char[]|table<Char|nil> Example: { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
---@param border_thickness number|nil Example: 1
---@return table Example: vim.api.nvim_open_win options table
local function set_border_win_opts(config_border_chars, border_thickness)
	local bchars = set_border_chars(config_border_chars)
	return {
		highlight = nil,
		border_thickness = {
			top = border_thickness or 0,
			right = border_thickness or 0,
			bot = border_thickness or 0,
			left = border_thickness or 0,
		},
		topleft = bchars.topleft,
		top = bchars.top,
		topright = bchars.topright,
		left = bchars.left,
		botright = bchars.botright,
		bot = bchars.bot,
		botleft = bchars.botleft,
		right = bchars.right,
		focusable = true,
	}
end

---@class PlenaryWindowFloatMod
---@field centered fun(options: any): table
---@field centered_with_top_win fun(top_text: any, options: any):table
---@field clear fun(bufnr: number):nil
---@field default_options fun(options: any):table
---@field percentage_range_window fun(col_range: any, row_range: any, win_opts: any, border_opts: any):table

---@param config lazyjui.Config Example: lazyjui configuration table
---@return lazyjui.Config.WindowPos Example: { width = number, height = number, row = number, col = number, win_id = Int|nil, bufnr = Int|nil }
local function window_native(config)
	local height = math.ceil(vim.o.lines * config.height) - 1
	local width = math.ceil(vim.o.columns * config.width)
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	---@return lazyjui.Config.WindowPos Example: { width = Int?, height = Int?, row = number, col = number, win_id = Int|nil, bufnr = Int|nil }
	return {
		width = width,
		height = height,
		row = row,
		col = col,
		win_id = nil,
		bufnr = nil,
	}
end

---@param config lazyjui.Config Example: lazyjui configuration table
---@return lazyjui.Config.WindowPos Example: { width = Int?, height = Int?, row = number, col = number, win_id = Int|nil, bufnr = Int|nil }
function M.window_plenary(config)
	-- local plenary_status, plenary = pcall(require, "plenary.window.float")
	local width = clamp_min_max(0.1, 1.0, config.width or 0.9) -- config.width or 0.9
	local height = clamp_min_max(0.1, 1.0, config.height or 0.8)
	local plenary = require("plenary.window.float")

	local content_win_opts = set_content_win_opts(width, height)
	local border_win_opts = set_border_win_opts(config.border.chars, config.border.thickness)

	local ret = plenary.percentage_range_window(width, height, content_win_opts, border_win_opts)

	---@return lazyjui.Config.WindowPos Example: { width = Int?, height = Int?, row = number, col = number, win_id = Int|nil, bufnr = Int|nil }
	return {
		width = nil,
		height = nil,
		row = nil,
		col = nil,
		win_id = ret.win_id,
		bufnr = ret.bufnr,
	}
end

---@param config lazyjui.Config Example: lazyjui configuration table
---@param window Int Example: window handle
---@return nil
local function handle_resize(config, window)
	local status, _ = pcall(require, "plenary.window.float")
	if status then
		local win_conf = M.window_plenary(config)
		vim.api.nvim_win_set_config(win_conf.bufnr, win_conf)
		return
	end

	if not status then -- no status == native ops
		local win_conf = window_native(config)
		vim.api.nvim_win_set_config(window, win_conf)
		return
	end
end

function M:autocmd_group_init(config)
	self.autocmd_group_has_init = true

	-- Create autocmd group for cleanup
	self.autocmd_group = vim.api.nvim_create_augroup("LazyJuiWindow", { clear = true })

	-- Autocmd to hide window when focus is lost
	vim.api.nvim_create_autocmd("WinLeave", {
		group = self.autocmd_group,
		buffer = self.buffer,
		callback = function()
			if not vim.api.nvim_win_is_valid(self.window) then
				return
			end
			vim.api.nvim_win_hide(self.window)
		end,
	})

	-- Autocmd to resize window on VimResized event
	vim.api.nvim_create_autocmd("VimResized", {
		group = self.autocmd_group,
		buffer = self.buffer,
		callback = function()
			assert(self.window, "AU=VimResized :: self.window is empty!")
			if not vim.api.nvim_win_is_valid(self.window) then
				return
			end
			handle_resize(config, self.window)
		end,
	})
end

function M:autocmd_group_deinit()
	if self.loaded ~= false then
		vim.notify("Window is still loaded; cannot deinitialize autocmd group", vim.log.levels.WARN)
	end

	self.autocmd_group_has_init = false

	--	-- Clean up autocmd group ------ not needed as we have it set to clear = true (will do so on re-create/init
	-- if self.autocmd_group then
	-- 	vim.api.nvim_del_augroup_by_id(self.autocmd_group)
	-- 	self.autocmd_group = nil
	-- end

	if self.previous_window and vim.api.nvim_win_is_valid(self.previous_window) then
		-- vim.print("deinit :: self.previous_window: " .. vim.inspect(self.previous_window))
		vim.api.nvim_set_current_win(self.previous_window)
		-- self.previous_window = nil
	end

	if self.window and vim.api.nvim_win_is_valid(self.window) then
		-- vim.print("deinit :: self.window: " .. vim.inspect(self.window))
		vim.api.nvim_win_close(self.window, true)
		-- self.window = nil
	end

	if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) and vim.api.nvim_buf_is_loaded(self.buffer) then
		-- vim.print("deinit :: self.buffer: " .. vim.inspect(self.buffer))
		vim.api.nvim_buf_delete(self.buffer, { force = true })
		-- self.buffer = nil
	end
	if self.__debug then
		vim.print(vim.inspect(M))
		vim.print(vim.inspect(self))
		vim.print(vim.inspect(getmetatable(M)))
		vim.print(vim.inspect(getmetatable(self)))
	end

	self:state_update({
		loaded = false,
		buffer = nil,
		window = nil,
		previous_window = nil,
	})
end

function M:hide_only()
	self.previous_window = vim.api.nvim_get_current_win()
	assert(nil, "Not implemented yet")
end

------------------------------------

---@param config lazyjui.Config
---@param prev_win Int
function M:using_native(config, prev_win)
	vim.print("M:using_native :: config: " .. vim.inspect(config))
	local win_conf = window_native(config)

	if self.buffer == nil or vim.fn.bufwinnr(self.buffer) == -1 then
		self.buffer = vim.api.nvim_create_buf(false, true)
		-- else
		-- 	self.loaded = true
	end

	---@type vim.api.keyset.win_config
	local new_window_opts = {
		style = "minimal",
		relative = "editor",
		width = win_conf.width,
		height = win_conf.height,
		row = win_conf.row,
		col = win_conf.col,
	}

	self:state_update({
		loaded = true,
		buffer = self.buffer,
		window = vim.api.nvim_open_win(self.buffer, true, new_window_opts),
		previous_window = prev_win,
	})

	buffer_opts(config.winblend, config.border.winhl_str)
	return self.window, self.buffer
end

function M:using_plenary(config, prev_win)
	local win_conf = self.window_plenary(config)

	if win_conf.win_id and win_conf.bufnr then
		-- vim.wo.winblend = config.winblend
		self:state_update({
			loaded = true,
			buffer = win_conf.bufnr,
			window = win_conf.win_id,
			previous_window = prev_win,
		})

		-- Don't turn this on or we cannot resize!!!!!!!!!!!!!
		-- self:autocmd_group_init(config)
	end

	buffer_opts(config.winblend, config.border.winhl_str)
	return self.window, self.buffer
end

------------------------------------

function M:open_floating_window(config)
	local prev_win = vim.api.nvim_get_current_win()

	assert(config, "No config provided to open_floating_window")
	assert(type(config) == "table", "Config provided is not a table")
	assert(prev_win, "Failed to get previous window")

	---@type boolean, PlenaryWindowFloatMod
	local status, _ = pcall(require, "plenary.window.float")
	local id, bufnr = nil, nil

	if status then -- we COULD load plenary -> use plenary variant
		id, bufnr = self:using_plenary(config, prev_win)
		if id and bufnr then
			return id, bufnr -- valid as a plenary float window
		else
			vim.notify("Plenary float window creation failed, falling back to native.", vim.log.levels.WARN)
			return self:using_native(config, prev_win) -- not valid, we use native
		end
	end

	vim.notify("Plenary not available, using native floating window.", vim.log.levels.INFO)
	return self:using_native(config, prev_win) -- fallthrough case, plenary not available
end

function M:close_floating_window()
	self.loaded = false
	self:autocmd_group_deinit()
	vim.cmd("silent! :checktime") -- force UI update
end

---@type lazyjui.Window
return setmetatable(M, M)
