
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
	if (enable) then 
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " ENABLE TTS")
	else 
		Spring.Echo(Spring.GetPlayerInfo(Spring.GetMyPlayerID()) .. " DISABLE TTS")
	end 
end 


options_path = 'Settings/Interface/Chat'
options_order = { 'enable'}
options = {
	enable = {name = "Text-To-Speech (Zero-K lobby only)", type = 'bool', value = true, 
	
	OnChange = function(self)
			SetupTTS(self.value)
		end,

	},
}

function widget:Initialize()
	SetupTTS(options.enable.value)
end 

