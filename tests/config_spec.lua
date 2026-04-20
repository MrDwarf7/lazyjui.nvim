describe("lazyjui.config", function()
	before_each(function()
		-- Reset config module state between tests by re-requiring
		package.loaded["lazyjui.config"] = nil
	end)

	describe("defaults", function()
		it("should have default cmd", function()
			local cfg = require("lazyjui.config")
			assert.are.same({ "jjui" }, cfg.cmd)
		end)

		it("should have default height", function()
			local cfg = require("lazyjui.config")
			assert.are.equal(0.8, cfg.height)
		end)

		it("should have default width", function()
			local cfg = require("lazyjui.config")
			assert.are.equal(0.9, cfg.width)
		end)

		it("should have default winblend", function()
			local cfg = require("lazyjui.config")
			assert.are.equal(0, cfg.winblend)
		end)

		it("should have default hide_only", function()
			local cfg = require("lazyjui.config")
			assert.are.equal(false, cfg.hide_only)
		end)

		it("should have default use_default_keymaps", function()
			local cfg = require("lazyjui.config")
			assert.are.equal(true, cfg.use_default_keymaps)
		end)

		it("should have default border", function()
			local cfg = require("lazyjui.config")
			assert.is_not_nil(cfg.border)
			assert.are.same({ "", "", "", "", "", "", "", "" }, cfg.border.chars)
			assert.are.equal(0, cfg.border.thickness)
			assert.are.equal("", cfg.border.winhl_str)
		end)
	end)

	describe("setup", function()
		it("should merge user options with defaults", function()
			local cfg = require("lazyjui.config")
			local result = cfg.setup({ height = 0.5, width = 0.6 })
			assert.are.equal(0.5, result.height)
			assert.are.equal(0.6, result.width)
			-- defaults should still be present
			assert.are.same({ "jjui" }, result.cmd)
		end)

		it("should handle empty opts", function()
			local cfg = require("lazyjui.config")
			local result = cfg.setup({})
			assert.are.equal(0.8, result.height)
			assert.are.equal(0.9, result.width)
		end)

		it("should handle nil opts", function()
			local cfg = require("lazyjui.config")
			local result = cfg.setup(nil)
			assert.are.equal(0.8, result.height)
		end)

		it("should override nested border options", function()
			local cfg = require("lazyjui.config")
			local result = cfg.setup({
				border = {
					thickness = 2,
				},
			})
			assert.are.equal(2, result.border.thickness)
		end)

		it("should accept custom cmd", function()
			local cfg = require("lazyjui.config")
			local result = cfg.setup({ cmd = { "jjui", "-r", "all()" } })
			assert.are.same({ "jjui", "-r", "all()" }, result.cmd)
		end)
	end)
end)
