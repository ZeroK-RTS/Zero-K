
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

local function SetupTTS (value)
	value = math.floor(value * Spring.GetConfigInt("snd_volmaster", 50) / 100)
	if (value == 0) then
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " TTS VOLUME 0")
		WG.textToSpeechCtrl = {ttsEnable = false,}
	else
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " ENABLE TTS")
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " TTS VOLUME " .. value)
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
		value = 50, step = 1,
		noHotkey = true,
		OnChange = function(self)
			SetupTTS(self.value)
		end,
	},
}

function widget:Initialize()
	SetupTTS (options.tts_vol.value)
end

local function ttsNotify()
	SetupTTS (options.tts_vol.value)
end

WG.ttsNotify = ttsNotify

function widget:Shutdown()
	Spring.Echo (Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
	WG.textToSpeechCtrl = nil
end
