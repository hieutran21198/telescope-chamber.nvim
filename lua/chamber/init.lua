local telescope_ok = pcall(require, "telescope")
if not telescope_ok then
	return
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local actions_state = require "telescope.actions.state"
local conf = require("telescope.config").values

local utils = require "chamber.utils"

local msg = {
	list_aws_profile = "List AWS Profile",
}

local default_plugin_opts = {
	aws = {
		profile = "default",
		region = "us-east-1",
		service = "",
	},
	mappings = {
		confirm = {
			mode = "i",
			key = "<CR>",
		},
		save = {
			mode = "i",
			key = "<C-s>",
		},
		save_to_file = {
			mode = "i",
			key = "<C-S>",
		},
		pull_variables = {
			mode = "i",
			key = "<C-p>",
		},
		push_to_chamber = {
			mode = "i",
			key = "<C-P>",
		},
	},
	allow_env = true,
}

local M = {
	opts = utils.deepcopy({}, default_plugin_opts),
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

---@class PickRegionOptions options Region-Picker.
---@field on_confirm function callback function when confirm selection.

---@param opts PickRegionOptions | nil
M.pick_region = function(opts)
	---@type PickRegionOptions
	local default_opts = {}
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

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
				local default_handler = function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)

					M.opts.aws.region = selection.value

					print("selected " .. selection.value .. " region.")
				end

				if opts.on_confirm then
					opts.on_confirm {
						default_handler = default_handler,
					}
				else
					default_handler()
				end
			end)

			return true
		end,
	})

	region_picker:find()
end

---@class ProfilePickerOptions options Profile-Picker
---@field on_confirm function callback function when confirm selection.
---@field pick_region boolean
---@field pick_region_opts PickRegionOptions

---@param opts ProfilePickerOptions | nil
M.pick_profile = function(opts)
	---@type ProfilePickerOptions
	local default_opts = {}
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	local profile_picker = pickers.new({}, {
		prompt_title = msg.list_aws_profile,
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
			-- confirm selection
			map("i", "<CR>", function()
				local default_handler = function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)

					M.opts.aws.profile = selection.value
					print("Selected " .. selection.value .. " profile.")

					if opts.pick_region then
						M.pick_region(opts.pick_region_opts)
					end
				end

				if opts.on_confirm then
					opts.on_confirm {
						default_handler = default_handler,
					}
				else
					default_handler()
				end
			end)

			return true
		end,
	})

	profile_picker:find()
end

---@class PickServiceOptions pick-service options.
---@field on_confirm function callback function when confirm selection.

---@param opts PickServiceOptions
M.pick_service = function(opts)
	if not M.opts.aws.region or not M.opts.aws.profile then
		M.pick_profile {
			pick_region = true,
			pick_region_opts = {
				on_confirm = function(confirm_opts)
					confirm_opts.default_handler()

					M.pick_service(opts)
				end,
			},
		}

		return
	end

	---@type PickServiceOptions
	local default_opts = {}
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

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
		prompt_title = M.opts.aws.service and " " .. M.opts.aws.service .. " " .. title or title,
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
			local mappings = M.opts.mappings
			if not mappings then
				mappings = default_plugin_opts.mappings
			end

			if mappings.confirm then
				local confirm_handler = function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					M.opts.aws.service = selection.value

					M.pick_variable {}
				end

				map(mappings.confirm.mode, mappings.confirm.key, confirm_handler)
			else
				print "Please set mappings.confirm"
			end

			if mappings.save_to_file then
				local save_to_file_handler = function()
					local selection = actions_state.get_selected_entry()
					actions.close(prompt_bufnr)
					M.opts.aws.service = selection.value

					local region = M.opts.aws.region
					local profile = M.opts.aws.profile
					local _, obj_result = M.get_env_variables(selection.value, profile, region)
					M.write_service_variables(obj_result)
				end

				map(mappings.save_to_file.mode, mappings.save_to_file.key, save_to_file_handler)
			end

			return true
		end,
	})

	pick_service:find()
end

---@param service string
---@param profile string
---@param region string
M.get_env_variables = function(service, profile, region)
	local key_values = vim.fn.systemlist(
		"AWS_REGION=" .. region .. " " .. "AWS_PROFILE=" .. profile .. " " .. "chamber list -e " .. service
	)

	local results = {}

	local tbl_result = {}
	for _, v in ipairs(key_values) do
		v = v:gsub("%s+", " ")
		local strs = vim.split(v, " ", { trimempty = true })
		if #strs == 6 then
			local key = strs[1]
			local value = strs[6]
			table.insert(results, key .. "=" .. value)
			tbl_result[key] = value
		end
	end

	return results, tbl_result
end

-- ---@class PickValueOptions
-- ---@field on_select_action 'view' | 'save_to_register'
-- ---@param opts PickValueOptions | nil
-- M.pick_variable = function(opts)
-- 	---@type PickValueOptions
-- 	local default_opts = {
-- 		on_select_action = "save_to_register",
-- 	}
--
-- 	opts = vim.tbl_deep_extend("force", default_opts, opts or {})
--
-- 	if M.opts.aws.profile == "" or M.opts.aws.region == "" then
-- 		M.pick_profile()
-- 	end
--
-- 	if M.opts.aws.service == "" then
-- 		M.pick_service {
-- 			update_service_only = true,
-- 		}
-- 		return
-- 	end
--
-- 	local results, _ = M.get_env_variables(M.opts.aws.service, M.opts.aws.profile, M.opts.aws.region)
--
-- 	local title = M.opts.aws.service .. ":" .. M.opts.aws.profile .. ":" .. M.opts.aws.region
--
-- 	local pick_value = pickers.new({}, {
-- 		prompt_title = title,
-- 		finder = finders.new_table {
-- 			results = results,
-- 			entry_maker = function(entry)
-- 				return {
-- 					value = entry,
-- 					display = entry,
-- 					ordinal = entry,
-- 				}
-- 			end,
-- 		},
-- 		sorter = conf.generic_sorter {},
-- 		attach_mappings = function(prompt_bufnr, map)
-- 			map("i", "<CR>", function()
-- 				local selection = actions_state.get_selected_entry()
-- 				actions.close(prompt_bufnr)
--
-- 				if opts.on_select_action == "view" then
-- 					print(selection.value)
-- 				elseif opts.on_select_action == "save_to_register" then
-- 					vim.fn.setreg("+", selection.value)
-- 				end
-- 			end)
--
-- 			return true
-- 		end,
-- 	})
--
-- 	pick_value:find()
-- end
--
M.write_service_variables = function(obj_results)
	vim.ui.input({
		prompt = "File path: ",
	}, function(input)
		if input == "" or not input then
			print "Please enter a valid file path"
			return
		end

		local content = utils.marshal_json(obj_results)
		if not content then
			print "result is nil"
			return
		end

		utils.write_content_to_file(content, input)
	end)
end
--
-- M.load_from_file = function()
-- 	vim.ui.input({
-- 		prompt = "Enter file path",
-- 	}, function(input)
-- 		local content = vim.fn.readfile(input)
-- 		if content == nil then
-- 			print "File not found"
-- 			return
-- 		end
--
-- 		local obj_results = utils.unmarshal_json(content)
-- 		if not obj_results then
-- 			print "Invalid JSON file"
-- 			return
-- 		end
--
-- 		local _, obj_results2 = M.get_env_variables(M.opts.aws.service, M.opts.aws.profile, M.opts.aws.region)
--
-- 		for k, v in pairs(obj_results) do
-- 			if obj_results2[k] ~= v then
-- 				-- run command: chamber write service key value
-- 				local command = "AWS_REGION="
-- 					.. M.opts.aws.region
-- 					.. " "
-- 					.. "AWS_PROFILE="
-- 					.. M.opts.aws.profile
-- 					.. " "
-- 					.. "chamber write "
-- 					.. M.opts.aws.service
-- 					.. " "
-- 					.. k
-- 					.. " "
-- 					.. v
--
-- 				vim.fn.system(command)
-- 			end
-- 		end
--
-- 		M.pick_variable()
-- 	end)
-- end

---@class PickServiceOptions
---@field on_select_action 'update_service' | 'write_to_file'

---@param opts PickServiceOptions | nil

return M
