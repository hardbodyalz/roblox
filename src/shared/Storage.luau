--!strict
-- Storage capacity = storage upgrade tier + equipped boat's capacity (or unlimited with the pass).

local Equipment = require(script.Parent.Config.Equipment)

local Storage = {}

Storage.INFINITE = math.huge

function Storage.capacity(storageTier: number, boatId: string, infinite: boolean): number
	if infinite then
		return Storage.INFINITE
	end
	local tier = Equipment.storage[math.clamp(storageTier, 1, #Equipment.storage)]
	local boat = Equipment.boatsById[boatId]
	return tier.slots + (if boat then boat.capacity else 0)
end

return Storage
