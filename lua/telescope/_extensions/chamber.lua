local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local chamber = require("chamber")

return telescope.register_extension({
	setup = chamber.setup,
	exports = {
		profile = chamber.pick_profile,
		service = chamber.pick_service,
	},
})
