describe("lazyjui.health", function()
	before_each(function()
		package.loaded["lazyjui.health"] = nil
	end)

	it("should have a check function", function()
		local health = require("lazyjui.health")
		assert.is_function(health.check)
	end)

	it("should have correct module name", function()
		local health = require("lazyjui.health")
		assert.are.equal("Health", health.__name)
	end)
end)
