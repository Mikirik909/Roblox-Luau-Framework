--!strict
-- One independent limiter per stream; supply server-owned monotonic time.

local FixedWindowLimiter = {}

local function finite(value: number): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function FixedWindowLimiter.new(maxCalls: number, windowSeconds: number): (number) -> boolean
	assert(
		finite(maxCalls) and maxCalls >= 1 and maxCalls <= 9007199254740991 and maxCalls % 1 == 0,
		"maxCalls must be a positive safe integer"
	)
	assert(finite(windowSeconds) and windowSeconds > 0, "windowSeconds must be positive and finite")
	local start: number? = nil
	local last: number? = nil
	local used = 0

	return function(now: number): boolean
		assert(finite(now) and now >= 0, "now must be nonnegative and finite")
		assert(last == nil or now >= last, "now must not move backwards")
		last = now
		if start == nil or now - start >= windowSeconds then
			start = now
			used = 0
		end
		if used >= maxCalls then
			return false
		end
		used += 1
		return true
	end
end

return FixedWindowLimiter
