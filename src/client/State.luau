--!strict
-- Client-side mirror of the player's profile, kept in sync by the server's Sync remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local State = {}

State.data = nil :: any
local listeners: { (changed: { [string]: boolean }) -> () } = {}

local function fire(changed: { [string]: boolean })
	for _, fn in listeners do
		task.spawn(fn, changed)
	end
end

-- fn receives the set of top-level keys that changed ("*" on the first full sync).
function State.onChange(fn: (changed: { [string]: boolean }) -> ()): () -> ()
	table.insert(listeners, fn)
	if State.data then
		task.spawn(fn, { ["*"] = true })
	end
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

function State.wait(): any
	while not State.data do
		task.wait()
	end
	return State.data
end

function State.passes(): { [string]: boolean }
	return (State.data and State.data.passes) or {}
end

function State.inventoryCount(): number
	local n = 0
	if State.data then
		for _ in State.data.inventory do
			n += 1
		end
	end
	return n
end

Net.event("Sync").OnClientEvent:Connect(function(kind: string, payload: any)
	if kind == "full" then
		State.data = payload
		fire({ ["*"] = true })
		return
	end
	if not State.data then
		return
	end
	if kind == "patch" then
		local changed = {}
		for k, v in payload do
			State.data[k] = v
			changed[k] = true
		end
		fire(changed)
	elseif kind == "inv" then
		if payload.add then
			for uid, item in payload.add do
				State.data.inventory[uid] = item
			end
		end
		if payload.remove then
			for _, uid in payload.remove do
				State.data.inventory[uid] = nil
			end
		end
		fire({ inventory = true })
	elseif kind == "collection" then
		local entry = State.data.collection[payload.c]
		if not entry then
			entry = {}
			State.data.collection[payload.c] = entry
		end
		entry[payload.m] = true
		fire({ collection = true })
	end
end)

return State
