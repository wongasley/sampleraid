--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTClient"
require "ISAddSafeZoneUI"

RTAddSafeZoneUI = {
	default = {
		onClick = ISAddSafeZoneUI.onClick
	}
}

--------------------------------
------ Override functions ------
--------------------------------

RTAddSafeZoneUI.onClick = function(self, button)
	RTAddSafeZoneUI.default.onClick(self, button)
	if button.internal == "OK" then
		LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
	end
end

ISAddSafeZoneUI.onClick = RTAddSafeZoneUI.onClick