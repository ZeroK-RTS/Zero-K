--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "CameraRecorder",
    desc      = "v0.011 Record positions of the camera to a file and repath those positions when loading the replay.",
    author    = "CarRepairer",
    date      = "2011-07-04",
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[

HOW TO USE:

Start a game (such as a replay).
Type /luaui reload
Push Settings > Camera > Recording > Record
Move your camera around.
Push Record again to stop.
End game.
Start a replay of that game you just recorded the camera in.
Type /luaui reload
Push Settings > Camera > Recording > Play
The camera will follow the path you recorded.

Notes:
For some reason the Game.gameID constant doesn't work until you type /luaui reload
The camera positions are saved to a file based on the gameID. If you don't
reload luaui it will save to (or read from) the file camrec_AAAAAAAAAAAAAAAAAAAAAA==.txt

--]]


options_path = 'Settings/Camera/Recording'
--options_order = { }

local OverviewAction = function() end

options = {
	
	record = {
		name = "Record",
		desc = "Record now",
		type = 'button',
        -- OnChange defined later
	},
    
    play = {
		name = "Play",
		desc = "Play now",
		type = 'button',
        -- OnChange defined later
	},
    
    help = {
        name = 'Help',
        type = 'text',
        value = [[
            * Start a game (such as a replay).
            * Type /luaui reload
            * Push Settings > Camera > Recording > Record
            * Move your camera around.
            * Push Record again to stop.
            * End game.
            * Start a replay of that game you just recorded the camera in.
            * Type /luaui reload
            * Push Settings > Camera > Recording > Play
            * The camera will follow the path you recorded.
        ]],
    }
    
	
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--config

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetCameraState		= Spring.GetCameraState
local spGetCameraVectors	= Spring.GetCameraVectors
local spGetModKeyState		= Spring.GetModKeyState
local spGetMouseState		= Spring.GetMouseState
local spIsAboveMiniMap		= Spring.IsAboveMiniMap
local spSendCommands		= Spring.SendCommands
local spSetCameraState		= Spring.SetCameraState
local spSetMouseCursor		= Spring.SetMouseCursor
local spTraceScreenRay		= Spring.TraceScreenRay
local spWarpMouse			= Spring.WarpMouse
local spGetCameraDirection	= Spring.GetCameraDirection

local abs	= math.abs
local min 	= math.min
local max	= math.max
local sqrt	= math.sqrt
local sin	= math.sin
local cos	= math.cos

local echo = Spring.Echo

local KF_FRAMES = 1
local recording = false
local recData = {}
local filename
local ranInit = false

Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")

options.record.OnChange = function()
    recording = not recording
    echo (recording and '<Camera Recording> Recording begun.' or '<Camera Recording> Recording stopped.')
end
options.play.OnChange = function()
    playing = not playing
    echo (playing and '<Camera Recording> Playback begun.' or '<Camera Recording> Playback stopped.')
end

local CAMERA_STATE_FORMATS = {
	fps = {
		"px", "py", "pz",
		"dx", "dy", "dz",
		"rx", "ry", "rz",
		"oldHeight",
	},
	free = {
		"px", "py", "pz",
		"dx", "dy", "dz",
		"rx", "ry", "rz",
		"fov",
		"gndOffset",
		"gravity",
		"slide",
		"scrollSpeed",
		"velTime",
		"avelTime",
		"autoTilt",
		"goForward",
		"invertAlt",
		"gndLock",
		"vx", "vy", "vz",
		"avx", "avy", "avz",
	},
	OrbitController = {
		"px", "py", "pz",
		"tx", "ty", "tz",
	},
	ta = {
		"px", "py", "pz",
		"dx", "dy", "dz",
		"height",
		"zscale",
		"flipped",
	},
	ov = {
		"px", "py", "pz",
	},
	rot = {
		"px", "py", "pz",
		"dx", "dy", "dz",
		"rx", "ry", "rz",
		"oldHeight",
	},
	sm = {
		"px", "py", "pz",
		"dx", "dy", "dz",
		"height",
		"zscale",
		"flipped",
	},
	tw = {
		"px", "py", "pz",
		"rx", "ry", "rz",
	},
}

local CAMERA_NAMES = {
	"fps",
	"free",
	"OrbitController",
	"ta",
	"ov",
	"rot",
	"sm",
	"tw",
}
local CAMERA_IDS = {}


for i=1, #CAMERA_NAMES do
	CAMERA_IDS[CAMERA_NAMES[i]] = i
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end



local function CameraStateToString(frame, cs)

	local name = cs.name
	local stateFormat = CAMERA_STATE_FORMATS[name]
	local cameraID = CAMERA_IDS[name]

	if not stateFormat or not cameraID then return nil end
	
	local result = frame .. '|' .. cameraID .. '|' .. cs.mode
	
	for i=1, #stateFormat do
		local num = cs[stateFormat[i]]
		if not num then return nil end
		result = result .. '|' .. num
	end
	
	return result
end


local function StringToCameraState(str)
    local s_arr = explode('|', str)
    
	local frame     = s_arr[1]
	local cameraID  = s_arr[2]
	local mode      = s_arr[3]
	local name          = CAMERA_NAMES[cameraID+0]
	local stateFormat   = CAMERA_STATE_FORMATS[name]
    
	if not (cameraID and mode and name and stateFormat) then
        --echo ('ISSUE', cameraID , mode , name , stateFormat)
		return nil
	end
	
	local result = {
        frame = frame,
		name = name,
		mode = mode,
	}
	
	for i=1, #stateFormat do
		local num = s_arr[i+3]
		
		if not num then return nil end
		
		result[stateFormat[i]] = num
	end
	
	return result
end


local function IsKeyframe(frame)
    return frame % KF_FRAMES == 0
end


local function RecordFrame(frame)
    --echo ('<camrec> recording frame', frame)
    
    local str = CameraStateToString( frame, spGetCameraState() )
    
    local out = assert(io.open(filename, "a+"), "Unable to save camera recording file to "..filename)
    out:write(str .. "\n")
    assert(out:close())
end

local function FileToData(filename)
    --local file = assert(io.open(filename,'r'), "Unable to load camera recording file from "..filename)
    local file = io.open(filename,'r')
    if not file then
        echo('<Camrec> No such file ' .. filename )
        return {}
    end
    local recData = {}
    local prevkey = 0
    while true do
		line = file:read()
		if not line then
			break
		end
        --echo ('<camrec> opening line ', line)
        local data = StringToCameraState( line )
		--recData[ data.frame ] = data
        if prevkey ~= 0 then
            --echo('<camrec> adding data', prevkey )
            recData[ prevkey+0 ] = data
        end
        prevkey = data.frame
	end
    return recData
end

local function RunInit()
    if ranInit then
        return true
    end
    
    local gameID = Game.gameID
    
    --echo ('gameid=', gameID)
    
    if not gameID or gameID == '' then
        return false
    end
    ranInit = true
    
    local gameID_enc = Spring.Utilities.Base64Encode( gameID )
    --echo( '<camrec>', gameID, gameID_enc )
    local gameID_dec = Spring.Utilities.Base64Decode( gameID_enc )
    --echo( '<camrec>','equal?', gameID_dec == gameID )
    filename = 'camrec_' .. gameID_enc .. '.txt'
    --echo ('<camrec>',filename)
    
    recData = FileToData( filename )
    return true
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GameFrame()
    local frame = Spring.GetGameFrame()
    if frame < 1 then return end
    if not RunInit() then return end
    
    if recording then
        if IsKeyframe(frame) then
            RecordFrame(frame)
        end
    end

    if playing then
        if recData[frame] then
            --echo ('playing frame', frame)
            spSetCameraState(recData[frame], KF_FRAMES / 32)
        end
    end
  
end


function widget:Initialize()
    
end


--------------------------------------------------------------------------------
