
function widget:GetInfo()
	return {
		name			= "Text To Speech Control",
		desc			= "Enables or disables text to speech through Zero-K lobby",
		author		= "Licho",
		date			= "10.6.2011",
		license	= "GNU GPL, v2 or later",
		layer		= math.huge,
		enabled	= true,	--	loaded by default?
		alwaysStart = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local luaMenuActive = false
local textToSpeechEnabled = false
local enabledWidgetOverride = true
local myPlayerID, myPlayerName

local function SetupTTS(value)
	value = math.floor(value * Spring.GetConfigInt("snd_volmaster", 50) / 100)
	if (value == 0) then
		textToSpeechEnabled = false 
		if not luaMenuActive then
			Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) .. " DISABLE TTS")
			Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) .. " TTS VOLUME 0")
		end
		WG.textToSpeechCtrl = {ttsEnable = false,}
	else
		textToSpeechEnabled = true
		if luaMenuActive then
			Spring.SendLuaMenuMsg("textToSpeechVolume_" .. value)
		else
			Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) .. " ENABLE TTS")
			Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) .. " TTS VOLUME " .. value)
		end
		WG.textToSpeechCtrl = {ttsEnable = true,}
	end
end

options_path = 'Settings/Audio'
options_order = {'tts_vol'}
options = {
	tts_vol = {
		name = "Text-to-speech volume",
		desc = "TTS reads the ally chat.",
		type = 'number',
		min = 0, max = 100, 
		value = 0, step = 1,
		noHotkey = true,
		OnChange = function(self)
			SetupTTS(self.value)
		end,
	},
}

local TextToSpeech = {}

function TextToSpeech.SetEnabled(newEnabled)
	enabledWidgetOverride = newEnabled
end

local function ttsNotify()
	SetupTTS(options.tts_vol.value)
end

function widget:Initialize()
	luaMenuActive = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	SetupTTS(options.tts_vol.value)
	WG.TextToSpeech = TextToSpeech
	WG.ttsNotify = ttsNotify
	if luaMenuActive then
		myPlayerID = Spring.GetMyPlayerID()
		myPlayerName = Spring.GetPlayerInfo(myPlayerID, false)
	else
		widgetHandler:RemoveCallIn("AddConsoleMessage")
	end
end

function widget:Shutdown()
	if not luaMenuActive then
		Spring.Echo (Spring.GetPlayerInfo(Spring.GetMyPlayerID(), false) .. " DISABLE TTS")
	end
	WG.textToSpeechCtrl = nil
end

function widget:AddConsoleMessage(msg)
	if not (textToSpeechEnabled and enabledWidgetOverride) then
		return
	end
	if not (msg and msg.msgtype == "player_to_allies" and msg.playername ~= myPlayerName) then
		return
	end
	Spring.SendLuaMenuMsg("textToSpeechSay_" .. (msg.playername or "unknown") .. " " .. (msg.argument or ""))
end

function widget:MapDrawCmd(playerId, cmdType, px, py, pz, caption)
	if not (textToSpeechEnabled and enabledWidgetOverride) then
		return
	end
	if (select(1, Spring.GetSpectatingState()) or playerId == myPlayerID) then
		return
	end
	if (cmdType == 'point') then
		local playerName = Spring.GetPlayerInfo(playerId, false)
		Spring.SendLuaMenuMsg("textToSpeechSay_" .. (playerName or "unknown") .. " " .. (caption or ""))
	end
end
