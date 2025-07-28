-- File: lua/lazyjui/init.lua
local is_available = require("lazyju.utils").is_available

local prev_win = -1

local M = {}

local function open_floating_window()
	-- Get plenary's float window module which handles window creation
	local plenary = require("plenary.window.float")

	-- Create centered floating window at 90% of screen size with rounded borders
	local win = plenary.percentage_range_window(0.9, 0.8, {
		border = {
			"╭",
			"─",
			"╮",
			"│",
			"│",
			"╰",
			"─",
			"╯",
		},
	})

	-- Set buffer filetype for syntax highlighting
	vim.bo[win.bufnr].filetype = "lazyjui"

	-- Ensure window is completely opaque
	vim.wo[win.win_id].winblend = 0

	-- Hide buffer when window closes rather than delete it
	vim.cmd("setlocal bufhidden=hide")

	-- Automatically hide window when focus is lost
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = win.bufnr,
		callback = function()
			vim.cmd("hide")
		end,
		once = true,
	})

	-- Return window and buffer handles for further manipulation if needed
	return win.win_id, win.bufnr
end

function M.setup(opts)
	-- Store user config for later use
	M.config = vim.tbl_deep_extend("force", {
		-- Default configuration options can go here
		mapping = "<Leader>jj", -- Default keymapping
	}, opts or {})

	-- Create user command
	vim.api.nvim_create_user_command("LazyJui", M.open, {})

	-- Set up keymapping if provided
	if M.config.mapping then
		vim.keymap.set("n", M.config.mapping, M.open, {
			noremap = true,
			silent = true,
			desc = "LazyJui", -- This will work with WhichKey and similar plugins
		})
	end
end

function M.open()
	-- Store current window ID for late    -- Check if lazyjui is available
	local cmd = "jjui"

	if is_available(cmd) ~= true then
		vim.notify("jjui executable not found. Please install jjui and ensure it's in your PATH.", vim.log.levels.ERROR)
		return
	end

	prev_win = vim.api.nvim_get_current_win()

	-- Create floating window
	open_floating_window()

	-- Execute lazyjui in the floating window
	vim.fn.termopen(cmd, {
		-- Return to previous window on exit
		on_exit = function()
			if vim.api.nvim_win_is_valid(prev_win) then
				vim.api.nvim_set_current_win(prev_win)
			end
		end,
		-- Handle potential errors
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line:match("^Error:.*") then
					vim.notify("lazyjui error: " .. line, vim.log.levels.ERROR)
				end
			end
		end,
	})

	-- Enter insert mode to allow immediate interaction
	vim.cmd("startinsert")
end

return M
