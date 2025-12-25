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

--- Updates self (Window) state params for:
--- loaded,
--- buffer,
--- window,
--- previous_window.
---
--- Be aware that this doesn't really check anything, it just sets the values
---
---@param loaded boolean
---@param buffer? Int
---@param window? Int
---@param previous_window? Int
---@return lazyjui.Window
function M:state_update(loaded, buffer, window, previous_window)
	self.loaded = loaded
	self.buffer = buffer
	self.window = window
	self.previous_window = previous_window
	return self
end

--- Small local function for bulk setting options via
--- the usge of vim.wo, vim.bo and vim.api.nvim_set_hl.
---@param winblend Int
---@return nil
local function buffer_opts(winblend)
	winblend = winblend or 0
	vim.bo.bufhidden = "hide"
	vim.wo.cursorcolumn = false
	vim.wo.signcolumn = "no"
	vim.api.nvim_set_hl(0, "LazyJui", { link = "Normal", default = true })
	vim.api.nvim_set_hl(0, "LazyJuiFloat", { link = "Normal", default = true })
	vim.wo.winhl = "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat"
	vim.bo.filetype = "lazyjui"
	vim.wo.winblend = winblend
end

local function clamp_min_max(min, max_of_val, val)
	return math.max(min, math.min(max_of_val, val))
end

---@param border_chars_array table
---@return table<string, Char>
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

---@param width number
---@param height number
---@return table
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

---@param config_border_chars Char[]|table<Char|nil>
local function set_border_win_opts(config_border_chars)
	local bchars = set_border_chars(config_border_chars)
	return {
		highlight = nil,
		border_thickness = {
			top = 1,
			right = 1,
			bot = 1,
			left = 1,
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

---@class PlaneryWindowFloatMod
---@field centered fun(options: any): table
---@field centered_with_top_win fun(top_text: any, options: any):table
---@field clear fun(bufnr: number):nil
---@field default_options fun(options: any):table
---@field percentage_range_window fun(col_range: any, row_range: any, win_opts: any, border_opts: any):table

---@param config lazyjui.Config
---@param plenary PlaneryWindowFloatMod
---@return lazyjui.Config.WindowPos
local function window_planery(config, plenary)
	-- local planery_status, plenary = pcall(require, "plenary.window.float")
	local width = clamp_min_max(0.1, 1.0, config.width or 0.9) -- config.width or 0.9
	local height = clamp_min_max(0.1, 1.0, config.height or 0.8)
	plenary = plenary or require("plenary.window.float")

	local content_win_opts = set_content_win_opts(width, height)
	local border_win_opts = set_border_win_opts(config.border_chars)

	---@type PlaneryPercentageRangeWindow
	local ret = plenary.percentage_range_window(width, height, content_win_opts, border_win_opts)

	return {
		width = nil,
		height = nil,
		row = nil,
		col = nil,
		win_id = ret.win_id,
		bufnr = ret.bufnr,
	}
end

---@return lazyjui.Config.WindowPos
local function window_native(config)
	local height = math.ceil(vim.o.lines * config.height) - 1
	local width = math.ceil(vim.o.columns * config.width)
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	return {
		width = width,
		height = height,
		row = row,
		col = col,
		win_id = nil,
		bufnr = nil,
	}
end

---@param config lazyjui.Config
---@return lazyjui.Config.WindowPos
local function window_pos(config)
	---@type boolean, PlaneryWindowFloatMod
	local status, plenary = pcall(require, "plenary.window.float")

	---@type lazyjui.Config.WindowPos|nil
	local window_config = {}

	if status then
		window_config = window_planery(config, plenary)
		return window_config
	end

	window_config = window_native(config)
	return window_config
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
		callback = function()
			if not vim.api.nvim_win_is_valid(self.window) then
				return
			end
			vim.api.nvim_win_set_config(self.window, window_pos(config))
		end,
	})
	setmetatable(M, self)
end

function M:autocmd_group_deinit()
	if self.loaded ~= false then
		vim.notify("Window is still loaded; cannot deinitialize autocmd group", vim.log.levels.WARN)
	end

	self.autocmd_group_has_init = false

	-- Clean up autocmd group
	-- if self.autocmd_group then
	-- 	vim.api.nvim_del_augroup_by_id(self.autocmd_group)
	-- 	self.autocmd_group = nil
	-- end

	if self.window and vim.api.nvim_win_is_valid(self.window) then
		vim.api.nvim_win_close(self.window, true)
		-- self.window = nil
	end

	if self.previous_window and vim.api.nvim_win_is_valid(self.previous_window) then
		vim.api.nvim_set_current_win(self.previous_window)
		-- self.previous_window = nil
	end

	if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) and vim.api.nvim_buf_is_loaded(self.buffer) then
		vim.api.nvim_buf_delete(self.buffer, { force = true })
		-- self.buffer = nil
	end
	if self.__debug then
		vim.print(vim.inspect(M))
		vim.print(vim.inspect(self))
		vim.print(vim.inspect(getmetatable(M)))
		vim.print(vim.inspect(getmetatable(self)))
	end

	self = self:state_update(false, nil, nil, nil)

	setmetatable(M, self)
end

function M:hide_only()
	self.previous_window = vim.api.nvim_get_current_win()
	assert(nil, "Not implemented yet")
end

function M:open_floating_window(config)
	local prev_win = vim.api.nvim_get_current_win()
	-- self.previous_window = vim.api.nvim_get_current_win()

	-- Get plenary's float window module which handles window creation
	local win_pos_config = window_pos(config)

	if win_pos_config.win_id and win_pos_config.bufnr then
		vim.wo.winblend = config.winblend
		self = self:state_update(true, win_pos_config.bufnr, win_pos_config.win_id, prev_win)
		self:autocmd_group_init(config)
		-- buffer_opts(config.winblend)
		return win_pos_config.win_id, win_pos_config.bufnr
	end

	if self.buffer == nil or vim.fn.bufwinnr(self.buffer) == -1 then
		self.buffer = vim.api.nvim_create_buf(false, true)
		-- else
		-- 	self.loaded = true
	end

	---@type vim.api.keyset.win_config
	local new_window_opts = {
		style = "minimal",
		relative = "editor",
		width = win_pos_config.width,
		height = win_pos_config.height,
		row = win_pos_config.row,
		col = win_pos_config.col,
	}

	-- self.window = vim.api.nvim_open_win(self.buffer, true, new_window_opts)
	self = self:state_update(
		true,
		vim.api.nvim_create_buf(false, true),
		vim.api.nvim_open_win(self.buffer, true, new_window_opts),
		prev_win
	)

	buffer_opts(config.winblend)

	self:autocmd_group_init(config)

	return self.window, self.buffer
end

function M:close_floating_window()
	self.loaded = false

	self:autocmd_group_deinit()

	vim.cmd("silent! :checktime")
end

---@type lazyjui.Window
return setmetatable(M, M)
