--!strict
-- Shared window chrome. Only one window is open at a time; Escape-style toggling via open().

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)

local Window = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local HEADER = 48

local gui = Kit.new("ScreenGui", {
	Name = "Windows",
	ResetOnSpawn = false,
	DisplayOrder = 10,
	Parent = player:WaitForChild("PlayerGui"),
})

export type Handle = {
	name: string,
	frame: Frame,
	content: Frame,
	onOpen: (() -> ())?,
	onClose: (() -> ())?,
}

local windows: { [string]: Handle } = {}
local current: Handle? = nil
local openListeners: { (string) -> () } = {}

function Window.create(name: string, title: string, size: Vector2): Handle
	local frame = Kit.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 0.06,
		Visible = false,
		Parent = gui,
	})
	Kit.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 205, 215)),
		Parent = frame,
	})
	Kit.fitToScreen(frame, size)

	Kit.label({
		Text = string.upper(title),
		FontFace = Kit.Title,
		TextSize = 22,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 0, HEADER),
		Parent = frame,
	})
	local close = Kit.button("✕", C.panel2, {
		Size = UDim2.fromOffset(32, 32),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		TextSize = 16,
		Parent = frame,
	})
	Kit.new("Frame", {
		Name = "Divider",
		BackgroundColor3 = C.line,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = frame,
	})
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, HEADER + 12),
		Size = UDim2.new(1, -32, 1, -(HEADER + 26)),
		Parent = frame,
	})

	local handle: Handle = { name = name, frame = frame, content = content }
	windows[name] = handle
	close.Activated:Connect(function()
		Window.close()
	end)
	return handle
end

function Window.open(name: string)
	local handle = windows[name]
	if not handle then
		return
	end
	if current == handle then
		Window.close()
		return
	end
	Window.close()
	current = handle
	handle.frame.Position = UDim2.fromScale(0.5, 0.53)
	handle.frame.Visible = true
	Kit.tween(handle.frame, 0.18, { Position = UDim2.fromScale(0.5, 0.5) })
	if handle.onOpen then
		handle.onOpen()
	end
	for _, fn in openListeners do
		task.spawn(fn, name)
	end
end

function Window.close()
	local handle = current
	if handle then
		handle.frame.Visible = false
		current = nil
		if handle.onClose then
			handle.onClose()
		end
	end
end

function Window.isOpen(name: string): boolean
	return current ~= nil and current.name == name
end

function Window.onOpened(fn: (string) -> ())
	table.insert(openListeners, fn)
end

-- Scrolling list/grid helper.
function Window.scroller(parent: Instance, props: { [string]: any }?): ScrollingFrame
	local defaults: { [string]: any } = {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.line,
		ScrollBarImageTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = parent,
	}
	if props then
		for k, v in props do
			defaults[k] = v
		end
	end
	return Kit.new("ScrollingFrame", defaults)
end

function Window.clear(container: Instance)
	for _, child in container:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- A list row: flat panel2 card.
function Window.row(parent: Instance, order: number, height: number): Frame
	return Kit.new("Frame", {
		BackgroundColor3 = C.panel2,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -8, 0, height),
		LayoutOrder = order,
		Parent = parent,
	}, { Kit.corner(6), Kit.stroke(C.line, 1, 0.92) })
end

-- Row of pill tabs; calls onSelect(id). Returns a setter to highlight a tab.
function Window.tabs(parent: Instance, items: { { id: string, name: string } }, onSelect: (string) -> ()): (string) -> ()
	local bar = Kit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Kit.list(6, true) })
	local buttons: { [string]: TextButton } = {}
	local function highlight(id: string)
		for bid, b in buttons do
			local on = bid == id
			b.BackgroundColor3 = if on then C.text else C.panel2
			b.TextColor3 = if on then C.panel else C.text
		end
	end
	for i, item in items do
		local b = Kit.button(item.name, C.panel2, {
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 15,
			LayoutOrder = i,
			Parent = bar,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = b })
		;(b:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius = UDim.new(1, 0)
		buttons[item.id] = b
		b.Activated:Connect(function()
			highlight(item.id)
			onSelect(item.id)
		end)
	end
	return highlight
end

return Window
