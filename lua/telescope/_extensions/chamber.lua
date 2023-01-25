local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local chamber = require "chamber"

return telescope.register_extension {
	setup = chamber.setup,
	exports = {
		region = chamber.pick_region,
		profile = chamber.pick_profile,
		service = chamber.pick_service,
		variable = chamber.pick_variable,
		can_pick_variable = chamber.can_pick_variable,
	},
}
