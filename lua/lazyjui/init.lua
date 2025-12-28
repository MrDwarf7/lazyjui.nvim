local window = require("lazyjui.window")

---@class lazyjui
local M = {
	__name = "lazyjui",
	__debug = false,
	__master_debug = false,
	opts = {},
	Window = require("lazyjui.window"),
	Config = require("lazyjui.config"),
	Utils = nil,
	Actions = require("lazyjui.actions")(window),
}

M.__has_init = false

--- Checks if debug mode is enabled and
--- runs the provided callback if so
function M:debug(callback)
	if self.__debug then
		callback()
	end
end

--- Calls required modules and loads them into the main module table
--- Only fires after `lazyjui.setup(opts?)` is called
---
---@package
---@return nil
function M:load_stack()
	if self.__has_init then
		return
	end

	local Utils = require("lazyjui.utils")
	local Health = require("lazyjui.health")

	local modules = {
		Utils,
		Health,
	}

	---@class module.MetaData
	---@field __name string
	---@field __debug? boolean

	--- Inline fn to check for duplicate module names
	---@param meta module.MetaData
	local duplicate = function(meta)
		self:debug(function()
			if self[meta] then
				self.Utils.notify("Duplicate module name detected: " .. meta, "warn")
			end
		end)
	end

	--- Inline fn to dump debug info about loaded modules
	---@param meta module.MetaData
	local debug_dump = function(meta)
		self:debug(function()
			self.Utils.notify("Loaded module: " .. meta.__name, "info")
			self.Utils.notify(
				--
				"Debug status for sub-module '"
					.. meta.__name
					.. "': "
					.. tostring(meta.__debug),
				"info"
			)

			if self.__master_debug then
				Utils.notify(
					"Master debug is enabled; setting sub-module debug to true.\nCurrently: "
						.. "'"
						.. tostring(meta.__debug)
						.. "' "
						.. "for module: "
						.. meta.__name,
					"info"
				)
			end
		end)
	end

	for _, module in ipairs(modules) do
		assert(type(module) == "table", "Module is not a table: " .. vim.inspect(module))
		assert(module.__name, "Module is missing __name field: " .. vim.inspect(module))

		duplicate({ __name = module.__name })

		if type(self[module.__name]) == "function" then
			local f = self[module.__name]
			if f then
				f()
			end
		end

		if not self[module.__name] then
			self[module.__name] = module
		end

		if self.__master_debug then
			module.__debug = true
		end

		debug_dump({ __name = module.__name, _debug = module.__debug })
	end
	setmetatable(M, self)
end

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	-- from M.Config: Fn(...) -> M.Config: attribute via the already assigned M.Config.__call->setup fn
	M.Config = M.Config(M.opts)
	M:load_stack()
	M.__has_init = true

	-- Create user command
	vim.api.nvim_create_user_command("LazyJui", M.open, {})
	---@return lazyjui
	return setmetatable(M, M)
end

function M.open()
	M.Actions:open(M.Utils, M.Config)
end

function M.close()
	M.Actions:close()
end

---@type lazyjui
return setmetatable(M, M)
