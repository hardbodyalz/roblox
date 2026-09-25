--!strict
-- Toasts (personal), announcements (server-wide), zone titles, floating popups and the sailing
-- transition.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Net = require(ReplicatedStorage.Shared.Net)
local Kit = require(script.Parent.Kit)

local Notices = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local gui = Kit.new("ScreenGui", {
	Name = "Notices",
	ResetOnSpawn = false,
	DisplayOrder = 50,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local function fadeOut(root: GuiObject, seconds: number): Tween
	for _, d in root:GetDescendants() do
		if d:IsA("TextLabel") then
			Kit.tween(d, seconds, { TextTransparency = 1, TextStrokeTransparency = 1 })
		elseif d:IsA("UIStroke") then
			Kit.tween(d, seconds, { Transparency = 1 })
		elseif d:IsA("Frame") then
			Kit.tween(d, seconds, { BackgroundTransparency = 1 })
		end
	end
	return Kit.tween(root, seconds, { BackgroundTransparency = 1 })
end

-- Toasts --------------------------------------------------------------------------

local toastStack = Kit.new("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -120),
	Size = UDim2.fromOffset(280, 400),
	Parent = gui,
}, {
	Kit.new("UIListLayout", {
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local toastOrder = 0
function Notices.toast(title: string, text: string?, color: Color3?)
	toastOrder += 1
	local accent = color or C.accent
	local frame = Kit.panel({
		Size = UDim2.fromOffset(280, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = toastOrder,
		Parent = toastStack,
	}, {
		Kit.new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) }),
		Kit.list(2),
		Kit.label({ Text = title, FontFace = Kit.Bold, TextSize = 16, TextColor3 = accent, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }),
		Kit.label({ Text = text or "", TextSize = 14, TextColor3 = C.muted, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = text ~= nil and text ~= "" }),
	})
	local stroke = frame:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = accent
	stroke.Transparency = 0.5
	task.delay(4, function()
		fadeOut(frame, 0.4).Completed:Wait()
		frame:Destroy()
	end)
end

function Notices.error(text: string)
	Notices.toast(text, nil, C.bad)
end

-- Floating popup, e.g. "PERFECT CAST!" -------------------------------------------------

function Notices.float(text: string, color: Color3?)
	local label = Kit.hudLabel({
		Text = text,
		FontFace = Kit.Title,
		TextSize = 34,
		TextColor3 = color or C.gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(500, 44),
		Parent = gui,
	})
	local scale = Kit.new("UIScale", { Scale = 0.6, Parent = label })
	Kit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	Kit.tween(label, 1.2, { Position = UDim2.fromScale(0.5, 0.34) })
	task.delay(0.8, function()
		Kit.tween(label, 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 }).Completed:Wait()
		label:Destroy()
	end)
end

-- Zone title: big fading name when you arrive somewhere ----------------------------------

local zoneFrame: Frame? = nil
function Notices.zone(title: string, subtitle: string?, color: Color3?)
	if zoneFrame then
		zoneFrame:Destroy()
	end
	local frame = Kit.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.fromOffset(700, 80),
		Parent = gui,
	})
	zoneFrame = frame
	local main = Kit.hudLabel({
		Text = string.upper(title),
		FontFace = Kit.Title,
		TextSize = 40,
		TextColor3 = color or C.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 46),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = frame,
	})
	local sub = Kit.hudLabel({
		Text = subtitle or "",
		FontFace = Kit.Body,
		TextSize = 17,
		TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 24),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = frame,
	})
	Kit.tween(main, 0.6, { TextTransparency = 0, TextStrokeTransparency = 0.4 })
	Kit.tween(sub, 0.6, { TextTransparency = 0.1, TextStrokeTransparency = 0.5 })
	task.delay(3.5, function()
		if frame.Parent then
			Kit.tween(main, 0.8, { TextTransparency = 1, TextStrokeTransparency = 1 })
			Kit.tween(sub, 0.8, { TextTransparency = 1, TextStrokeTransparency = 1 }).Completed:Wait()
			frame:Destroy()
		end
	end)
end

-- Server-wide banner ------------------------------------------------------------

local bannerQueue: { any } = {}
local bannerBusy = false

local function showBanner(info: any)
	bannerBusy = true
	local color: Color3 = info.color or C.gold
	local big = info.big == true
	local banner = Kit.panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -120),
		Size = UDim2.fromOffset(if big then 600 else 480, if big then 84 else 64),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		Parent = gui,
	})
	local stroke = banner:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = color
	stroke.Transparency = 0.2
	stroke.Thickness = if big then 2 else 1
	local title = Kit.hudLabel({
		Text = info.title,
		FontFace = Kit.Title,
		TextSize = if big then 30 else 22,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, if big then 38 else 28),
		Position = UDim2.fromOffset(10, 6),
		Parent = banner,
	})
	if big then
		Kit.gradient(color, Color3.new(1, 1, 1), true).Parent = title
	end
	Kit.label({
		Text = info.text or "",
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.fromOffset(10, if big then 44 else 32),
		Parent = banner,
	})
	Kit.tween(banner, 0.5, { Position = UDim2.new(0.5, 0, 0, 64) }, Enum.EasingStyle.Back)
	task.wait(if big then 6 else 4.5)
	Kit.tween(banner, 0.4, { Position = UDim2.new(0.5, 0, 0, -120) }).Completed:Wait()
	banner:Destroy()
	bannerBusy = false
	local nextInfo = table.remove(bannerQueue, 1)
	if nextInfo then
		task.spawn(showBanner, nextInfo)
	end
end

function Notices.announce(info: any)
	-- Server announcements also go to chat so they're visible in the log.
	task.spawn(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local system = channels and channels:FindFirstChild("RBXSystem") :: TextChannel?
		if system then
			local color = (info.color or C.gold) :: Color3
			system:DisplaySystemMessage(string.format('<font color="#%s"><b>[%s]</b> %s</font>', color:ToHex(), info.title, info.text or ""))
		end
	end)
	if bannerBusy then
		table.insert(bannerQueue, info)
	else
		task.spawn(showBanner, info)
	end
end

-- Sailing transition --------------------------------------------------------------

function Notices.travel(info: any)
	local overlay = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 18, 32),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = gui,
	})
	local title = Kit.label({
		Text = "Sailing to " .. info.to,
		FontFace = Kit.Title,
		TextSize = 34,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(600, 44),
		TextTransparency = 1,
		ZIndex = 21,
		Parent = overlay,
	})
	local sub = Kit.label({
		Text = "Aboard your " .. info.boat,
		TextSize = 17,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.51),
		Size = UDim2.fromOffset(600, 28),
		TextTransparency = 1,
		ZIndex = 21,
		Parent = overlay,
	})
	local track = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.57),
		Size = UDim2.fromOffset(360, 6),
		BackgroundColor3 = C.panel3,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = overlay,
	}, { Kit.corner(3) })
	local fill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.text, BorderSizePixel = 0, ZIndex = 22, Parent = track }, { Kit.corner(3) })

	Kit.tween(overlay, 0.4, { BackgroundTransparency = 0 })
	Kit.tween(title, 0.4, { TextTransparency = 0 })
	Kit.tween(sub, 0.4, { TextTransparency = 0 })
	Kit.tween(fill, info.seconds, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
	task.wait(info.seconds + 0.3)
	Kit.tween(title, 0.6, { TextTransparency = 1 })
	Kit.tween(sub, 0.6, { TextTransparency = 1 })
	track.Visible = false
	Kit.tween(overlay, 0.8, { BackgroundTransparency = 1 }).Completed:Wait()
	overlay:Destroy()
end

function Notices.start()
	Net.event("Notify").OnClientEvent:Connect(function(info)
		local color = if info.kind == "achievement" then C.gold elseif info.kind == "secret" then Color3.new(1, 1, 1) elseif info.kind == "sell" then C.good else nil
		Notices.toast(info.title, info.text, color)
	end)
	Net.event("Announce").OnClientEvent:Connect(Notices.announce)
	Net.event("Travel").OnClientEvent:Connect(function(info)
		task.spawn(Notices.travel, info)
	end)
end

return Notices
