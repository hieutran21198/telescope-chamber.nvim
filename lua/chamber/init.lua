local M = {
	opts = {
		aws = {
			profile = "default",
			region = "us-east-1",
			service = "",
		},
		allow_env = true,
	},

	regions = {
		"ap-south-1",
		"eu-north-1",
		"eu-west-3",
		"eu-west-2",
		"eu-west-1",
		"ap-northeast-3",
		"ap-northeast-2",
		"ap-northeast-1",
		"ca-central-1",
		"sa-east-1",
		"ap-southeast-1",
		"ap-southeast-2",
		"eu-central-1",
		"us-east-1",
		"us-east-2",
		"us-west-1",
		"us-west-2",
	},

	step = 0,
}

M.setup = function(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	if M.opts.allow_env then
		M.opts.aws.profile = os.getenv "AWS_PROFILE" or "default"
		M.opts.aws.region = os.getenv "AWS_REGION" or "us-east-1"
	end
end

M.pick_region = function(opts)
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print "Telescope is not available"
		return
	end

	local pickers = require "telescope.pickers"
	local finders = require "telescope.finders"
	local actions = require "telescope.actions"
	local actions_state = require "telescope.actions.state"
	local conf = require("telescope.config").values

	local region_picker = pickers.new({}, {
		prompt_title = "Select AWS Region",
		finder = finders.new_table {
			results = M.regions,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)

				M.opts.aws.region = selection.value
			end)

			return true
		end,
	})

	region_picker:find()
end

M.pick_profile = function(opts)
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print "Telescope is not available"
		return
	end

	local pickers = require "telescope.pickers"
	local finders = require "telescope.finders"
	local actions = require "telescope.actions"
	local actions_state = require "telescope.actions.state"
	local conf = require("telescope.config").values

	local profile_picker = pickers.new({}, {
		prompt_title = "Select AWS Profile",
		finder = finders.new_table {
			results = vim.fn.systemlist "aws configure list-profiles" or {},
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		},
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)

				M.opts.aws.profile = selection.value

				M.pick_region()
			end)

			return true
		end,
	})

	profile_picker:find()
end

---@param service string
---@param profile string
---@param region string
M.get_chamber_content = function(service, profile, region)
	local key_values = vim.fn.systemlist(
		"AWS_REGION=" .. region .. " " .. "AWS_PROFILE=" .. profile .. " " .. "chamber list -e " .. service
	)

	local results = {}

	local obj_results = {}
	for _, v in ipairs(key_values) do
		v = v:gsub("%s+", " ")
		local strs = vim.split(v, " ")
		if #strs == 6 then
			local key = strs[1]
			local value = strs[6]
			table.insert(results, key .. "=" .. value)
			obj_results[key] = value
		end
	end

	return results, obj_results
end

M.pick_value = function(opts)
	if M.opts.aws.profile == "" or M.opts.aws.region == "" then
		M.pick_profile()
	end

	if M.opts.aws.aws.service == "" then
		M.pick_service()
		return
	end
	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print "Telescope is not available"
		return
	end

	local pickers = require "telescope.pickers"
	local finders = require "telescope.finders"
	local actions = require "telescope.actions"
	local actions_state = require "telescope.actions.state"
	local conf = require("telescope.config").values

	local results, obj_results = M.get_chamber_content(M.opts.aws.service, M.opts.aws.profile, M.opts.aws.region)

	local title = M.opts.aws.service .. ":" .. M.opts.aws.profile .. ":" .. M.opts.aws.region

	local pick_value = pickers.new({}, {
		prompt_title = title,
		finder = finders.new_table {
			results = results,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		},
		sorter = conf.generic_sorter {},
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)
				vim.api.nvim_put({ selection.value }, "c", true, true)
			end)

			map("i", "<C-s>", function()
				M.write_content_to_file(obj_results)
			end)

			return true
		end,
	})

	pick_value:find()
end

M.write_content_to_file = function(obj_results)
	vim.ui.input({
		prompt = "File path: ",
	}, function(input)
		local utils = require "chamber.utils"

		if input == "" or not input then
			print "Please enter a valid file path"
			return
		end

		local content = utils.unmarshal_json(obj_results)
		if not content then
			return
		end

		utils.write_content_to_file(content, input)
	end)
end

M.load_from_file = function()
	vim.ui.input({
		prompt = "Enter file path",
	}, function(input)
		local content = vim.fn.readfile(input)
		if content == nil then
			print "File not found"
			return
		end
		local utils = require "chamber.utils"

		local obj_results = utils.unmarshal_json(content)
		if not obj_results then
			print "Invalid JSON file"
			return
		end

		local _, obj_results2 = M.get_chamber_content(M.opts.aws.service, M.opts.aws.profile, M.opts.aws.region)

		for k, v in pairs(obj_results) do
			if obj_results2[k] ~= v then
				-- run command: chamber write service key value
				local command = "AWS_REGION="
					.. M.opts.aws.region
					.. " "
					.. "AWS_PROFILE="
					.. M.opts.aws.profile
					.. " "
					.. "chamber write "
					.. M.opts.aws.service
					.. " "
					.. k
					.. " "
					.. v

				vim.fn.system(command)
			end
		end
	end)

	M.pick_value()
end

M.pick_service = function(opts)
	if M.opts.aws.profile == "" or M.opts.aws.region == "" then
		print "Please select AWS profile and region first"
		return
	end

	local telescope_ok = pcall(require, "telescope")
	if not telescope_ok then
		print "Telescope is not available"
		return
	end

	local pickers = require "telescope.pickers"
	local finders = require "telescope.finders"
	local actions = require "telescope.actions"
	local actions_state = require "telescope.actions.state"
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
	services = vim.tbl_filter(function(v)
		return v ~= services[1]
	end, services)

	local title = M.opts.aws.profile .. ":" .. M.opts.aws.region

	local pick_service = pickers.new({}, {
		prompt_title = M.opts.aws.service ~= "" and " " .. M.opts.aws.service .. " " .. title or title,
		finder = finders.new_table {
			results = services,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end,
		},
		sorter = conf.generic_sorter {},
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				local selection = actions_state.get_selected_entry()
				actions.close(prompt_bufnr)
				M.opts.aws.service = selection.value

				if opts.write_to_file then
					local region = M.opts.aws.region
					local profile = M.opts.aws.profile
					local _, obj_result = M.get_chamber_content(selection.value, profile, region)

					M.write_content_to_file(obj_result)
				else
					M.pick_value()
				end
			end)

			return true
		end,
	})

	pick_service:find()
end

return M
