-- Minimal Roblox stubs so the Instance-free modules in src/shared can run under the plain luau CLI.
local V = {}
V.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if k == "Unit" then local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z); return Vector3.new(v.X / m, v.Y / m, v.Z / m) end
	return nil
end
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__mul = function(a, b)
	if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
	if type(b) == "number" then return vec(a.X * b, a.Y * b, a.Z * b) end
	return vec(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
V.__unm = function(a) return vec(-a.X, -a.Y, -a.Z) end
Vector3 = { new = vec, zero = vec(0, 0, 0), yAxis = vec(0, 1, 0) }
Color3 = { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end, new = function(r, g, b) return { R = r, G = g, B = b } end }

ATTRS = { EventActive = true, Weather = "Sunny", WeatherEnds = 0 }
local function service(name)
	return { Name = name, GetAttribute = function(_, k) return ATTRS[k] end }
end
game = { GetService = function(_, name) return service(name) end }
workspace = { GetServerTimeNow = function() return 1000 end }

MODULES = {}
local cache = {}
local function proxy(path)
	return setmetatable({ __path = path }, { __index = function(t, k)
		local p = rawget(t, "__path")
		if k == "Parent" then return proxy(p:match("^(.*)%.[^%.]+$")) end
		return proxy(p .. "." .. k)
	end })
end

function require(p)
	local path = type(p) == "table" and rawget(p, "__path") or error("bad require " .. tostring(p))
	path = path:gsub("^ReplicatedStorage%.", "")
	if cache[path] == nil then
		local fn = MODULES[path] or error("no module " .. path)
		cache[path] = fn(proxy(path))
	end
	return cache[path]
end
game = setmetatable(game, { __index = function(_, k) return proxy(k) end })
