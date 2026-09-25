--!strict
-- The second, independent RNG roll. Rolled after the character is decided.
--
-- weight: base mutation weighting (sums to 100).
-- valueMult: multiplies catch value.

export type Mutation = {
	id: string,
	name: string,
	order: number,
	weight: number,
	valueMult: number,
	color: Color3,
	color2: Color3,
}

local list: { Mutation } = {
	{ id = "Normal", name = "Normal", order = 1, weight = 72, valueMult = 1, color = Color3.fromRGB(220, 220, 220), color2 = Color3.fromRGB(220, 220, 220) },
	{ id = "Shiny", name = "Shiny", order = 2, weight = 12, valueMult = 1.5, color = Color3.fromRGB(255, 255, 255), color2 = Color3.fromRGB(160, 230, 255) },
	{ id = "Golden", name = "Golden", order = 3, weight = 8, valueMult = 3, color = Color3.fromRGB(255, 205, 60), color2 = Color3.fromRGB(255, 150, 20) },
	{ id = "Diamond", name = "Diamond", order = 4, weight = 5, valueMult = 6, color = Color3.fromRGB(140, 240, 255), color2 = Color3.fromRGB(80, 160, 255) },
	{ id = "Ethereal", name = "Ethereal", order = 5, weight = 2, valueMult = 15, color = Color3.fromRGB(210, 190, 255), color2 = Color3.fromRGB(140, 255, 230) },
	{ id = "Celestial", name = "Celestial", order = 6, weight = 0.8, valueMult = 40, color = Color3.fromRGB(255, 245, 200), color2 = Color3.fromRGB(255, 200, 80) },
	{ id = "Void", name = "Void", order = 7, weight = 0.19, valueMult = 150, color = Color3.fromRGB(170, 60, 255), color2 = Color3.fromRGB(20, 0, 40) },
	{ id = "Mystery", name = "???", order = 8, weight = 0.01, valueMult = 1000, color = Color3.fromRGB(255, 255, 255), color2 = Color3.fromRGB(0, 0, 0) },
}

local byId: { [string]: Mutation } = {}
for _, m in list do
	byId[m.id] = m
end

return {
	list = list,
	byId = byId,
}
