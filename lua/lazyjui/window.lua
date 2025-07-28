---@class lazyjui.Window
---@field buffer? int
---@field height uint
---@field loaded boolean
---@field previous_window? int
---@field width uint
---@field window? int
---@field autocmd_group? int
---@field open_floating_window fun(winblend?: integer, border_chars?: string[]): int, int
---@field close_floating_window fun(): nil
local M = {
	buffer = nil,
	loaded = false,
	previous_window = nil,
	window = nil,
	autocmd_group = nil,
}

local function buffer_opts(winblend)
	vim.bo.bufhidden = "hide"
	vim.wo.cursorcolumn = false
	vim.wo.signcolumn = "no"
	vim.api.nvim_set_hl(0, "LazyJui", { link = "Normal", default = true })
	vim.api.nvim_set_hl(0, "LazyJuiFloat", { link = "Normal", default = true })
	vim.wo.winhl = "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat"
	vim.bo.filetype = "lazyjui"
	vim.wo.winblend = winblend or 0 -- 0 = entirely solid
end

local function window_pos()
	local Config = require("lazyjui.config")
	local height_c = Config.height
	local width_c = Config.width
	local border_chars = Config.border_chars
	local status, plenary = pcall(require, "plenary.window.float")

	if status then
		local ret = plenary.percentage_range_window(0.9, 0.8, {
			border = border_chars,
		})

		return nil, nil, nil, nil, ret.win_id, ret.bufnr
	end

	local height = math.ceil(vim.o.lines * height_c) - 1
	local width = math.ceil(vim.o.columns * width_c)
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	return width, height, row, col, nil, nil
end

function M.open_floating_window(winblend, border_chars)
	M.previous_window = vim.api.nvim_get_current_win()

	-- Get plenary's float window module which handles window creation
	local width, height, row, col, plenary_win, plenary_buf = window_pos()
	if plenary_win and plenary_buf then
		-- vim.wo.winblend = winblend
		return plenary_win, plenary_buf
	end

	local opts = {
		style = "minimal", -- disables line numbers, statusline, etc.
		relative = "editor", -- position relative to the entire editor
		row = row,
		col = col,
		width = width,
		height = height,
		border = border_chars,
	}

	if M.buffer == nil or vim.fn.bufwinnr(M.buffer) == -1 then
		M.buffer = vim.api.nvim_create_buf(false, true)
	else
		M.loaded = true
	end

	M.window = vim.api.nvim_open_win(M.buffer, true, opts)
	buffer_opts(winblend)

	-- Create autocmd group for cleanup
	M.autocmd_group = vim.api.nvim_create_augroup("LazyJuiWindow", { clear = true })

	-- Autocmd to hide window when focus is lost
	vim.api.nvim_create_autocmd("WinLeave", {
		group = M.autocmd_group,
		buffer = M.buffer,
		callback = function()
			vim.defer_fn(function()
				if not vim.api.nvim_win_is_valid(M.window) then
					return
				end
				vim.api.nvim_win_hide(M.window)
			end, 20)
		end,
	})

	-- Autocmd to resize window on VimResized event
	vim.api.nvim_create_autocmd("VimResized", {
		group = M.autocmd_group,
		callback = function()
			vim.defer_fn(function()
				if not vim.api.nvim_win_is_valid(M.window) then
					return
				end
				local new_width, new_height, new_row, new_col, _, _ = window_pos()
				vim.api.nvim_win_set_config(M.window, {
					width = new_width,
					height = new_height,
					row = new_row,
					col = new_col,
				})
			end, 20)
		end,
	})

	return M.window, M.buffer
end

function M.close_floating_window()
	M.loaded = false

	vim.cmd("silent! :checktime")

	-- Clean up autocmd group
	if M.autocmd_group then
		vim.api.nvim_del_augroup_by_id(M.autocmd_group)
		M.autocmd_group = nil
	end

	if M.window and vim.api.nvim_win_is_valid(M.window) then
		vim.api.nvim_win_close(M.window, true)
		M.window = nil
	end

	if M.previous_window and vim.api.nvim_win_is_valid(M.previous_window) then
		vim.api.nvim_set_current_win(M.previous_window)
		M.previous_window = nil
	end

	if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) and vim.api.nvim_buf_is_loaded(M.buffer) then
		vim.api.nvim_buf_delete(M.buffer, { force = true })
		M.buffer = nil
	end
end

return M
