--!strict
-- Shared window chrome. Only one window is open at a time.

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)

local Window = {}

local player = Players.LocalPlayer
local C = Kit.Colors

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
	local frame = Kit.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.04,
		Visible = false,
		Parent = gui,
	}, {
		Kit.corner(16),
		Kit.stroke(C.accent, 2, 0.4),
		Kit.new("UISizeConstraint", { MaxSize = size }),
	})
	-- Fit small screens.
	local scale = Kit.new("UIScale", { Parent = frame })
	local function fit()
		local camera = workspace.CurrentCamera
		if camera then
			local vp = camera.ViewportSize
			scale.Scale = math.min(1, (vp.X - 20) / size.X, (vp.Y - 60) / size.Y)
		end
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	Kit.label({
		Text = title,
		Font = Kit.Font,
		TextSize = 26,
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -80, 0, 34),
		Parent = frame,
	})
	local close = Kit.button("✕", C.bad, { Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Parent = frame })
	local content = Kit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 54),
		Size = UDim2.new(1, -32, 1, -68),
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
	handle.frame.Visible = true
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
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.accent,
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

-- Row of tab buttons; calls onSelect(id). Returns a setter to highlight a tab.
function Window.tabs(parent: Instance, items: { { id: string, name: string } }, onSelect: (string) -> ()): (string) -> ()
	local bar = Kit.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		Parent = parent,
	}, { Kit.list(6, true) })
	local buttons: { [string]: TextButton } = {}
	local function select(id: string)
		for bid, b in buttons do
			b.BackgroundColor3 = if bid == id then C.accent else C.panel3
		end
	end
	for i, item in items do
		local b = Kit.button(item.name, C.panel3, {
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			TextSize = 16,
			LayoutOrder = i,
			Parent = bar,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = b })
		buttons[item.id] = b
		b.Activated:Connect(function()
			select(item.id)
			onSelect(item.id)
		end)
	end
	return select
end

return Window
