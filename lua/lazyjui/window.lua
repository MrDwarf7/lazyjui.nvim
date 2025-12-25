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

	---@type PlaneryPercentageRangeWindow
	local ret = plenary.percentage_range_window(width, height, {
		border = config.border_chars,
	})

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
	local status, planery = pcall(require, "plenary.window.float")

	---@type lazyjui.Config.WindowPos|nil
	local window_config = {}

	if status then
		window_config = window_planery(config, planery)
	else
		window_config = window_native(config)
	end

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
	-- self.__index = {}

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
		table.unpack(win_pos_config),
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
