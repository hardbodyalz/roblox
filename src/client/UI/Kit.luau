--!strict
-- Small UI toolkit: instance builder, theme and common widgets. The look is deliberately quiet:
-- dark translucent panels, thin white outlines, white text with a stroke over the world.

local TweenService = game:GetService("TweenService")

local Kit = {}

local rgb = Color3.fromRGB

Kit.Colors = {
	panel = rgb(14, 18, 26),
	panel2 = rgb(26, 32, 44),
	panel3 = rgb(42, 50, 66),
	line = rgb(255, 255, 255),
	text = rgb(245, 247, 250),
	muted = rgb(150, 160, 178),
	accent = rgb(90, 180, 255),
	pink = rgb(255, 120, 180),
	good = rgb(95, 215, 130),
	bad = rgb(240, 85, 95),
	gold = rgb(255, 205, 85),
}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
Kit.Title = Font.new(FAMILY, Enum.FontWeight.Heavy)
Kit.Bold = Font.new(FAMILY, Enum.FontWeight.Bold)
Kit.Body = Font.new(FAMILY, Enum.FontWeight.Medium)

local function merge(defaults: { [string]: any }, props: { [string]: any }?): { [string]: any }
	if props then
		for k, v in props do
			defaults[k] = v
		end
	end
	return defaults
end

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
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Kit.stroke(color: Color3?, thickness: number?, transparency: number?): any
	return Kit.new("UIStroke", {
		Color = color or Kit.Colors.line,
		Thickness = thickness or 1,
		Transparency = transparency or 0.85,
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

-- Dark translucent panel with a hairline outline.
function Kit.panel(props: { [string]: any }?, children: { any }?): any
	local frame = Kit.new("Frame", merge({
		BackgroundColor3 = Kit.Colors.panel,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, props), children)
	Kit.corner(8).Parent = frame
	Kit.stroke().Parent = frame
	return frame
end

function Kit.label(props: { [string]: any }): any
	return Kit.new("TextLabel", merge({
		BackgroundTransparency = 1,
		FontFace = Kit.Body,
		TextColor3 = Kit.Colors.text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		RichText = true,
	}, props))
end

-- White text with a dark outline, for labels that sit straight on the 3D view.
function Kit.hudLabel(props: { [string]: any }): any
	return Kit.label(merge({
		FontFace = Kit.Bold,
		TextStrokeTransparency = 0.35,
		TextStrokeColor3 = Color3.new(0, 0, 0),
	}, props))
end

function Kit.button(text: string, color: Color3?, props: { [string]: any }?): TextButton
	local button = Kit.new("TextButton", merge({
		Text = text,
		FontFace = Kit.Bold,
		TextSize = 16,
		TextColor3 = Kit.Colors.text,
		BackgroundColor3 = color or Kit.Colors.panel3,
		AutoButtonColor = true,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(120, 36),
	}, props))
	Kit.corner(6).Parent = button
	Kit.stroke(Kit.Colors.line, 1, 0.8).Parent = button
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

-- Scales a frame down to fit small screens.
function Kit.fitToScreen(frame: GuiObject, size: Vector2, margin: Vector2?)
	local scale = Kit.new("UIScale", { Parent = frame })
	local pad = margin or Vector2.new(20, 60)
	local function fit()
		local camera = workspace.CurrentCamera
		if camera then
			local vp = camera.ViewportSize
			scale.Scale = math.min(1, (vp.X - pad.X) / size.X, (vp.Y - pad.Y) / size.Y)
		end
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	return scale
end

return Kit
