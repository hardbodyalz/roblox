--!strict
local Format = {}

function Format.commas(n: number): string
	local s = tostring(math.floor(math.abs(n)))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if n < 0 then "-" else "") .. out
end

function Format.yen(n: number): string
	return "¥" .. Format.commas(n)
end

function Format.compact(n: number): string
	local abs = math.abs(n)
	if abs >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return Format.commas(n)
end

function Format.kg(n: number): string
	return string.format("%.1fkg", n)
end

function Format.clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "1 in 50,000" style odds.
function Format.oneIn(p: number): string
	if p <= 0 then
		return "never"
	end
	return "1 in " .. Format.commas(math.max(1, math.floor(1 / p + 0.5)))
end

return Format
