---@class lazyjui.Window
local M = {
	buffer = nil,
	loaded = false,
	previous_window = nil,
	window = nil,
	autocmd_group = nil,
	autocmd_group_has_init = nil,
}

--- Small local function for bulk setting options via
--- the usge of vim.wo, vim.bo and vim.api.nvim_set_hl.
---@param winblend Int
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
local function window_pos(config)
	local status, plenary = pcall(require, "plenary.window.float")

	if status then
		local ret = plenary.percentage_range_window(0.9, 0.8, {
			border = config.border_chars,
		})

		return nil, nil, nil, nil, ret.win_id, ret.bufnr
	end

	local height = math.ceil(vim.o.lines * config.height) - 1
	local width = math.ceil(vim.o.columns * config.width)
	local row = math.ceil((vim.o.lines - height) / 2)
	local col = math.ceil((vim.o.columns - width) / 2)

	return width, height, row, col, nil, nil
end

function M.autocmd_group_init(config)
	M.autocmd_group_has_init = true

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
				local new_width, new_height, new_row, new_col, _, _ = window_pos(config)
				vim.api.nvim_win_set_config(M.window, {
					width = new_width,
					height = new_height,
					row = new_row,
					col = new_col,
				})
			end, 20)
		end,
	})
end

function M.autocmd_group_deinit()
	M.autocmd_group_has_init = false

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

function M.hide_only()
	M.previous_window = vim.api.nvim_get_current_win()
	assert(nil, "Not implemented yet")
end

function M.open_floating_window(config)
	M.previous_window = vim.api.nvim_get_current_win()

	-- Get plenary's float window module which handles window creation
	local width, height, row, col, plenary_win, plenary_buf = window_pos(config)
	if plenary_win and plenary_buf then
		vim.wo.winblend = config.winblend
		return plenary_win, plenary_buf
	end

	---@type vim.api.keyset.win_config
	local new_window_opts = {
		style = "minimal", -- disables line numbers, statusline, etc.
		relative = "editor", -- position relative to the entire editor
		row = row,
		col = col,
		width = width,
		height = height,
		border = config.border_chars,
	}

	if M.buffer == nil or vim.fn.bufwinnr(M.buffer) == -1 then
		M.buffer = vim.api.nvim_create_buf(false, true)
	else
		M.loaded = true
	end

	M.window = vim.api.nvim_open_win(M.buffer, true, new_window_opts)
	buffer_opts(config.winblend)

	M.autocmd_group_init(config)

	return M.window, M.buffer
end

function M.close_floating_window()
	M.loaded = false

	M.autocmd_group_deinit()

	vim.cmd("silent! :checktime")
end

-- TEST: Have a feeling this _may_ cause some issues but not sure rn

---@package
M.__index = M

return M
