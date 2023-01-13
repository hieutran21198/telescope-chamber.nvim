local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local chamber = require("chamber")

return telescope.register({
	setup = chamber.setup,
	exports = {
		pick_profile = chamber.pick_profile,
	},
})
