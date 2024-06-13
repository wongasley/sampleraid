--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTSafehouse"
require "RTPlayerRespawn"

local JSON = require "JSON"

RTServer = {
	settingsFileName = "RaidTimeSettings.ini",
	safehousesFileName = "RaidTimeData"
}

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

--------------------------------
------- Public functions -------
--------------------------------

function RTServer:init()
	print("[Raid Time] Initializing mod..")
	RTServer:loadSettings()
	RTServer:loadSafehouses()
	RTServer:updateSafehouses()
	print("[Raid Time] Mod initialization COMPLETED")
	RTCore.modLoaded = true
end

--------------------------------
------ Private functions -------
--------------------------------

---------- Settings ------------

function RTServer:loadSettings()
	print("[Raid Time] Loading settings..")
	local reader = getFileReader(RTServer.settingsFileName, false)
	if reader then
		print("[Raid Time] Settings file found. Reading..")
		local n = 1
		local line = reader:readLine()
		while line do
			local setting = line:trim():split("=")
			if #setting ~= 2 then
				print("[Raid Time] ERROR! Unable to parse setting at line "..tostring(n))
			else
				local value = tonumber(setting[2])
				if value then
					RTCore.settings[setting[1]] = value
				else
					print("[Raid Time] ERROR! \""..setting[2].."\" is not valid value for \""..setting[1].."\". Setting the default value")
					RTCore.settings[setting[1]] = RTCore.default.settings[setting[1]]
				end
			end
			n = n + 1
			line = reader:readLine()
		end
		print("[Raid Time] Finished loading settings from the file")
		RTServer:checkSettings()
	else
		print("[Raid Time] No settings file \""..RTServer.settingsFileName.."\" found")
		RTServer:createSettingsFile()
		RTServer:setDefaultSettings()
	end
	print("[Raid Time] Loading of settings completed")
end

function RTServer:createSettingsFile()
	print("[Raid Time] Creating a new settings file..")
	local writer = getFileWriter(RTServer.settingsFileName, false, false)
	for key, value in pairs(RTCore.default.settings) do
		writer:write(key.."="..value.."\r\n")
	end
	writer:close()
	print("[Raid Time] Settings file created")
end

function RTServer:setDefaultSettings()
	print("[Raid Time] Setting the default settings..")
	RTCore.settings = RTCore.default.settings
	print("[Raid Time] Settings have been set")
end

function RTServer:checkSettings()
	print("[Raid Time] Checking settings..")
	for key, value in pairs(RTCore.default.settings) do
		if not RTCore.settings[key] then
			print("[Raid Time] ERROR! Setting \""..key.."\" was not found")
			RTServer:createSettingsFile()
			RTServer:setDefaultSettings()
			return
		end
		local interval = RTCore.default.intervals[key]
		if interval then
			if (RTCore.settings[key] < interval.min) or (RTCore.settings[key] > interval.max) then
				print("[Raid Time] ERROR! Setting \""..key.."\" has a wrong value. Setting the default one")
				RTCore.settings[key] = value
			end
		end
	end
end

--------- Safehouses -----------

function RTServer:loadSafehouses()
	print("[Raid Time] Loading safehouses..")
	local reader = getFileReader(RTServer.safehousesFileName, false)
	local text = ""
	
	if reader then
		local line = reader:readLine()
		while line do
			text = text..line
			line = reader:readLine()
		end
		RTCore.safehouses = JSON:decode(text)
		if RTCore.safehouses then
			RTServer:checkLoadedSafehouses()
		else
			RTCore.safehouses = { }
			print("[Raid Time] ERROR! Safehouses file is broken. No safehouses were loaded")
		end
	else
		print("[Raid Time] No safehouses file \""..RTServer.safehousesFileName.."\" found")
	end
	print("[Raid Time] Loading of safehouses completed")
end

function RTServer:checkLoadedSafehouses()
	print("[Raid Time] Checking loaded safehouses..")
	for i = #RTCore.safehouses, 1, -1 do
		local rtsafehouse = RTCore.safehouses[i]
		if not RTSafehouse:check(rtsafehouse) then
			print("[Raid Time] ERROR! Safehouse data is incorrect. Removing..")
			table.remove(RTCore.safehouses, i)
		end
	end
	print("[Raid Time] Safehouses checking completed")
end

function RTServer:updateSafehouses()
	print("[Raid Time] Updating safehouses..")
	local safehouses = SafeHouse.getSafehouseList()
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i)
		local rtsafehouse = RTSafehouse:getByCoords(safehouse:getX(), safehouse:getY(), safehouse:getW(), safehouse:getH())
		if rtsafehouse then
			rtsafehouse.isActive = true
			rtsafehouse.data = nil
		else
			RTSafehouse:addNew(safehouse)
		end
	end
	print("[Raid Time] Updating of safehouses completed")
	RTServer:saveSafehouses()
	RTServer:sendSafehouses()
end

function RTServer:saveSafehouses()
	print("[Raid Time] Saving safehouses..")
	local writer = getFileWriter(RTServer.safehousesFileName, false, false)
	writer:write(JSON:encode(RTCore.safehouses))
	writer:close()
	print("[Raid Time] Saving of safehouses completed")
end

function RTServer:sendSafehouses()
	print("[Raid Time] Sending safehouses to players..")
	local players = getOnlinePlayers()
	if players then
		for i = 0, players:size() - 1 do
			local player = players:get(i)
			RTServer:sendSafehousesTo(player)
		end
	end
	print("[Raid Time] Sending of safehouses completed")
end

function RTServer:sendSafehousesTo(player)
	sendServerCommand(player, "server", "setSafehouses", RTCore.safehouses)
end

function RTServer:checkRaidTime()
	if RTCore.modLoaded then
		print("[Raid Time] Checking safehouses..")
		local hasChanges = false
		for i = #RTCore.safehouses, 1, -1 do
			local rtsafehouse = RTCore.safehouses[i]
			if RTSafehouse:shouldStartRaidTime(rtsafehouse) then
				local safehouse = SafeHouse.getSafeHouse(rtsafehouse.x, rtsafehouse.y, rtsafehouse.w, rtsafehouse.h)
				if safehouse then
					print("[Raid Time] Start raid time for safehouse of owner \""..safehouse:getOwner().."\"")
					RTSafehouse:startRaidTime(rtsafehouse, safehouse)
				else
					table.remove(RTCore.safehouses, i)
				end
				hasChanges = true
			elseif RTSafehouse:shouldEndRaidTime(rtsafehouse) then
				print("[Raid Time] End raid time for safehouse of owner \""..rtsafehouse.data.owner.."\"")
				RTSafehouse:endRaidTime(rtsafehouse)
				hasChanges = true
			end
		end
		if hasChanges then
			RTServer:saveSafehouses()
			RTServer:sendSafehouses()
		end
		print("[Raid Time] Checking of safehouses completed")
	end
end

----------- Commands -----------

RTServer.writeLog = function(player, args)
	if type(args.logText) == "string" and args.logText:find("Login") then
		sendServerCommand(player, "server", "setSettings", RTCore.settings)
		RTServer:sendSafehousesTo(player)
	end
end

RTServer.raidTimeChange = function(player, args)
	local rtsafehouse = RTSafehouse:getByPlayer(player)
	local day = args[1]
	local hour = args[2]
	if rtsafehouse and RTCore:isCorrect(day, RTCore.intervals.day) and RTCore:isCorrect(hour, RTCore.intervals.hour) then
		local safehouse = SafeHouse.getSafeHouse(rtsafehouse.x, rtsafehouse.y, rtsafehouse.w, rtsafehouse.h)
		if safehouse and RTSafehouse:canChangeRaidTime(player, safehouse, rtsafehouse) then
			rtsafehouse.raidDay = day
			rtsafehouse.raidHour = hour
			print("[Raid Time] Player \""..player:getUsername().."\" changed the raid time")
			RTServer:saveSafehouses()
			RTServer:sendSafehouses()
		end
	end
end

RTServer.playerDeath = function(player, args)
	local x = player:getX()
	local y = player:getY()
	if type(x) == "number" and type(y) == "number" then
		local distance = 100
		local banRespawnInSafehouse = false
		local newBan = false
		for i = 1, #RTCore.safehouses do
			local rtsafehouse = RTCore.safehouses[i]
			if rtsafehouse and rtsafehouse.isActive == false then
				local playerName = player:getUsername()
				if table.contains(rtsafehouse.data.playersBan, playerName) then
					banRespawnInSafehouse = true
				elseif rtsafehouse.x - distance <= x and x <= rtsafehouse.x + rtsafehouse.w + distance and
			           rtsafehouse.y - distance <= y and y <= rtsafehouse.y + rtsafehouse.h + distance then
			        table.insert(rtsafehouse.data.playersBan, playerName)
			        banRespawnInSafehouse = true
			        newBan = true
			        print("[Raid Time] New respawn ban for \""..player:getUsername().."\" in x:"..tostring(rtsafehouse.x).." y:"..tostring(rtsafehouse.y))
			    end
			end
		end
		if newBan then
			RTServer:saveSafehouses()
			RTServer:sendSafehouses()
		end
		if banRespawnInSafehouse then
			RTPlayerRespawn:disableRespawn(player)
			print("[Raid Time] Send respawn ban for \""..player:getUsername().."\"")
			sendServerCommand(player, "server", "banRespawnInSafehouse", { })
		end
	end
end

RTServer.safehouseChanged = function()
	RTServer:updateSafehouses()
end

function RTServer:onClientCommand(command, player, args)
	--print(command)
    if RTServer[command] then
        RTServer[command](player, args)
    end
end

--------------------------------
----------- Events -------------
--------------------------------

if isServer() then
	Events.OnServerStarted.Add(RTServer.init)
	Events.EveryTenMinutes.Add(RTServer.checkRaidTime)
	Events.OnClientCommand.Add(RTServer.onClientCommand)
end