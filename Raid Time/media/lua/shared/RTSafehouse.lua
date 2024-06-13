--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTSafehouseSyncWorkaround"

RTSafehouse = { }

function RTSafehouse:check(rtsafehouse)
	if type(rtsafehouse) ~= "table" or
	   type(rtsafehouse.x) ~= "number" or
	   type(rtsafehouse.y) ~= "number" or
	   type(rtsafehouse.w) ~= "number" or
	   type(rtsafehouse.h) ~= "number" or
	   type(rtsafehouse.raidDay) ~= "number" or
	   type(rtsafehouse.raidHour) ~= "number" or
	   type(rtsafehouse.lastRaid) ~= "number" or
	   type(rtsafehouse.isActive) ~= "boolean" then
		return false
	end
	if not RTCore:isCorrect(rtsafehouse.raidDay, RTCore.intervals.day) or
	   not RTCore:isCorrect(rtsafehouse.raidHour, RTCore.intervals.hour) then
		return false
	end
	if rtsafehouse.isActive then
		if rtsafehouse.data ~= nil then
			return false
		end
	else
		if type(rtsafehouse.data) ~= "table" then
			return false
		end
		if type(rtsafehouse.data.owner) ~= "string" or
	   	   type(rtsafehouse.data.players) ~= "table" or
	       type(rtsafehouse.data.lastVisited) ~= "number" or
	       type(rtsafehouse.data.title) ~= "string" or
	       type(rtsafehouse.data.playersRespawn) ~= "table" or
	       type(rtsafehouse.data.playersBan) ~= "table" then
	       	return false
	    end
	end
	return true
end

function RTSafehouse:getByCoords(x, y, w, h)
	for i = 1, #RTCore.safehouses do
		local rtsafehouse = RTCore.safehouses[i]
		if rtsafehouse and rtsafehouse.x == x and rtsafehouse.y == y and rtsafehouse.w == w and rtsafehouse.h == h then
			return rtsafehouse
		end
	end
	return nil
end

function RTSafehouse:getByPlayer(player)
	local username = player:getUsername()
	local safehouses = SafeHouse:getSafehouseList()
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i)
		if safehouse and safehouse:playerAllowed(username) then
			return RTSafehouse:getByCoords(safehouse:getX(), safehouse:getY(), safehouse:getW(), safehouse:getH())
		end
	end
	return nil
end

function RTSafehouse:addNew(safehouse)
	local date = os.date("!*t")
	rtsafehouse = {
		x = safehouse:getX(),
		y = safehouse:getY(),
		w = safehouse:getW(),
		h = safehouse:getH(),
		raidDay = date.wday,
		raidHour = date.hour,
		lastRaid = os.time({ year = date.year, month = date.month, day = date.day, hour = date.hour }),
		isActive = true
	}
	table.insert(RTCore.safehouses, rtsafehouse)
end

function RTSafehouse:canChangeRaidTime(player, safehouse, rtsafehouse)
	if not safehouse:isOwner(player) or
	safehouse:getX() ~= rtsafehouse.x or
	safehouse:getY() ~= rtsafehouse.y or
	safehouse:getW() ~= rtsafehouse.w or
	safehouse:getH() ~= rtsafehouse.h or
	os.time() - rtsafehouse.lastRaid > RTCore.settings.RaidTimeChangePeriodInHours * 60 * 60 then
		return false
	else
		return true
	end
end

function RTSafehouse:hasInactiveSafehouse(playerName)
	for i = 1, #RTCore.safehouses do
		local rtsafehouse = RTCore.safehouses[i]
		if rtsafehouse and rtsafehouse.isActive == false then
			if rtsafehouse.data.owner == playerName or rtsafehouse.data.players[playerName] ~= nil then
				return true
			end
		end
	end
	return false
end

function RTSafehouse:isInactiveSafehouse(square)
	for i = 1, #RTCore.safehouses do
		local rtsafehouse = RTCore.safehouses[i]
		if rtsafehouse and rtsafehouse.isActive == false then
			local x = square:getX()
			local y = square:getY()
			if rtsafehouse.x <= x and x <= rtsafehouse.x + rtsafehouse.w and
			   rtsafehouse.y <= y and y <= rtsafehouse.y + rtsafehouse.h then
			   	return true
			end
		end
	end
	return false
end

function RTSafehouse:getSafehouseNear(square)
	local safehouses = SafeHouse.getSafehouseList()
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i)
		if safehouse:getX() - 1 <= square:getX() and square:getX() <= safehouse:getX2() + 1 and
		   safehouse:getY() - 1 <= square:getY() and square:getY() <= safehouse:getY2() + 1 then
			return safehouse
		end
	end
	return nil
end

---------- Raid Time -----------

local function getNextDate(time, wday, isPreviousDateInstead)
	local date = nil
	local dayInterval = 24 * 60 * 60
	if isPreviousDateInstead then
		dayInterval = -1 * dayInterval
	end
	for i = 0, 6 do
		local t = time + i * dayInterval
		local d = os.date("!*t", t)
		if d.wday == wday then 
			date = d
			break
		end
	end
	return date
end

function RTSafehouse:getNextRaidTime(rtsafehouse)
	local monday = 2
	local oneWeek = 7 * 24 * 60 * 60
	local lastRaidWeekDate = getNextDate(rtsafehouse.lastRaid, monday, true)
	local lastRaidWeekBeginningTime = os.time({ year = lastRaidWeekDate.year, month = lastRaidWeekDate.month, day = lastRaidWeekDate.day, hour = 0 })
	local timeoutPeriod = RTCore.settings.RaidFrequencyEveryNWeeks * oneWeek
	local nextRaidWeekBeginningTime = lastRaidWeekBeginningTime + timeoutPeriod
	local nextRaidDate = getNextDate(nextRaidWeekBeginningTime, rtsafehouse.raidDay, false)
	local nextRaidTime = os.time({ year = nextRaidDate.year, month = nextRaidDate.month, day = nextRaidDate.day, hour = rtsafehouse.raidHour })
	local changePeriod = RTCore.settings.RaidTimeChangePeriodInHours * 60 * 60
	local diff = nextRaidTime - rtsafehouse.lastRaid
	local currentTime = os.time()
	if diff < changePeriod then
		nextRaidTime = nextRaidTime + math.ceil((changePeriod - diff) / oneWeek) * oneWeek
	end
	if nextRaidTime < currentTime then
		nextRaidTime = nextRaidTime + math.ceil((currentTime - nextRaidTime) / oneWeek) * oneWeek
	end
	
	return nextRaidTime
end

function RTSafehouse:inCorrectRaidTimeRange(rtsafehouse)
	local currentTime = os.time()
	local oneHour = 60 * 60
	local startDate = getNextDate(currentTime, rtsafehouse.raidDay, true)
	local startTime = os.time({ year = startDate.year, month = startDate.month, day = startDate.day, hour = rtsafehouse.raidHour })
	local raidLength = RTCore.settings.RaidTimeLengthInHours * oneHour
	local endTime = startTime + raidLength
	
	return startTime <= currentTime and currentTime <= endTime
end

function RTSafehouse:changePeriodPassed(rtsafehouse)
	local currentTime = os.time()
	local oneHour = 60 * 60
	local changePeriod = RTCore.settings.RaidTimeChangePeriodInHours * oneHour
	
	return (currentTime - rtsafehouse.lastRaid) >= changePeriod
end

function RTSafehouse:timeoutPeriodPassed(rtsafehouse)
	local monday = 2
	local oneWeek = 7 * 24 * 60 * 60
	local currentTime = os.time()
	local lastRaidWeekDate = getNextDate(rtsafehouse.lastRaid, monday, true)
	local lastRaidWeekBeginningTime = os.time({ year = lastRaidWeekDate.year, month = lastRaidWeekDate.month, day = lastRaidWeekDate.day, hour = 0 })
	local thisWeekDate = getNextDate(currentTime, monday, true)
	local thisWeekBeginningTime = os.time({ year = thisWeekDate.year, month = thisWeekDate.month, day = thisWeekDate.day, hour = 0 })
	local timeoutPeriod = RTCore.settings.RaidFrequencyEveryNWeeks * oneWeek
	
	return (thisWeekBeginningTime - lastRaidWeekBeginningTime) >= timeoutPeriod
end

function RTSafehouse:shouldStartRaidTime(rtsafehouse)
	if rtsafehouse.isActive and
	   RTSafehouse:inCorrectRaidTimeRange(rtsafehouse) and
	   (RTCore.settings.TestMode == 1 or (RTSafehouse:changePeriodPassed(rtsafehouse) and RTSafehouse:timeoutPeriodPassed(rtsafehouse))) then
		return true
	end
	return false
end

function RTSafehouse:shouldEndRaidTime(rtsafehouse)
	if not rtsafehouse.isActive and
	   not RTSafehouse:inCorrectRaidTimeRange(rtsafehouse) then
	   	return true
	end
	return false
end

function RTSafehouse:startRaidTime(rtsafehouse, safehouse)
	rtsafehouse.data = { }
	rtsafehouse.data.owner = safehouse:getOwner()
	rtsafehouse.data.players = { }
	rtsafehouse.data.playersRespawn = { }
	rtsafehouse.data.playersBan = { }
	local players = safehouse:getPlayers()
	for i = 0, players:size() - 1 do
		local playerName = players:get(i)
		table.insert(rtsafehouse.data.players, playerName)
		if safehouse:isRespawnInSafehouse(playerName) then
			table.insert(rtsafehouse.data.playersRespawn, playerName)
		end
	end
	rtsafehouse.data.lastVisited = safehouse:getLastVisited()
	rtsafehouse.data.title = safehouse:getTitle()
	local currentTime = os.time()
	local lastRaidDate = getNextDate(currentTime, rtsafehouse.raidDay, true)
	rtsafehouse.lastRaid = os.time({ year = lastRaidDate.year, month = lastRaidDate.month, day = lastRaidDate.day, hour = rtsafehouse.raidHour })
	rtsafehouse.isActive = false
	local owner = getPlayerFromUsername(safehouse:getOwner())
	RTSafehouse:sendAll(safehouse, "raidStarted")
	safehouse:removeSafeHouse(owner)
end

function RTSafehouse:endRaidTime(rtsafehouse)
	RTSafehouseSyncWorkaround:sharedAddSafehouse(rtsafehouse)
	RTSafehouseSyncWorkaround:serverSend(rtsafehouse)
	local safehouse = SafeHouse.getSafeHouse(rtsafehouse.x, rtsafehouse.y, rtsafehouse.w, rtsafehouse.h)
	if safehouse then
		RTSafehouse:sendAll(safehouse, "raidFinished")
	end
	rtsafehouse.data = nil
	rtsafehouse.isActive = true
end

function RTSafehouse:sendAll(safehouse, command)
	local players = getOnlinePlayers()
	if players then
		for i = 0, players:size() - 1 do
			local player = players:get(i)
			if safehouse:playerAllowed(player:getUsername()) then
				sendServerCommand(player, "server", command, { })
			end
		end
	end
end