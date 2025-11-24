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

M.__index = M

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

---@param config lazyjui.Config
---@return lazyjui.Config.WindowPos
local function window_pos(config)
	local status, plenary = pcall(require, "plenary.window.float")

	if status then
		---@type PlaneryPercentageRangeWindow
		local ret = plenary.percentage_range_window(0.9, 0.8, {
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

function M:autocmd_group_init(config)
	self.autocmd_group_has_init = true
	setmetatable(self, self.__index)

	-- Create autocmd group for cleanup
	self.autocmd_group = vim.api.nvim_create_augroup("LazyJuiWindow", { clear = true })

	-- Autocmd to hide window when focus is lost
	vim.api.nvim_create_autocmd("WinLeave", {
		group = self.autocmd_group,
		buffer = self.buffer,
		callback = function()
			vim.defer_fn(function()
				if not vim.api.nvim_win_is_valid(self.window) then
					return
				end
				vim.api.nvim_win_hide(self.window)
			end, 20)
		end,
	})

	-- Autocmd to resize window on VimResized event
	vim.api.nvim_create_autocmd("VimResized", {
		group = self.autocmd_group,
		callback = function()
			vim.defer_fn(function()
				if not vim.api.nvim_win_is_valid(self.window) then
					return
				end
				local win_pos_config = window_pos(config)
				-- local new_width, new_height, new_row, new_col, _, _ = window_pos(config)
				vim.api.nvim_win_set_config(self.window, win_pos_config)
			end, 20)
		end,
	})
	setmetatable(M, self)
end

function M:autocmd_group_deinit()
	self.autocmd_group_has_init = false
	self.__index = {}

	-- Clean up autocmd group
	if self.autocmd_group then
		vim.api.nvim_del_augroup_by_id(self.autocmd_group)
		self.autocmd_group = nil
	end

	if self.window and vim.api.nvim_win_is_valid(self.window) then
		vim.api.nvim_win_close(self.window, true)
		self.window = nil
	end

	if self.previous_window and vim.api.nvim_win_is_valid(self.previous_window) then
		vim.api.nvim_set_current_win(self.previous_window)
		self.previous_window = nil
	end

	if self.buffer and vim.api.nvim_buf_is_valid(self.buffer) and vim.api.nvim_buf_is_loaded(self.buffer) then
		vim.api.nvim_buf_delete(self.buffer, { force = true })
		self.buffer = nil
	end
	if self.__debug then
		vim.print(vim.inspect(M))
		vim.print(vim.inspect(self))
		vim.print(vim.inspect(getmetatable(M)))
		vim.print(vim.inspect(getmetatable(self)))
	end
	setmetatable(M, self)
end

function M:hide_only()
	self.previous_window = vim.api.nvim_get_current_win()
	assert(nil, "Not implemented yet")
end

function M:open_floating_window(config)
	self.previous_window = vim.api.nvim_get_current_win()

	-- Get plenary's float window module which handles window creation
	local win_pos_config = window_pos(config)

	if win_pos_config.win_id and win_pos_config.bufnr then
		vim.wo.winblend = config.winblend
		return win_pos_config.win_id, win_pos_config.bufnr
	end

	-- local t = table.unpack(win_pos_config)
	-- vim.print("T value on UNPACK" .. vim.inspect(t))

	---@type vim.api.keyset.win_config
	local new_window_opts = {
		style = "minimal",
		relative = "editor",
		table.unpack(win_pos_config),
	}

	if self.buffer == nil or vim.fn.bufwinnr(self.buffer) == -1 then
		self.buffer = vim.api.nvim_create_buf(false, true)
	else
		self.loaded = true
	end

	self.window = vim.api.nvim_open_win(self.buffer, true, new_window_opts)
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
return setmetatable(M, {
	__debug = M.__debug,
	__name = M.__name,
})
