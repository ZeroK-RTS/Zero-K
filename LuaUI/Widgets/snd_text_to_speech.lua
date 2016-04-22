
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

local function SetupTTS(enable)
	if (enable and not Spring.GetSpectatingState()) then 
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " ENABLE TTS")
	else 
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
	end 
end 

options_path = 'Settings/Audio/Text to Speech'
options_order = {'enable', 'volume'}
options = {
	enable ={	
		name = "Enable TTS (ZKL only)",
		desc = "Ally chat will be read aloud.",
		type = 'bool', value = true, 
		noHotkey = true,
		OnChange = function(self)
			SetupTTS(self.value)
			WG.textToSpeechCtrl = {ttsEnable = self.value,}
		end,
	},
	volume ={	
		name = "Volume",
		type = 'number',
		min = 1,
		max = 100, 
		step = 1,
		value = 50,
		OnChange = function(self)
			Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " TTS VOLUME " .. self.value)
		end,
	},
}

function widget:Initialize()
	SetupTTS(options.enable.value)
	WG.textToSpeechCtrl = {ttsEnable = options.enable.value,} --allow other widget to get value from this widget. ie: gui_chili_rejoin_progress.lua. We didn't declare it at outside because we doesn't want "WG.textToSpeechCtrl" to be initialize first without widget being enabled first.
end 

function widget:Shutdown()
	Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
	WG.textToSpeechCtrl = nil
end
