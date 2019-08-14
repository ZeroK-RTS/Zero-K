-- $Id$

function widget:GetInfo()
  return {
    name      = "Auto First Build Facing",
    desc      = "Set buildfacing toward map center on the first building placed",
    author    = "zwzsg with lotsa help from #lua channel",
    date      = "October 26, 2008", --29 May 2014
    license   = "Free",
    layer     = 0,
    enabled   = true  -- loaded by default
  }
end


local facing=0
local x --intentionally Nil
local z=0
local n=0

function widget:Initialize()
	if Spring.GetSpectatingState() then
		Spring.Echo("Spectator mode detected. Removed: Auto First Build Facing") --added this message because widget removed message might not appear (make debugging harder)
		widgetHandler:RemoveWidget(self)
	end
end

-- Count all units and calculate their barycenter
local function SetStartPos()
	if Spring.GetTeamUnitCount(Spring.GetMyTeamID()) and Spring.GetTeamUnitCount(Spring.GetMyTeamID())>0 then
		x= 0
		for k,unitID in pairs(Spring.GetTeamUnits(Spring.GetMyTeamID())) do
			local ux=0
			local uz=0
			ux,_,uz=Spring.GetUnitPosition(unitID)
			if ux and uz then
				x=x+ux
				z=z+uz
				n=n+1
			end
		end
		x=x/n
		z=z/n
	end
end

local function GetStartPos()
	local sx, _, sz = Spring.GetTeamStartPosition(Spring.GetMyTeamID()) -- Returns -100, -100, -100 when none chosen
	if (sx > 0) then
		x = sx
		z = sz
	end
end

local function SetPreGameStartPos()
	local mx, my = Spring.GetMouseState()
	local _, pos = Spring.TraceScreenRay(mx, my, true, false,false, true)--only coordinate, NOT thru minimap, NOT include sky, ignore water surface
	if pos then
		x = pos[1]
		z = pos[3]
	end
end

-- Set buildfacing the first time a building is about to be built
function widget:Update()
	local _,cmd=Spring.GetActiveCommand()
	if cmd and cmd<0 then
		if not x then SetStartPos() end --use unit's mean position as start pos
		if not x then GetStartPos() end --no unit, use official start pos
		if not x then SetPreGameStartPos() end --no official start pos, use mouse cursor as startpos
		if x then
			if math.abs(Game.mapSizeX - 2*x) > math.abs(Game.mapSizeZ - 2*z) then
				if (2*x>Game.mapSizeX) then
					-- facing="west"
					facing=3
				else
					-- facing="east"
					facing=1
				end
			else
				if (2*z>Game.mapSizeZ) then
					-- facing="north"
					facing=2
				else
					-- facing="south"
					facing=0
				end
			end
			-- Spring.SendCommands({"buildfacing "..facing})
			Spring.SetBuildFacing(facing)
			widget.widgetHandler.RemoveCallIn(widget.widget,"Update")
		end
	end
end
