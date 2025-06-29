-- Poisoning for Spring.* functions (caching, filtering, providing back compat)

if not Spring.IsUserWriting then
	Spring.IsUserWriting = function()
		return false
	end
end

-- *etTeamColor
local teamColor = {}

-- GetVisibleUnits
local visibleUnits = {}

-- original functions
local GetTeamColor = Spring.GetTeamColor
local SetTeamColor = Spring.SetTeamColor
local GetVisibleUnits = Spring.GetVisibleUnits
local MarkerAddPoint = Spring.MarkerAddPoint
local ShareResources = Spring.ShareResources

-- Block line drawing widgets
--local MarkerAddLine = Spring.MarkerAddLine
--function Spring.MarkerAddLine(a,b,c,d,e,f,g)
--	MarkerAddLine(a,b,c,d,e,f,true)
--end

-- Cutscenes apply F5
local IsGUIHidden = Spring.IsGUIHidden
function Spring.IsGUIHidden()
	return IsGUIHidden() or (WG.Cutscene and WG.Cutscene.IsInCutscene())
end

function Spring.GetTeamColor(teamid)
  if not teamColor[teamid] then
    teamColor[teamid] = {GetTeamColor(teamid)}
  end
  return unpack(teamColor[teamid])
end

function Spring.MarkerAddPoint(x, y, z, t, b)
	MarkerAddPoint(x,y,z,t,true)
end

function Spring.ShareResources(teamID, resourceType, amount)
	if resourceType:sub(1, 1) == "u" then
		-- Cancel commands to prevent things like sharing an active con to drain resources
		-- or to pass on griefing blame. The implementation matches legacy engine behaviour.
		Spring.GiveOrder(CMD.STOP, 0, 0)

		return ShareResources(teamID, resourceType) -- passing an explicit nil as amount breaks it on old engines
	end

	return ShareResources(teamID, resourceType, amount)
end

function Spring.SetTeamColor(teamid, r, g, b)
  -- set and cache
  SetTeamColor(teamid, r, g, b)
  teamColor[teamid] = { GetTeamColor(teamid) }
end

local spSetUnitNoSelect = Spring.SetUnitNoSelect
function Spring.SetUnitNoSelect(unitID, value)
	return
end

local function buildIndex(teamID, radius, Icons)
	--local index = tostring(teamID)..":"..tostring(radius)..":"..tostring(Icons)
	local t = {}
	if teamID then
		t[#t + 1] = teamID
	end
	if radius then
		t[#t + 1] = radius
	end
	-- concat wants a table where all elements are strings or numbers
	if Icons then
		t[#t+1] = 1
	end
	return table.concat(t, ":")
end

-- returns unitTable = { [1] = number unitID, ... }
function Spring.GetVisibleUnits(teamID, radius, Icons)
	local index = buildIndex(teamID, radius, Icons)

	local currentFrame = Spring.GetGameFrame() -- frame is necessary (invalidates visibility; units can die or disappear outta LoS)
	local now = Spring.GetTimer() -- frame is not sufficient (eg. you can move the screen while game is paused)

	local visible = visibleUnits[index]
	if visible then
		local diff = Spring.DiffTimers(now, visible.time)
		if diff < 0.05 and currentFrame == visible.frame then
			return visible.units
		end
	else
		visibleUnits[index] = {}
		visible = visibleUnits[index]
	end

	local ret = GetVisibleUnits(teamID, radius, Icons)
	visible.units = ret
	visible.frame = currentFrame
	visible.time = now

	return ret
end

--Workaround for Spring.SetCameraTarget() not working in Freestyle mode.
local SetCameraTarget = Spring.SetCameraTarget
function Spring.SetCameraTarget(x, y, z, transTime)
	local cs = Spring.GetCameraState()
	if cs.mode == 4 then --if using Freestyle cam, especially when using "camera_cofc.lua"
		--"0.46364757418633" is the default pitch given to FreeStyle camera (the angle between Target->Camera->Ground, tested ingame) and is the only pitch that original "Spring.SetCameraTarget()" is based upon.
		--"cs.py-y" is the camera height.
		--"math.pi/2 + cs.rx" is the current pitch for Freestyle camera (the angle between Target->Camera->Ground). Freestyle camera can change its pitch by rotating in rx-axis.
		--The original equation is: "x/y = math.tan(rad)" which is solved for "x"
		local ori_zDist = math.tan(0.46364757418633) * (cs.py - y) --the ground distance (at z-axis) between default FreeStyle camera and the target. We know this is only for z-axis from our test.
		local xzDist = math.tan(math.pi / 2 + cs.rx) * (cs.py - y) --the ground distance (at xz-plane) between FreeStyle camera and the target.
		local xDist = math.sin(cs.ry) * xzDist ----break down "xzDist" into x and z component.
		local zDist = math.cos(cs.ry) * xzDist
		x = x - xDist --add current FreeStyle camera to x-component
		z = z - ori_zDist - zDist --remove default FreeStyle z-component, then add current Freestyle camera to z-component
	end
	if x and y and z then
		return SetCameraTarget(x, y, z, transTime) --return new results
	end
end

-- not yet supported (can screw up the minimap)
Spring.SetMiniMapRotation = function() end
