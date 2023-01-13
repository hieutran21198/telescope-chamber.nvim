local M = {
	opts = {
		aws = {
			profile = "default",
			region = "ap-southeast-1",
			service = "",
		},
		-- if use_cached_profiles == true, list profiles and regions will be
		-- loaded at init. If not, it will be loaded after telescope prompt
		-- buffer has been opened.
		use_cached_profiles = false,
		-- if load_from_env == true, load profiles and regions from environment
		-- and override the opts.aws.profile & opts.aws.region configuration.
		load_from_env = false,
	},

	regions = {},
	profiles = {},
	step = 0,
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	if M.opts.use_cached_profiles then
		M.profiles = vim.fn.systemlist("aws configure list-profiles")
		M.regions = vim.fn.systemlist("aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text")
	end

	if M.opts.load_from_env then
		M.opts.aws.profile = os.getenv("AWS_PROFILE") or "default"
		M.opts.aws.region = os.getenv("AWS_REGION") or "ap-southeast-1"
	end
end

M.update_profile = function(str)
	local arrs = vim.split(str, ":")
	local profile, region = "", ""
	if #arrs == 2 then
		profile, region = arrs[1], arrs[2]
	else
		if #arrs == 1 then
			profile = arrs[1]
		else
			profile, region = "", ""
		end
	end

	if profile ~= "" then
		print("Setting AWS profile to " .. profile)
		M.opts.aws.profile = profile
	end

	if region ~= "" then
		print("Setting AWS region to " .. region)
		M.opts.aws.region = region
	end
end

M.pick_profile = function(opts)
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print("Telescope is not available")
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local actions_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	local profiles = M.profiles

	if not M.opts.use_cached_profiles then
		profiles = vim.fn.systemlist("aws configure list-profiles")
	end

	local profile_picker = pickers.new(opts or {}, {
		prompt_title = M.opts.aws.profile,
		finder = finders.new_table({
			results = profiles,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)
				M.update_profile(selection.value)
			end)

			return true
		end,
	})

	profile_picker:find()
end

M.pick_region = function(opts)
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print("Telescope is not available")
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local actions_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	local regions = M.regions
	if not M.opts.use_cached_profiles then
		regions = vim.fn.systemlist("aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text")
	end

	local region_picker = pickers.new(opts or {}, {
		prompt_title = M.opts.aws.region,
		finder = finders.new_table({
			results = regions,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)
				M.update_profile(M.opts.aws.profile .. ":" .. selection.value)
			end)

			return true
		end,
	})

	region_picker:find()
end

M.pick_service = function(opts)
	if M.opts.aws.profile == "" or M.opts.aws.region == "" then
		print("Please select AWS profile and region first")
		return
	end

	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print("Telescope is not available")
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local actions_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	local services = vim.fn.systemlist(
		"AWS_REGION="
			.. M.opts.aws.region
			.. " "
			.. "AWS_PROFILE="
			.. M.opts.aws.profile
			.. " "
			.. "chamber list-services"
	)
	-- remove first item which is the service name
	services = vim.tbl_filter(function(v, _)
		return v ~= services[1]
	end, services)

	local title = M.opts.aws.profile .. ":" .. M.opts.aws.region

	pickers
		.new(opts or {}, {
			prompt_title = M.opts.aws.service ~= "" and " " .. M.opts.aws.service .. " " .. title or title,
			finder = finders.new_table({
				results = services,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				map("i", "<CR>", function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					M.opts.aws.service = selection.value
					M.pick_key_value(opts)
				end)

				return true
			end,
		})
		:find()
end

M.pick_key_value = function(opts)
	if M.opts.aws.service == "" or M.opts.aws.profile == "" or M.opts.aws.region == "" then
		print("Please select AWS service, profile and region first")
		return
	end
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print("Telescope is not available")
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local actions_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	local key_values = vim.fn.systemlist(
		"AWS_REGION="
			.. M.opts.aws.region
			.. " "
			.. "AWS_PROFILE="
			.. M.opts.aws.profile
			.. " "
			.. "chamber list -e "
			.. M.opts.aws.service
	)
	-- remove first item which is the service name
	-- key_values = vim.tbl_filter(function(v, _)
	-- 	return v ~= key_values[1]
	-- end, key_values)
	local results = {}
	for _, v in ipairs(key_values) do
		-- trim duplicate spaces
		v = v:gsub("%s+", " ")
		local strs = vim.split(v, " ")
		if #strs == 6 then
			local key = strs[1]
			local value = strs[6]
			table.insert(results, key .. "=" .. value)
		end
	end

	local title = M.opts.aws.service .. ":" .. M.opts.aws.profile .. ":" .. M.opts.aws.region

	pickers
		.new(opts or {}, {
			prompt_title = title,
			finder = finders.new_table({
				results = results,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				map("i", "<CR>", function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.api.nvim_put({ selection.value }, "c", true, true)
				end)

				return true
			end,
		})
		:find()
end

return M
