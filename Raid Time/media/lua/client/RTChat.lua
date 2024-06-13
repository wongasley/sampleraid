--------------------------------
---- Copyright (c) 2022 War ----
--------------------------------

RTChat = { }

function RTChat:createMessage(text)
	local message = {
		getText = function(_)
			return text
		end,
		getTextWithPrefix = function(_)
			return text
		end,
		isServerAlert = function(_)
			return false
		end,
		isShowAuthor = function(_)
			return false
		end,
		getAuthor = function(_)
			return getPlayer():getUsername();
		end,
		setShouldAttractZombies = function(_)
			return false
		end,
		setOverHeadSpeech = function(_)
			return false
		end
	}
	return message
end

function RTChat:show(text)
	if ISChat.instance and ISChat.instance.chatText then
	local message = RTChat:createMessage(text)
		ISChat.addLineInChat(message, 0)
	end
end