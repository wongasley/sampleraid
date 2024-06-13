--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTChat"

RTClient = {
	events = {
		safehousesSet = "safehousesSet",
		safehouseChanged = "safehouseChanged"
	}
}

--------------------------------
------ Private functions -------
--------------------------------

function RTClient:onSafehouseChanged()
	sendClientCommand(getPlayer(), "client", "safehouseChanged", { })
end

---------- Commands ------------

RTClient.setSettings = function(settings)
	if settings then
		RTCore.settings = settings
		RTCore.modLoaded = true
	end
end

RTClient.setSafehouses = function(rtsafehouses)
	if rtsafehouses then
		RTCore.safehouses = rtsafehouses
	else
		RTCore.safehouses = { }
	end
	LuaEventManager.triggerEvent(RTClient.events.safehousesSet)
end

RTClient.raidStarted = function(args)
	RTChat:show(getText("UI_RT_Chat_RaidTimeStarted"))
end

RTClient.raidFinished = function(args)
	RTChat:show(getText("UI_RT_Chat_RaidTimeFinished"))
end

function RTClient:onServerCommand(command, args)
	print(command)
	if RTClient[command] then
        RTClient[command](args)
    end
end

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	LuaEventManager.AddEvent(RTClient.events.safehousesSet)
	LuaEventManager.AddEvent(RTClient.events.safehouseChanged)
	Events[RTClient.events.safehouseChanged].Add(RTClient.onSafehouseChanged)
	Events.AcceptedSafehouseInvite.Add(RTClient.onSafehouseChanged)
	Events.OnServerCommand.Add(RTClient.onServerCommand)
end