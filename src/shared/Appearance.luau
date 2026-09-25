--!strict
-- Colours for drawing a Waifu, shared by the 2D portrait and the 3D model that rises out of
-- the water: her config colours, re-tinted by mutation.

local Characters = require(script.Parent.Config.Characters)

local Appearance = {}

Appearance.SKIN = Color3.fromRGB(255, 226, 205)

local MUTATION_TINT: { [string]: { tint: Color3, amount: number } } = {
	Golden = { tint = Color3.fromRGB(255, 200, 50), amount = 0.45 },
	Diamond = { tint = Color3.fromRGB(150, 240, 255), amount = 0.45 },
	Ethereal = { tint = Color3.fromRGB(220, 200, 255), amount = 0.4 },
	Celestial = { tint = Color3.fromRGB(255, 245, 200), amount = 0.5 },
	Void = { tint = Color3.fromRGB(60, 0, 110), amount = 0.6 },
}

function Appearance.tint(color: Color3, mutationId: string?): Color3
	if mutationId == "Mystery" then
		return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
	end
	local t = mutationId and MUTATION_TINT[mutationId]
	if t then
		return color:Lerp(t.tint, t.amount)
	end
	return color
end

export type Palette = { hair: Color3, eyes: Color3, outfit: Color3, skin: Color3 }

function Appearance.palette(characterId: string, mutationId: string?): Palette
	local character = Characters.byId[characterId]
	return {
		hair = Appearance.tint(character.hair, mutationId),
		eyes = Appearance.tint(character.eyes, mutationId),
		outfit = Appearance.tint(character.outfit, mutationId),
		skin = Appearance.tint(Appearance.SKIN, mutationId),
	}
end

return Appearance
