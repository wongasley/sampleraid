--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

RTPlayerRespawn = { }

function RTPlayerRespawn:onPlayerDeath()
	sendClientCommand(getPlayer(), "client", "playerDeath", { })
end

function RTPlayerRespawn:disableRespawn(player)
	local playerName = player:getUsername()
	local safehouses = SafeHouse.getSafehouseList()
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i)
		if safehouse:isRespawnInSafehouse(playerName) then
			safehouse:setRespawnInSafehouse(false, playerName)
		end
	end
end

---------- Commands ------------

RTPlayerRespawn.banRespawnInSafehouse = function(args)
	RTPlayerRespawn:disableRespawn(getPlayer())
end

function RTPlayerRespawn:onServerCommand(command, args)
	if RTPlayerRespawn[command] then
        RTPlayerRespawn[command](args)
    end
end

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	Events.OnPlayerDeath.Add(RTPlayerRespawn.onPlayerDeath)
	Events.OnServerCommand.Add(RTPlayerRespawn.onServerCommand)
end