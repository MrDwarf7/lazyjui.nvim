local utils = require("lazyjui.utils")

describe("lazyjui.utils", function()
	describe("string_to_table", function()
		it("should convert a simple command string to table", function()
			local result = utils.string_to_table("jjui")
			assert.are.same({ "jjui" }, result)
		end)

		it("should convert a command string with arguments to table", function()
			local result = utils.string_to_table("jjui -r all()")
			assert.are.same({ "jjui", "-r", "all()" }, result)
		end)

		it("should return default for empty string", function()
			local result = utils.string_to_table("")
			assert.are.same({ "jjui" }, result)
		end)

		it("should return default for non-string input", function()
			local result = utils.string_to_table(nil)
			assert.are.same({ "jjui" }, result)
		end)
	end)

	describe("is_available", function()
		it("should return true for available commands", function()
			-- 'ls' should be available on any Unix-like system
			assert.is_true(utils.is_available("ls"))
		end)

		it("should return true for table commands", function()
			assert.is_true(utils.is_available({ "ls" }))
		end)

		it("should return false for unavailable commands", function()
			assert.is_false(utils.is_available("this_command_definitely_does_not_exist_12345"))
		end)

		it("should return false for empty table", function()
			assert.is_false(utils.is_available({}))
		end)

		it("should return false for empty string", function()
			assert.is_false(utils.is_available(""))
		end)
	end)

	describe("get_nested", function()
		it("should retrieve a nested value", function()
			local tbl = { a = { b = { c = "hello" } } }
			assert.are.equal("hello", utils.get_nested(tbl, { "a", "b", "c" }))
		end)

		it("should return nil for missing path", function()
			local tbl = { a = { b = 1 } }
			assert.is_nil(utils.get_nested(tbl, { "a", "c" }))
		end)

		it("should handle single-level path", function()
			local tbl = { foo = "bar" }
			assert.are.equal("bar", utils.get_nested(tbl, { "foo" }))
		end)
	end)

	describe("set_nested", function()
		it("should set a nested value", function()
			local tbl = {}
			utils.set_nested(tbl, { "a", "b", "c" }, 42)
			assert.are.equal(42, tbl.a.b.c)
		end)

		it("should set a single-level value", function()
			local tbl = {}
			utils.set_nested(tbl, { "key" }, "value")
			assert.are.equal("value", tbl.key)
		end)

		it("should create intermediate tables", function()
			local tbl = {}
			utils.set_nested(tbl, { "a", "b" }, true)
			assert.is_table(tbl.a)
			assert.is_true(tbl.a.b)
		end)
	end)

	describe("migrate_deprecated", function()
		it("should migrate deprecated keys to new paths", function()
			local opts = { border_chars = { "a", "b" } }
			local deprecations = { border_chars = { "border", "chars" } }
			local warned = {}
			utils.migrate_deprecated(opts, deprecations, warned)
			assert.are.same({ "a", "b" }, opts.border.chars)
			assert.is_nil(opts.border_chars)
		end)

		it("should not overwrite existing new values", function()
			local opts = {
				border_chars = { "old" },
				border = { chars = { "new" } },
			}
			local deprecations = { border_chars = { "border", "chars" } }
			local warned = {}
			utils.migrate_deprecated(opts, deprecations, warned)
			assert.are.same({ "new" }, opts.border.chars)
		end)

		it("should handle empty opts", function()
			local opts = {}
			local deprecations = { border_chars = { "border", "chars" } }
			local warned = {}
			-- Should not error
			utils.migrate_deprecated(opts, deprecations, warned)
			assert.is_nil(opts.border)
		end)

		it("should handle nil opts", function()
			local deprecations = { border_chars = { "border", "chars" } }
			local warned = {}
			-- Should not error
			utils.migrate_deprecated(nil, deprecations, warned)
		end)

		it("should track warned deprecations", function()
			local opts = { border_chars = { "a" } }
			local deprecations = { border_chars = { "border", "chars" } }
			local warned = {}
			utils.migrate_deprecated(opts, deprecations, warned)
			assert.is_true(warned.border_chars)
		end)
	end)

	describe("notify", function()
		it("should not error on string message", function()
			-- Just ensure it doesn't throw
			assert.has_no.errors(function()
				utils.notify("test message", "info")
			end)
		end)

		it("should not error on table message", function()
			assert.has_no.errors(function()
				utils.notify({ key = "value" }, "info")
			end)
		end)
	end)
end)
