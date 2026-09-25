--!strict
-- Remote definitions. The server creates them; clients wait for them.
--
-- Client -> Server:
--   Request (RemoteFunction): (action: string, payload: any) -> (ok: boolean, result: any)
-- Server -> Client:
--   Sync         full state or a patch of it
--   Bite         a Waifu is on the line; start the shake + reel minigame
--   Notify       small toast
--   Announce     server-wide banner (rare catches, weather)
--   Travel       play the sailing transition
--   FishingFx    everyone's bobbers and catches, so the whole server sees Waifus surface:
--                { kind = "cast" | "bite" | "catch" | "clear", userId, target?, c?, m?, w? }

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = { "Sync", "Bite", "Notify", "Announce", "Travel", "FishingFx" }
local FUNCTIONS = { "Request" }

local Net = {}

local folder: Folder
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	for _, name in FUNCTIONS do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Net.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return Net
