--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

RTCore = {
	days = {
		getText("UI_RT_Day_Sunday"),
		getText("UI_RT_Day_Monday"),
		getText("UI_RT_Day_Tuesday"),
		getText("UI_RT_Day_Wednesday"),
		getText("UI_RT_Day_Thursday"),
		getText("UI_RT_Day_Friday"),
		getText("UI_RT_Day_Saturday")
	},
	intervals = {
		day = {
			min = 1,
			max = 7
		},
		hour = {
			min = 0,
			max = 23
		}
	},
	default = {
		settings = {
			RaidFrequencyEveryNWeeks = 1,
			RaidTimeLengthInHours = 1,
			RaidTimeChangePeriodInHours = 12,
			TestMode = 0
		},
		intervals = {
			RaidFrequencyEveryNWeeks = {
				min = 1,
				max = 32
			},
			RaidTimeLengthInHours = {
				min = 0,
				max = 24
			},
			RaidTimeChangePeriodInHours = {
				min = 0,
				max = 72
			},
			TestMode = {
				min = 0,
				max = 1
			}
		}
	},
	settings = { },
	safehouses = { },
	timezone = tonumber(SimpleDateFormat.new("X"):format(Calendar.getInstance():getTime())),
	templateTime = os.time({ year = 2000, month = 1, day = 1, hour = 0}),
	modLoaded = false
}

function RTCore:isCorrect(value, interval)
	if type(value) ~= "number" then
		return false
	end
	if value < interval.min or value > interval.max then
		return false
	end
	return true
end

function RTCore:getDate(wday, hour, timezone)
	return os.date("!*t", RTCore.templateTime + wday * 24 * 60 * 60 + (hour + timezone) * 60 * 60)
end

function RTCore:printHour(hour)
	if hour < RTCore.intervals.hour.min or hour > RTCore.intervals.hour.max then
		return nil
	end
	if hour < 10 then
		return "0"..hour..":00"
	else
		return hour..":00"
	end
end