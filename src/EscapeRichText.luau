--!strict
-- Escape plain text once, before inserting it into a RichText text node.
local entities = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&apos;" }

return function(text: string): string
	assert(type(text) == "string", "text must be a string")
	local escaped = string.gsub(text, "[&<>\"']", entities)
	return escaped
end
