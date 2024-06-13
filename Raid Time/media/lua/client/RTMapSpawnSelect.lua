--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "MapSpawnSelect"

RTMapSpawnSelect = {
	default = {
		getSafehouseSpawnRegion = MapSpawnSelect.getSafehouseSpawnRegion
	}
}

--------------------------------
------ Override functions ------
--------------------------------

RTMapSpawnSelect.getSafehouseSpawnRegion = function(self)
	local spawnRegion = RTMapSpawnSelect.default.getSafehouseSpawnRegion()
	
	-- Fix the error in game: safehouse owner always spawns in safehouse regardless of option selected
	-- Update: this error has been fixed in 41.77 patch
	local player = getPlayer()
	if player then
		local playerName = player:getUsername()
		local deleteSpawnRegion = true
		for i = 0,SafeHouse.getSafehouseList():size() - 1 do
			local safehouse = SafeHouse.getSafehouseList():get(i)
			if safehouse:isRespawnInSafehouse(playerName) and (safehouse:getPlayers():contains(playerName) or safehouse:getOwner() == playerName) then
				deleteSpawnRegion = false
			end
		end
		if deleteSpawnRegion then
			return nil
		else
			return spawnRegion
		end
	end
	
	return spawnRegion
end

--MapSpawnSelect.getSafehouseSpawnRegion = RTMapSpawnSelect.getSafehouseSpawnRegion
