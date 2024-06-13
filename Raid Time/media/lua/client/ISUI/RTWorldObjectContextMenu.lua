--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTClient"
require "RTChat"
require "RTSafehouse"
require "ISWorldObjectContextMenu"

RTWorldObjectContextMenu = {
	default = {
		onTakeSafeHouse = ISWorldObjectContextMenu.onTakeSafeHouse,
		createMenu = ISWorldObjectContextMenu.createMenu
	}
}

--------------------------------
------ Override functions ------
--------------------------------

local function addTooltip(option, message)
	local toolTip = ISWorldObjectContextMenu.addToolTip()
    toolTip:setVisible(false)
    toolTip.description = message
    option.onSelect = nil
    option.notAvailable = true
    option.toolTip = toolTip
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
	local player = getSpecificPlayer(player)
	if clickedPlayer and clickedPlayer ~= player then
		local option = context:getOptionFromName(getText("ContextMenu_Trade", clickedPlayer:getDisplayName()))
		if option then
			addTooltip(option, getText("UI_RT_Tooltip_TradeDisabled"))
		end
	end
	
	if clickedSquare then
		local safehouse = RTSafehouse:getSafehouseNear(clickedSquare)
		if safehouse then
			local rtsafehouse = RTSafehouse:getByCoords(safehouse:getX(), safehouse:getY(), safehouse:getW(), safehouse:getH())
			if rtsafehouse then
				context:addOptionOnTop(getText("UI_RT_Context_RaidTime"), worldobjects, RTWorldObjectContextMenu.viewRaidTime, rtsafehouse)
			end
		end
	end
end

RTWorldObjectContextMenu.viewRaidTime = function(worldobjects, rtsafehouse)
	local date = RTCore:getDate(rtsafehouse.raidDay, rtsafehouse.raidHour, RTCore.timezone)
	RTChat:show(getText("UI_RT_Chat_RaidTime", RTCore.days[date.wday], RTCore:printHour(date.hour)))
	local nextRaidTime = RTSafehouse:getNextRaidTime(rtsafehouse)
	local delta = nextRaidTime - os.time()
	local oneDay = 24 * 60 * 60
	local oneHour = 60 * 60
	local oneMinute = 60
	local d = math.floor(delta / oneDay)
	local h = math.floor((delta - d * oneDay) / oneHour)
	local m = math.floor((delta - d * oneDay - h * oneHour) / oneMinute)
	RTChat:show(getText("UI_RT_Chat_AttackIn", d, h, m))
end

RTWorldObjectContextMenu.createMenu = function(playerId, worldobjects, x, y, test)
	local context = RTWorldObjectContextMenu.default.createMenu(playerId, worldobjects, x, y, test)
	if context then
		local option = context:getOptionFromName(getText("ContextMenu_SafehouseClaim"))
		if option then
			local player = getSpecificPlayer(playerId)
			local square = option.param1
			local hasInactiveSafehouse = RTSafehouse:hasInactiveSafehouse(player:getUsername())
			local isInactiveSafehouse = RTSafehouse:isInactiveSafehouse(square)
			local message = ""
			if hasInactiveSafehouse then
				message = getText("UI_RT_Tooltip_HasInactiveSafehouse")
			elseif isInactiveSafehouse then
				message = getText("UI_RT_Tooltip_InactiveSafehouse")
			end
			if hasInactiveSafehouse or isInactiveSafehouse then
				addTooltip(option, message)
			end
		end
	end
	return context
end

RTWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, playerId)
	local player = getSpecificPlayer(playerId)
	if RTSafehouse:hasInactiveSafehouse(player:getUsername()) then
		return
	end
	RTWorldObjectContextMenu.default.onTakeSafeHouse(worldobjects, square, playerId)
	LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
end

ISWorldObjectContextMenu.onTakeSafeHouse = RTWorldObjectContextMenu.onTakeSafeHouse
ISWorldObjectContextMenu.createMenu = RTWorldObjectContextMenu.createMenu

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
end