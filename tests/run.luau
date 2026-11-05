--!strict
-- Run locally with Lune: lune run tests/run.luau
local Limiter = require("../src/FixedWindowLimiter")
local escape = require("../src/EscapeRichText")
local cases = 0

local function test(name: string, body: () -> ())
	local ok, message = pcall(body)
	assert(ok, name .. ": " .. tostring(message))
	cases += 1
	print("PASS " .. name)
end

local function fails(body: () -> ())
	assert(not pcall(body), "expected rejection")
end

test("quota and exact window boundary", function()
	local allow = Limiter.new(2, 5)
	assert(allow(10) and allow(10), "initial quota")
	assert(not allow(10) and not allow(14.999), "exhausted quota")
	assert(allow(15) and allow(15), "boundary reset")
	assert(not allow(15), "new window quota")
end)

test("independent limiters", function()
	local first, second = Limiter.new(1, 2), Limiter.new(1, 2)
	assert(first(0) and second(0), "separate initial quotas")
	assert(not first(0) and not second(0), "separate exhausted quotas")
end)

test("fractional durations and long idle gap", function()
	local allow = Limiter.new(1, 0.5)
	assert(allow(0.25), "fractional start")
	assert(not allow(0.749), "before fractional boundary")
	assert(allow(0.75), "fractional boundary")
	assert(allow(1000), "idle reset")
	assert(not allow(1000.25), "quota after idle")
end)

test("fixed window permits boundary bursts", function()
	local allow = Limiter.new(2, 1)
	assert(allow(0) and allow(0.999), "old window")
	assert(allow(1) and allow(1), "new window")
end)

test("invalid quotas and durations", function()
	for _, value in { 0, -1, 1.5, math.huge, -math.huge, 0 / 0, 9007199254740992 } do
		fails(function()
			Limiter.new(value, 1)
		end)
	end
	for _, value in { 0, -1, math.huge, -math.huge, 0 / 0 } do
		fails(function()
			Limiter.new(1, value)
		end)
	end
	fails(function()
		Limiter.new("2" :: any, 1)
	end)
	fails(function()
		Limiter.new(1, nil :: any)
	end)
end)

test("invalid time cannot consume quota", function()
	local allow = Limiter.new(2, 1)
	assert(allow(3), "first call")
	for _, value in { -1, math.huge, -math.huge, 0 / 0, 2.9 } do
		fails(function()
			allow(value)
		end)
	end
	fails(function()
		allow("3" :: any)
	end)
	assert(allow(3), "invalid calls preserved quota")
	assert(not allow(3), "quota now exhausted")
	assert(allow(4), "next window still works")
end)

test("all five rich text escapes", function()
	assert(escape("&<>\"'") == "&amp;&lt;&gt;&quot;&apos;", "five entities")
end)

test("markup becomes literal text", function()
	assert(
		escape('<b title="x">Hello & bye</b>') == "&lt;b title=&quot;x&quot;&gt;Hello &amp; bye&lt;/b&gt;",
		"literal markup"
	)
end)

test("existing entity is plain text; call once", function()
	assert(escape("&lt;") == "&amp;lt;", "existing entity")
	assert(escape(escape("<")) == "&amp;lt;", "double escaping is intentional")
end)

test("empty text, Unicode and newlines", function()
	assert(escape("") == "", "empty string")
	assert(escape("Grüße 世界\n100%") == "Grüße 世界\n100%", "preserved characters")
end)

test("wrong text type is rejected", function()
	fails(function()
		escape(123 :: any)
	end)
end)

test("escape has exactly one return value", function()
	assert(select("#", escape("&&")) == 1, "single return value")
end)

print(string.format("PASS: %d test cases", cases))
