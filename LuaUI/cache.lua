-- Caching results for Spring.* functions


-- *etTeamColor
local teamColor = {}

-- GetVisibleUnits
local visibleUnits = {}

-- original functions
local GetTeamColor = Spring.GetTeamColor
local SetTeamColor = Spring.SetTeamColor
local GetVisibleUnits = Spring.GetVisibleUnits

function Spring.GetTeamColor(teamid)
  if teamColor[teamid] then
  else
    teamColor[teamid] = { GetTeamColor(teamid) }
  end
  return unpack(teamColor[teamid])
end

function Spring.SetTeamColor(teamid, r, g, b)
  -- set and cache
  SetTeamColor(teamid, r, g, b)
  teamColor[teamid] = { GetTeamColor(teamid) }
end

local function buildIndex(teamID, radius, Icons)
  --local index = tostring(teamID)..":"..tostring(radius)..":"..tostring(Icons)
  local t = {}
  if teamID then t[#t+1] = teamID end
  if radius then t[#t+1] = radius end
  -- concat wants a table where all elements are strings or numbers
  if Icons then t[#t+1] = 1 end
  return table.concat(t, ":")
end

-- returns unitTable = { [1] = number unitID, ... }
function Spring.GetVisibleUnits(teamID, radius, Icons)
  local index = buildIndex(teamID, radius, Icons)
  local ret
  local update = false
  if visibleUnits[index] then
    local visible = visibleUnits[index]
    -- check time
    local now = Spring.GetTimer()
    local diff = Spring.DiffTimers(now, visible.time)
    if diff > 1/25 then
      visible.time = now
      update = true
    else
      return visible.units
      end
  else
    update = true
  end

  if update then
    ret = GetVisibleUnits(teamID, radius, Icons)
    visibleUnits[index] = {}
    visibleUnits[index].units = ret
    visibleUnits[index].time = Spring.GetTimer()
    local rev = {}
    for i=1,#ret do
      rev[ret[i]] = i
    end
    visibleUnits[index].reverse = rev
  end
  return ret
end

-- returns unitTable = { [unitID] = number indexFromTableReturnedByGetVisibleUnits, ... }
function Spring.GetVisibleUnitsReverse(teamID, radius, Icons)
  local index = buildIndex(teamID, radius, Icons)
  local update = false
  if visibleUnits[index] then
    local visible = visibleUnits[index]
    -- check time
    local now = Spring.GetTimer()
    local diff = Spring.DiffTimers(now, visible.time)
    if diff > 1/25 then
      visible.time = now
      update = true
    else
      return visible.reverse
      end
  else
    update = true
  end

  if update then
    -- update
    Spring.GetVisibleUnits(teamID, radius, Icons)
  end
  return visibleUnits[index].reverse
end

--Workaround for Spring.SetCameraTarget() not working in Freestyle mode.
local SetCameraTarget = Spring.SetCameraTarget
function Spring.SetCameraTarget(x,y,z,transTime) 
	local cs = Spring.GetCameraState()
	if cs.mode==4 then --if using Freestyle cam, especially when using "camera_cofc.lua"
		--"0.46364757418633" is the default pitch given to FreeStyle camera (the angle between Target->Camera->Ground, tested ingame) and is the only pitch that original "Spring.SetCameraTarget()" is based upon.
		--"cs.py-y" is the camera height.	
		--"math.pi/2 + cs.rx" is the current pitch for Freestyle camera (the angle between Target->Camera->Ground). Freestyle camera can change its pitch by rotating in rx-axis.
		--The original equation is: "x/y = math.tan(rad)" which is solved for "x"
		local ori_zDist = math.tan(0.46364757418633)*(cs.py-y) --the ground distance (at z-axis) between default FreeStyle camera and the target. We know this is only for z-axis from our test.
		local xzDist = math.tan(math.pi/2 + cs.rx)*(cs.py-y) --the ground distance (at xz-plane) between FreeStyle camera and the target.
		local xDist = math.sin(cs.ry)*xzDist ----break down "xzDist" into x and z component.
		local zDist = math.cos(cs.ry)*xzDist
		x = x-xDist --add current FreeStyle camera to x-component 
		z = z-ori_zDist-zDist --remove default FreeStyle z-component, then add current Freestyle camera to z-component
	end
	return SetCameraTarget(x,y,z,transTime) --return new results
end