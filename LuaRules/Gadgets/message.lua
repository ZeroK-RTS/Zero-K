--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Automatically generated local definitions

local spGetGameFrame   = Spring.GetGameFrame
local spGetLocalTeamID = Spring.GetLocalTeamID
local spGetTeamList    = Spring.GetTeamList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name = "Message",
		desc = "Displays a massage",
		author = "KDR_11k (David Becker)",
		date = "2008-03-04",
		license = "Public Domain",
		layer = 1,
		enabled = false
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local msgs = {}

function gadget:Initialize()
	for _,t in ipairs(spGetTeamList()) do
		msgs[t] = {
			text = "",
			hint = "",
			timeout = 0,
		}
	end
	GG.message = msgs
	_G.message = msgs
end

else

--UNSYNCED
local glText           = gl.Text

function gadget:DrawScreen(vsx, vsy)
	local team = spGetLocalTeamID()
	if spGetGameFrame() < SYNCED.message[team].timeout then
		glText(SYNCED.message[team].text, vsx*.5, vsy*.8, 24, "oc")
		glText(SYNCED.message[team].hint, vsx*.5, vsy*.8 - 40, 15, "oc")
	end
end

end
