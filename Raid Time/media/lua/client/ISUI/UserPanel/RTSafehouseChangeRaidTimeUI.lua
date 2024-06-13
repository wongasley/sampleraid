--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

require "RTCore"
require "RTSafehouse"

RTSafehouseChangeRaidTimeUI = ISPanel:derive("RTSafehouseChangeRaidTimeUI")

--------------------------------
------- Public functions -------
--------------------------------

function RTSafehouseChangeRaidTimeUI:new(x, y, safehouse)
    local width = 260
    local height = 170
    local instance = ISPanel:new(x, y, width, height)
    
    setmetatable(instance, self)
    self.__index = self
    if x == 0 then
        instance.x = instance:getMouseX() - (width / 2)
        instance:setX(instance.x)
    end
    if y == 0 then
        instance.y = instance:getMouseY() - (height / 2)
        instance:setY(instance.y)
    end
    instance.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    instance.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    instance.width = width
    instance.height = height
    instance.safehouse = safehouse
    RTSafehouseChangeRaidTimeUI.instance = instance
    
    return instance
end

--------------------------------
------ Private functions -------
--------------------------------

function RTSafehouseChangeRaidTimeUI:initialise()
	local horizontalPadding = 20
	local verticalPadding = 20
	local comboBoxWidth = 130
	local height = 20
	local buttonWidth = 100
	local buttonHeight = 25
	
	local dayLabel = ISLabel:new(horizontalPadding, verticalPadding, height, getText("UI_RT_Label_Day"), 1, 1, 1, 1, UIFont.Small, true)
	dayLabel:initialise()
    dayLabel:instantiate()
    self:addChild(dayLabel)
    
    local timeLabel = ISLabel:new(dayLabel.x, dayLabel:getBottom() + verticalPadding, height, getText("UI_RT_Label_Time"), 1, 1, 1, 1, UIFont.Small, true)
	timeLabel:initialise()
    timeLabel:instantiate()
    self:addChild(timeLabel)
    
    local comboBoxXPosition = math.max(dayLabel:getRight(), timeLabel:getRight()) + horizontalPadding
    
    self.dayComboBox = ISComboBox:new(comboBoxXPosition, dayLabel.y, comboBoxWidth, height)
	self.dayComboBox:initialise()
	for i = 2, #RTCore.days do
		self.dayComboBox:addOptionWithData(RTCore.days[i], i)
	end
	self.dayComboBox:addOptionWithData(RTCore.days[1], 1)
	self:addChild(self.dayComboBox)
    
    self.timeComboBox = ISComboBox:new(comboBoxXPosition, timeLabel.y, comboBoxWidth, height)
	self.timeComboBox:initialise()
	for i = RTCore.intervals.hour.min, RTCore.intervals.hour.max do
		self.timeComboBox:addOptionWithData(RTCore:printHour(i), i)
	end
	self:addChild(self.timeComboBox)
	
	local rtsafehouse = RTSafehouse:getByCoords(self.safehouse:getX(), self.safehouse:getY(), self.safehouse:getW(), self.safehouse:getH())
	if rtsafehouse then
		local date = RTCore:getDate(rtsafehouse.raidDay, rtsafehouse.raidHour, RTCore.timezone)
		self.dayComboBox:selectData(date.wday)
		self.timeComboBox:selectData(date.hour)
	end
	
	local cancelButton = ISButton:new((self:getWidth() / 2) - buttonWidth - horizontalPadding / 2, self:getHeight() - verticalPadding - buttonHeight, buttonWidth, buttonHeight, getText("UI_RT_Button_Cancel"), self, RTSafehouseChangeRaidTimeUI.close)
	cancelButton.anchorTop = false
	cancelButton.anchorBottom = true
	cancelButton:initialise()
	cancelButton:instantiate()
	cancelButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
	self:addChild(cancelButton)
	
	local saveButton = ISButton:new((self:getWidth() / 2) + horizontalPadding / 2, self:getHeight() - verticalPadding - buttonHeight, buttonWidth, buttonHeight, getText("UI_RT_Button_Save"), self, RTSafehouseChangeRaidTimeUI.save)
	saveButton.anchorTop = false
	saveButton.anchorBottom = true
	saveButton:initialise()
	saveButton:instantiate()
	saveButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
	self:addChild(saveButton)
end

function RTSafehouseChangeRaidTimeUI:save()
	local day = self.dayComboBox:getOptionData(self.dayComboBox.selected)
	local hour = self.timeComboBox:getOptionData(self.timeComboBox.selected)
	local date = RTCore:getDate(day, hour, -RTCore.timezone)
	sendClientCommand(getPlayer(), "client", "raidTimeChange", { date.wday, date.hour })
	self:close()
end

function RTSafehouseChangeRaidTimeUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
    RTSafehouseChangeRaidTimeUI.instance = nil
end

function RTSafehouseChangeRaidTimeUI:onSafehousesChanged()
	if RTSafehouseChangeRaidTimeUI.instance then
        local safehouse = RTSafehouseChangeRaidTimeUI.instance.safehouse
        if not SafeHouse.getSafehouseList():contains(safehouse) then
            RTSafehouseChangeRaidTimeUI.instance:close()
        end
    end
end

--------------------------------
----------- Events -------------
--------------------------------

Events.OnSafehousesChanged.Add(RTSafehouseChangeRaidTimeUI.onSafehousesChanged)