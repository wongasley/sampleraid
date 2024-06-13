--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTClient"
require "RTSafehouse"
require "ISSafehouseUI"

local unknownRaidTime = "?"

RTSafehouseUI = {
	default = {
		initialise = ISSafehouseUI.initialise,
		prerender = ISSafehouseUI.prerender,
		updateButtons = ISSafehouseUI.updateButtons,
		onReleaseSafehouse = ISSafehouseUI.onReleaseSafehouse,
		onQuitSafehouse = ISSafehouseUI.onQuitSafehouse,
		onRemovePlayerFromSafehouse = ISSafehouseUI.onRemovePlayerFromSafehouse
	}
}

--------------------------------
------ Private functions -------
--------------------------------

function RTSafehouseUI:update()
	local self = ISSafehouseUI.instance
	if self then
		local player = self.player
		local safehouse = self.safehouse
		local rtsafehouse = RTSafehouse:getByCoords(safehouse:getX(), safehouse:getY(), safehouse:getW(), safehouse:getH())
		if rtsafehouse then
			local date = RTCore:getDate(rtsafehouse.raidDay, rtsafehouse.raidHour, RTCore.timezone)
			self.raidTime = RTCore.days[date.wday].." "..RTCore:printHour(date.hour)
			if RTSafehouse:canChangeRaidTime(player, safehouse, rtsafehouse) then
				self.raidTimeButtonEnabled = true
				self.raidTimeButtonTooltip = nil
			else
				self.raidTimeButtonEnabled = false
				if RTCore.settings.RaidTimeChangePeriodInHours == 1 then
					self.raidTimeButtonTooltip = getText("UI_RT_Tooltip_RaidTimeChangeTooLateOneHour")
				else
					self.raidTimeButtonTooltip =  string.format(getText("UI_RT_Tooltip_RaidTimeChangeTooLateNHours"), RTCore.settings.RaidTimeChangePeriodInHours)
				end
			end
		else
			self.raidTime = unknownRaidTime
			self.raidTimeButtonEnabled = false
			self.raidTimeButtonTooltip = nil
		end
	end
end

RTSafehouseUI.raidTimeChangeClicked = function(self)
	local modal = RTSafehouseChangeRaidTimeUI:new(0, 0, self.safehouse)
    modal:initialise()
    modal:addToUIManager()
    modal.ui = self
    modal.moveWithMouse = true
end

RTSafehouseUI.getYPosition = function(self)
	local y = 20 -- default value
	local name = getText("IGUI_SafehouseUI_Pos")
	
	for _,child in pairs(self:getChildren()) do
        if child.name == name then
            y = child.y
        end
    end
    
    return y
end

RTSafehouseUI.addRaidTimeUIElements = function(self)
	local x = self:getWidth() / 2
	local y = RTSafehouseUI.getYPosition(self)
	local fontHeight = getTextManager():getFontHeight(UIFont.Small)
	
	local titleLabel = ISLabel:new(x, y, fontHeight, getText("UI_RT_Label_RaidTime"), 1, 1, 1, 1, UIFont.Small, true)
	titleLabel:initialise()
    titleLabel:instantiate()
    self:addChild(titleLabel)
    
    self.raidTimeLabel = ISLabel:new(titleLabel:getRight() + 8, y, fontHeight, RTSafehouseUI.raidTime, 0.6, 0.6, 0.8, 1.0, UIFont.Small, true)
    self.raidTimeLabel:initialise()
    self.raidTimeLabel:instantiate()
    self:addChild(self.raidTimeLabel)
    
    local raidTimeInfo = ""
    if RTCore.settings.RaidFrequencyEveryNWeeks == 1 then
    	raidTimeInfo = getText("UI_RT_Tooltip_RaidTimeInfoOneWeek")
	else
		raidTimeInfo = string.format(getText("UI_RT_Tooltip_RaidTimeInfoNWeeks"), RTCore.settings.RaidFrequencyEveryNWeeks)
	end
	if RTCore.settings.RaidTimeLengthInHours == 1 then
    	raidTimeInfo = raidTimeInfo..getText("UI_RT_Tooltip_RaidTimeInfoOneHour")
	else
		raidTimeInfo = raidTimeInfo..string.format(getText("UI_RT_Tooltip_RaidTimeInfoNHours"), RTCore.settings.RaidTimeLengthInHours)
	end
	self.raidTimeLabel.tooltip = raidTimeInfo
    
    self.raidTimeChangeButton = ISButton:new(0, y, 70, fontHeight, getText("UI_RT_Button_Change"), self, RTSafehouseUI.raidTimeChangeClicked)
	self.raidTimeChangeButton:initialise()
    self.raidTimeChangeButton:instantiate()
    self.raidTimeChangeButton.borderColor = self.buttonBorderColor
    self:addChild(self.raidTimeChangeButton)
    self.raidTimeChangeButton.parent = self
    self.raidTimeChangeButton:setVisible(false)
end

RTSafehouseUI.prerenderRaidTimeUIElements = function(self)
	self.raidTimeLabel:setName(self.raidTime)
	self.raidTimeChangeButton:setX(self.raidTimeLabel:getRight() + 10)
end

RTSafehouseUI.updateRaidTimeButtons = function(self)
    self.raidTimeChangeButton.enable = self.raidTimeButtonEnabled
    self.raidTimeChangeButton.tooltip = self.raidTimeButtonTooltip
    self.raidTimeChangeButton:setVisible(self:isOwner())
end

--------------------------------
------ Override functions ------
--------------------------------

RTSafehouseUI.initialise = function(self)
	RTSafehouseUI.default.initialise(self)
	RTSafehouseUI.addRaidTimeUIElements(self)
	self.raidTime = unknownRaidTime
	self.raidTimeButtonEnabled = false
	RTSafehouseUI:update()
end

RTSafehouseUI.prerender = function(self)
	RTSafehouseUI.default.prerender(self)
	RTSafehouseUI.prerenderRaidTimeUIElements(self)
end

RTSafehouseUI.updateButtons = function(self)
	RTSafehouseUI.default.updateButtons(self)
	RTSafehouseUI.updateRaidTimeButtons(self)
end

RTSafehouseUI.onReleaseSafehouse = function(self, button, player)
	RTSafehouseUI.default.onReleaseSafehouse(self, button, player)
	if button.internal == "YES" then
		LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
	end
end

RTSafehouseUI.onRemovePlayerFromSafehouse = function(self, button, player)
	RTSafehouseUI.default.onRemovePlayerFromSafehouse(self, button, player)
	if button.internal == "YES" then
		LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
	end
end

RTSafehouseUI.onQuitSafehouse = function(self, button)
	RTSafehouseUI.default.onQuitSafehouse(self, button)
	if button.internal == "YES" then
		LuaEventManager.triggerEvent(RTClient.events.safehouseChanged)
	end
end

ISSafehouseUI.initialise = RTSafehouseUI.initialise
ISSafehouseUI.prerender = RTSafehouseUI.prerender
ISSafehouseUI.updateButtons = RTSafehouseUI.updateButtons
ISSafehouseUI.onReleaseSafehouse = RTSafehouseUI.onReleaseSafehouse
ISSafehouseUI.onRemovePlayerFromSafehouse = RTSafehouseUI.onRemovePlayerFromSafehouse
ISSafehouseUI.onQuitSafehouse = RTSafehouseUI.onQuitSafehouse

--------------------------------
----------- Events -------------
--------------------------------

if isClient() then
	Events[RTClient.events.safehousesSet].Add(RTSafehouseUI.update)
end