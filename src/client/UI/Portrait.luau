--!strict
-- Placeholder character portrait built from UI shapes, coloured from the character's config
-- (hair, eyes, outfit) and re-tinted by mutation. Swap for real art by setting an ImageLabel here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Mutations = require(Shared.Config.Mutations)
local Rarities = require(Shared.Config.Rarities)
local Characters = require(Shared.Config.Characters)
local Appearance = require(Shared.Appearance)
local Kit = require(script.Parent.Kit)

local Portrait = {}

local function shape(parent: Instance, props: { [string]: any }, radius: number?): Frame
	local f = Kit.new("Frame", props)
	f.BorderSizePixel = 0
	Kit.corner(radius or 999).Parent = f
	f.Parent = parent
	return f
end

-- silhouette = true draws an undiscovered black shape.
function Portrait.create(characterId: string, mutationId: string?, silhouette: boolean?): Frame
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]
	local mutation = mutationId and Mutations.byId[mutationId]

	local palette = Appearance.palette(characterId, mutationId)
	local shadow = Color3.new(0.05, 0.05, 0.08)
	local hair = if silhouette then shadow else palette.hair
	local outfit = if silhouette then shadow else palette.outfit
	local eyes = if silhouette then shadow else palette.eyes
	local skin = if silhouette then Color3.new(0.07, 0.07, 0.1) else palette.skin

	local root = Kit.new("Frame", {
		Name = "Portrait",
		BackgroundColor3 = if silhouette then Color3.fromRGB(30, 28, 40) else outfit:Lerp(Color3.new(0, 0, 0), 0.55),
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1),
	}, { Kit.corner(12) })

	if not silhouette then
		Kit.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(rarity.color:Lerp(Color3.new(0, 0, 0), 0.4), outfit:Lerp(Color3.new(0, 0, 0), 0.7)),
			Parent = root,
		})
	end

	-- Long hair behind everything
	shape(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.62, 0.78), BackgroundColor3 = hair }, 40)
	-- Body
	shape(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.fromScale(0.62, 0.5), BackgroundColor3 = outfit }, 30)
	-- Neck + face
	shape(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.12, 0.14), BackgroundColor3 = skin }, 6)
	local face = shape(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.44, 0.42), BackgroundColor3 = skin })
	-- Eyes
	for _, x in { 0.3, 0.7 } do
		local eye = shape(face, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.58), Size = UDim2.fromScale(0.2, 0.24), BackgroundColor3 = Color3.new(1, 1, 1) })
		shape(eye, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.8, 0.85), BackgroundColor3 = eyes })
		shape(eye, { Position = UDim2.fromScale(0.25, 0.2), Size = UDim2.fromScale(0.3, 0.3), BackgroundColor3 = Color3.new(1, 1, 1) })
	end
	-- Bangs
	shape(root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.15), Size = UDim2.fromScale(0.52, 0.18), BackgroundColor3 = hair }, 20)

	if silhouette then
		Kit.label({
			Text = "?",
			FontFace = Kit.Title,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(120, 110, 150),
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(0.5, 0.4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Parent = root,
		})
	elseif mutation and mutation.id ~= "Normal" then
		local border = Kit.stroke(Color3.new(1, 1, 1), 3, 0)
		Kit.gradient(mutation.color, mutation.color2, true).Parent = border
		border.Parent = root
		if mutation.id == "Shiny" or mutation.id == "Diamond" or mutation.id == "Celestial" then
			-- Moving shine sweep
			local shine = Kit.new("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.6,
				Size = UDim2.fromScale(0.25, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(-0.3, 0.5),
				Rotation = 25,
				BorderSizePixel = 0,
				Parent = root,
			})
			task.spawn(function()
				while shine.Parent do
					shine.Position = UDim2.fromScale(-0.3, 0.5)
					Kit.tween(shine, 1.2, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine).Completed:Wait()
					task.wait(1.5)
				end
			end)
		end
	end
	return root
end

return Portrait
