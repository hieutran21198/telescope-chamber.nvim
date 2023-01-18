local M = {}

---@param content table
---@return string | nil
M.marshal_json = function(content)
	local ok, json = pcall(vim.fn.json_encode, content)
	return ok and json or nil
end

M.unmarshal_json = function(content)
	local ok, json = pcall(vim.fn.json_decode, content)
	return ok and json or nil
end

---@param content string
---@param path string
M.write_content_to_file = function(content, path)
	local file = io.open(path, "w")
	if not file then
		error("Failed to open file: " .. path)
	end

	file:write(content)
	file:close()
end

M.is_chamber_available = function()
	return pcall(vim.fn.system, "chamber --version")
end

M.is_aws_cli_available = function()
	-- aws-cli/2.9.8 Python/3.10.8 Linux/6.1.1-1-MANJARO source/x86_64.manjaro.22 prompt/off
	-- require version > 2
	local ok, output = pcall(vim.fn.system, "aws --version")
	if not ok then
		return false
	end

	local version = string.match(output, "%d+%.%d+%.%d+")
	if version == nil then
		return false
	end

	local major = string.match(version, "%d+")
	if major == nil then
		return false
	end

	local major_number = tonumber(major)
	if major_number == nil then
		return false
	end

	return major_number >= 2
end

return M
