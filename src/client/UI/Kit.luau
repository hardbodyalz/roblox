--!strict
-- Small UI toolkit: instance builder, theme colours and common widgets.

local TweenService = game:GetService("TweenService")

local Kit = {}

Kit.Colors = {
	panel = Color3.fromRGB(24, 20, 36),
	panel2 = Color3.fromRGB(38, 32, 56),
	panel3 = Color3.fromRGB(54, 46, 78),
	text = Color3.fromRGB(245, 240, 255),
	muted = Color3.fromRGB(170, 160, 195),
	accent = Color3.fromRGB(255, 120, 180),
	accent2 = Color3.fromRGB(140, 110, 255),
	good = Color3.fromRGB(110, 225, 140),
	bad = Color3.fromRGB(255, 90, 100),
	gold = Color3.fromRGB(255, 210, 90),
}

Kit.Font = Enum.Font.FredokaOne
Kit.Body = Enum.Font.GothamMedium
Kit.Bold = Enum.Font.GothamBold

-- new("Frame", { Size = ..., Parent = ... }, { children })
function Kit.new(className: string, props: { [string]: any }?, children: { any }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Kit.corner(radius: number?): any
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Kit.stroke(color: Color3?, thickness: number?, transparency: number?): any
	return Kit.new("UIStroke", {
		Color = color or Color3.new(0, 0, 0),
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.padding(px: number): any
	local u = UDim.new(0, px)
	return Kit.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function Kit.list(padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?): any
	return Kit.new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
	})
end

function Kit.label(props: { [string]: any }): any
	local defaults = {
		BackgroundTransparency = 1,
		Font = Kit.Body,
		TextColor3 = Kit.Colors.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return Kit.new("TextLabel", defaults)
end

function Kit.button(text: string, color: Color3?, props: { [string]: any }?): TextButton
	local defaults: { [string]: any } = {
		Text = text,
		Font = Kit.Font,
		TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = color or Kit.Colors.accent,
		AutoButtonColor = true,
		Size = UDim2.fromOffset(120, 38),
	}
	if props then
		for k, v in props do
			defaults[k] = v
		end
	end
	local button = Kit.new("TextButton", defaults, { Kit.corner(8), Kit.stroke(Color3.new(0, 0, 0), 2, 0.6) })
	return button
end

function Kit.tween(inst: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(inst, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
	tween:Play()
	return tween
end

function Kit.hex(color: Color3): string
	return "#" .. color:ToHex()
end

-- Rich-text coloured span.
function Kit.color(text: string, color: Color3): string
	return string.format('<font color="%s">%s</font>', Kit.hex(color), text)
end

-- Animated two-colour gradient used for mutation text/borders.
function Kit.gradient(c1: Color3, c2: Color3, animate: boolean?): any
	local g = Kit.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(0.5, c2),
			ColorSequenceKeypoint.new(1, c1),
		}),
	})
	if animate then
		task.spawn(function()
			while g.Parent do
				g.Offset = Vector2.new(-1, 0)
				Kit.tween(g, 2, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear).Completed:Wait()
			end
		end)
	end
	return g
end

return Kit
