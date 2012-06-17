
function widget:GetInfo()
	return {
		name			= "Text To Speech Control",
		desc			= "Enables or disables text to speech through Zero-K lobby",
		author		= "Licho",
		date			= "10.6.2011",
		license	= "GNU GPL, v2 or later",
		layer		= 0,
		enabled	= true	--	loaded by default?
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

options_path = 'Settings/Audio'
options_order = {'enable'}
options = {
	enable ={	
		name = "Text-To-Speech (with Zero-K lobby only)", 
		type = 'bool', value = true, 
		OnChange = function(self)
			SetupTTS(self.value)
			WG.textToSpeechCtrl = {ttsEnable = self.value,}
		end,
	},
}

function widget:Initialize()
	SetupTTS(options.enable.value)
	WG.textToSpeechCtrl = {ttsEnable = options.enable.value,} --allow other widget to get value from this widget. ie: gui_chili_rejoin_progress.lua. We didn't declare it at outside because we doesn't want "WG.textToSpeechCtrl" to be initialize first without widget being enabled first.
end 

function widget:Shutdown()
	WG.textToSpeechCtrl = nil
end
