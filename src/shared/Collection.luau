--!strict
-- Collection Book helpers shared by server (achievements) and client (the book UI).
-- collection data shape: { [characterId]: { [mutationId]: true } }

local Config = script.Parent.Config
local Islands = require(Config.Islands)
local Characters = require(Config.Characters)

local Collection = {}

-- Characters listed under an island's page, in table order. Global secrets get their own page.
function Collection.roster(islandId: string): { string }
	local out = {}
	if islandId == "secrets" then
		for _, entry in Islands.globalTable do
			table.insert(out, entry.id)
		end
		return out
	end
	for _, entry in Islands.byId[islandId].table do
		table.insert(out, entry.id)
	end
	return out
end

function Collection.pages(): { { id: string, name: string } }
	local out = {}
	for _, island in Islands.list do
		table.insert(out, { id = island.id, name = island.name })
	end
	table.insert(out, { id = "secrets", name = "Open Sea" })
	return out
end

-- Discovered / total, counting hidden characters only once they've been found.
function Collection.progress(collection: { [string]: any }, islandId: string): (number, number)
	local found, total = 0, 0
	for _, id in Collection.roster(islandId) do
		local discovered = collection[id] ~= nil
		if discovered or not Characters.byId[id].hidden then
			total += 1
		end
		if discovered then
			found += 1
		end
	end
	return found, total
end

-- Every non-hidden character on the island discovered.
function Collection.islandComplete(collection: { [string]: any }, islandId: string): boolean
	for _, id in Collection.roster(islandId) do
		if not Characters.byId[id].hidden and collection[id] == nil then
			return false
		end
	end
	return true
end

return Collection
