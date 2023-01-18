local utils = require "chamber.utils"

local msg = {
	err_telescope_not_available = "Telescope is not available",
	err_chamber_not_available = "Chamber is not available",

	start_heath_check = "Starting health check for 'Telescope Chamber'",

	telescope_available = "Telescope is available",
	chamber_available = "Chamber is available",
}

local M = {}

M.check = function()
	vim.health.report_start(msg.start_heath_check)
	local ok = pcall(require, "telescope")
	if not ok then
		vim.health.report_error(msg.err_telescope_not_available)
	else
		vim.health.report_ok(msg.telescope_available)
	end

	-- verify chamber cli is available
	local chamber_ok = utils.is_chamber_available()
	if not chamber_ok then
		vim.health.report_error(msg.err_chamber_not_available)
	else
		vim.health.report_ok(msg.chamber_available)
	end
end

return M
