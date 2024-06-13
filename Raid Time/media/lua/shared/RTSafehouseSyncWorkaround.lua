--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

RTSafehouseSyncWorkaround = { }

function RTSafehouseSyncWorkaround:sharedAddSafehouse(rtsafehouse)
	if SafeHouse.getSafeHouse(rtsafehouse.x, rtsafehouse.y, rtsafehouse.w, rtsafehouse.h) or SafeHouse.hasSafehouse(rtsafehouse.data.owner) then
		return
	end
	local safehouse = SafeHouse.addSafeHouse(rtsafehouse.x, rtsafehouse.y, rtsafehouse.w, rtsafehouse.h, rtsafehouse.data.owner, false)
	safehouse:setLastVisited(rtsafehouse.data.lastVisited)
	safehouse:setTitle(rtsafehouse.data.title)
	local players = rtsafehouse.data.players
	for i = 1, #players do
		local playerName = players[i]
		if not SafeHouse.hasSafehouse(playerName) or safehouse:getOwner() == playerName then
			safehouse:addPlayer(playerName)
		end
	end
	local playersRespawn = rtsafehouse.data.playersRespawn
	for i = 1, #playersRespawn do
		local playerName = playersRespawn[i]
		safehouse:setRespawnInSafehouse(true, playerName)
	end
end

function RTSafehouseSyncWorkaround:serverSend(rtsafehouse)
	local players = getOnlinePlayers()
	if players then
		for i = 0, players:size() - 1 do
			local player = players:get(i)
			sendServerCommand(player, "server", "addSafehouse", rtsafehouse)
		end
	end
end

---------- Commands ------------

RTSafehouseSyncWorkaround.addSafehouse = function(rtsafehouse)
	RTSafehouseSyncWorkaround:sharedAddSafehouse(rtsafehouse)
end

function RTSafehouseSyncWorkaround:onServerCommand(command, args)
	if RTSafehouseSyncWorkaround[command] then
        RTSafehouseSyncWorkaround[command](args)
    end
end

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	Events.OnServerCommand.Add(RTSafehouseSyncWorkaround.onServerCommand)
end