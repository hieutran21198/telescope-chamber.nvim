local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local chamber = require("chamber")

return telescope.register_extension({
	setup = chamber.setup,
	exports = {
		chamber_profiles = chamber.pick_profile,
		chamber_regions = chamber.pick_region,
		chamber_services = chamber.pick_service,
	},
})
