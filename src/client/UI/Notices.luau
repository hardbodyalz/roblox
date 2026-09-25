--!strict
-- Toasts (personal), announcements (server-wide) and the sailing transition.

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

local toastStack = Kit.new("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -150),
	Size = UDim2.fromOffset(300, 400),
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
	local frame = Kit.new("Frame", {
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = toastOrder,
		Parent = toastStack,
	}, {
		Kit.corner(10),
		Kit.stroke(color or C.accent, 2, 0.2),
		Kit.padding(10),
		Kit.list(2),
		Kit.label({ Text = title, Font = Kit.Font, TextSize = 18, TextColor3 = color or C.accent, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }),
		Kit.label({ Text = text or "", TextSize = 14, TextColor3 = C.muted, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = text ~= nil and text ~= "" }),
	})
	task.delay(4, function()
		for _, d in frame:GetDescendants() do
			if d:IsA("TextLabel") then
				Kit.tween(d, 0.4, { TextTransparency = 1 })
			elseif d:IsA("UIStroke") then
				Kit.tween(d, 0.4, { Transparency = 1 })
			end
		end
		Kit.tween(frame, 0.4, { BackgroundTransparency = 1 }).Completed:Wait()
		frame:Destroy()
	end)
end

function Notices.error(text: string)
	Notices.toast(text, nil, C.bad)
end

-- Server-wide banner ------------------------------------------------------------

local bannerQueue: { any } = {}
local bannerBusy = false

local function showBanner(info: any)
	bannerBusy = true
	local color: Color3 = info.color or C.gold
	local big = info.big == true
	local banner = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -120),
		Size = UDim2.fromOffset(if big then 640 else 520, if big then 96 else 72),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, {
		Kit.corner(12),
		Kit.stroke(color, 3),
	})
	local title = Kit.label({
		Text = info.title,
		Font = Kit.Font,
		TextSize = if big then 34 else 26,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, if big then 44 else 32),
		Position = UDim2.fromOffset(10, 6),
		TextStrokeTransparency = 0.4,
		Parent = banner,
	})
	if big then
		Kit.gradient(color, Color3.new(1, 1, 1), true).Parent = title
	end
	Kit.label({
		Text = info.text or "",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -20, 0, 36),
		Position = UDim2.fromOffset(10, if big then 50 else 36),
		Parent = banner,
	})
	Kit.tween(banner, 0.5, { Position = UDim2.new(0.5, 0, 0, 70) }, Enum.EasingStyle.Back)
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
		if info.quiet then
			return
		end
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
		BackgroundColor3 = Color3.fromRGB(10, 25, 45),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = gui,
	})
	local title = Kit.label({
		Text = "⛵ Sailing to " .. info.to .. "...",
		Font = Kit.Font,
		TextSize = 36,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(600, 50),
		TextTransparency = 1,
		ZIndex = 21,
		Parent = overlay,
	})
	local sub = Kit.label({
		Text = "Aboard your " .. info.boat,
		TextSize = 18,
		TextColor3 = C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(600, 30),
		TextTransparency = 1,
		ZIndex = 21,
		Parent = overlay,
	})
	local track = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromOffset(360, 10),
		BackgroundColor3 = C.panel3,
		ZIndex = 21,
		Parent = overlay,
	}, { Kit.corner(5) })
	local fill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.accent, ZIndex = 22, Parent = track }, { Kit.corner(5) })

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
