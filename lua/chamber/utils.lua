local M = {}

---@param content table
---@return string | nil
M.marshal_json = function(content)
	local ok, json = pcall(vim.fn.json_encode, content)
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

return M
