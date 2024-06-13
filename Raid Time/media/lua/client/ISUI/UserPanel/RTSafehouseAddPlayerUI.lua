--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTClient"
require "RTSafehouse"
require "ISSafehouseAddPlayerUI"

RTSafehouseAddPlayerUI = {
	default = {
		populateList = ISSafehouseAddPlayerUI.populateList,
		onClick = ISSafehouseAddPlayerUI.onClick
	}
}

--------------------------------
------ Override functions ------
--------------------------------

RTSafehouseAddPlayerUI.populateList = function(self)
	if self then
		RTSafehouseAddPlayerUI.default.populateList(self)
		print("POPULATE")
		print(#self.playerList.items)
		for i = 1, #self.playerList.items do
			print(self.playerList.items[i].item.username)
			print(RTSafehouse:hasInactiveSafehouse(self.playerList.items[i].item.username))
			if RTSafehouse:hasInactiveSafehouse(self.playerList.items[i].item.username) then
				self.playerList.items[i].item.tooltip = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse" , "")
			end
		end
	end
end

RTSafehouseAddPlayerUI.onClick = function(self, button)
	RTSafehouseAddPlayerUI.default.onClick(self, button)
	if button.internal == "ADDPLAYER" then
		LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
	end
end

--ISSafehouseAddPlayerUI.populateList = RTSafehouseAddPlayerUI.populateList
ISSafehouseAddPlayerUI.onClick = RTSafehouseAddPlayerUI.onClick

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	--Events[RTClient.events.safehousesSet].Add(RTSafehouseAddPlayerUI.populateList)
end