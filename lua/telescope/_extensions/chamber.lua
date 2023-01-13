local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local chamber = require("chamber")

return telescope.register_extension({
	setup = chamber.setup,
	exports = {
		profiles = chamber.pick_profile,
		regions = chamber.pick_region,
		services = chamber.pick_service,
	},
})
