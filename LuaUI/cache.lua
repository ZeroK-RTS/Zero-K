-- Poisoning for Spring.* functions (caching, filtering, providing back compat)

-- luacheck: globals currentGameFrame

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

-- Block line drawing widgets
--local MarkerAddLine = Spring.MarkerAddLine
--function Spring.MarkerAddLine(a,b,c,d,e,f,g)
--	MarkerAddLine(a,b,c,d,e,f,true)
--end

local spGetProjectileTeamID = Spring.GetProjectileTeamID
local spGetMyTeamID = Spring.GetMyTeamID
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetProjectileDefID = Spring.GetProjectileDefID
local filteredWeaponDefID = {}
for wdid, wd in pairs(WeaponDefs) do
	if wd.customParams.restrict_in_widgets then
		filteredWeaponDefID[wdid] = true
	end
end
local function FilterOutRestrictedProjectiles(projectiles)
	local i = 1
	local n = #projectiles
	local myTeamID = spGetMyTeamID()
	while i <= n do
		local p = projectiles[i]
		local ownerTeamID = spGetProjectileTeamID(p)
		-- If the owner is allied with us, we shouldn't need to filter anything out
		if not spAreTeamsAllied(ownerTeamID, myTeamID) then
			local pID = spGetProjectileDefID(p)
			if filteredWeaponDefID[pID] then
				projectiles[i] = projectiles[n]
				projectiles[n] = nil
				n = n - 1
				i = i - 1
			end
		end
		i = i + 1
	end
	return projectiles
end

local GetProjectilesInRectangle = Spring.GetProjectilesInRectangle
function Spring.GetProjectilesInRectangle(x1, z1, x2, z2)
	local projectiles = GetProjectilesInRectangle(x1, z1, x2, z2)
	return FilterOutRestrictedProjectiles(projectiles)
end

-- Cutscenes apply F5
local IsGUIHidden = Spring.IsGUIHidden
function Spring.IsGUIHidden()
	return IsGUIHidden() or (WG.Cutscene and WG.Cutscene.IsInCutscene())
end

function Spring.GetTeamColor(teamid)
  if not teamColor[teamid] then
    teamColor[teamid] = { GetTeamColor(teamid) }
  end
  return unpack(teamColor[teamid])
end

function Spring.MarkerAddPoint(x, y, z, t, b)
	MarkerAddPoint(x,y,z,t,true)
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

	-- frame is necessary (invalidates visibility; units can die or disappear outta LoS)
	local now = Spring.GetTimer() -- frame is not sufficient (eg. you can move the screen while game is paused)

	local visible = visibleUnits[index]
	if visible then
		local diff = Spring.DiffTimers(now, visible.time)
		if diff < 0.05 and currentGameFrame == visible.frame then
			return visible.units
		end
	else
		visibleUnits[index] = {}
		visible = visibleUnits[index]
	end

	local ret = GetVisibleUnits(teamID, radius, Icons)
	visible.units = ret
	visible.frame = currentGameFrame
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

-- Rate limit network commands. This limit is per-widget.
-- - This is meant to stop people accidentally shooting themselves in the foot.
-- - This is meant to provide a warning for when a widget is being excessive.
-- - In particular, this is not meant to create an ironclad sandbox to curtail abusive actors. A widget staying under these thresholds does not necessarily imply that it is okay!
local FRAMES_PER_SECOND = Game.gameSpeed
local MAX_ORDERS_PER_SECOND = 110
local CIRCLE_BUFFER_SIZE = 15
local MAX_ORDERS_PER_BUFFER = MAX_ORDERS_PER_SECOND * CIRCLE_BUFFER_SIZE
local FUNCTIONS_TO_RATELIMIT = {
	"GiveOrder",
	"GiveOrderToUnit",
	"GiveOrderToUnitArray",
	"GiveOrderToUnitMap",
	"GiveOrderArrayToUnitMap",
	"GiveOrderArrayToUnitArray",
}

-- Mechanism for painless reversion via infra without a stable, in case something goes wrong and this starts culling something it shouldn't.
--  - 0: No throttling.
--  - 1: Warn, giving a one-time warning when commands would be dropped.
--  - 2: Enforce, dropping commands above the threshold.
-- In local skirmishes, this is 1 to permit destructive testing. ZKI is generally expected to send 2, or temporarily 0 if, for example, a stable forgot to add a widget to the whitelist in cawidgets.lua.
local BLOCK_MODE = Spring.GetModOptions().throttle_commands and tonumber(Spring.GetModOptions().throttle_commands) or 1

local spLog = Spring.Log

function PoisonWidget(widget, widgetName)
	if BLOCK_MODE == 0 then return end
	-- All GiveOrder* functions use the same circle buffer to count commands for throttling.
	-- Tracks calls made over the last CIRCLE_BUFFER_SIZE seconds, grouped by second.
	local lastWindow = math.floor(currentGameFrame / FRAMES_PER_SECOND)
	local lastFrame = currentGameFrame
	local currentWindowCalls = 0
	local circleBuffer = {}
	local circleBufferIndex = 1
	for i=1,CIRCLE_BUFFER_SIZE do
		circleBuffer[i] = 0
	end

	-- Create a local Spring table that the widget will receive in its environment.
	local realSpring = widget.Spring
	local localSpring = {}
	for k,v in pairs(realSpring) do
		localSpring[k] = v
	end

	-- Display a warning when a widget is sending commands at an unsustainable rate.
	local highestPercentageWarned = 0
	local noEnforceWarningYet = true

	-- Actually apply the throttle
	for i=1,#FUNCTIONS_TO_RATELIMIT do
		local fname = FUNCTIONS_TO_RATELIMIT[i]
		local realFunction = localSpring[fname]
		local function warnExcess(percentage)
			highestPercentageWarned = percentage
			Spring.Echo(fname .. ' use from ' .. widgetName .. ' hit soft ratelimit.')
			spLog(widgetName, LOG.ERROR, "Warning: Excessive command rate (" .. circleBuffer[circleBufferIndex] .. " in the current second) in " .. fname .. " from Widget " .. widgetName .. ". " .. percentage .. "% of permitted burst budget used! Commands will soon be dropped if it continues to send commands at this rate!")
			spLog(widgetName, LOG.ERROR, "===== CUT HERE WHEN REPORTING =====")
			spLog(widgetName, LOG.ERROR, "Command origin:")
			spLog(widgetName, LOG.ERROR, debug.traceback())
			spLog(widgetName, LOG.ERROR, "===== END CUT =====")
			Spring.Echo('Command volume history over the past ten seconds (current index: ' .. circleBufferIndex .. '):')
			Spring.Utilities.TableEcho(circleBuffer)
		end
		--local dbHit
		-- Replace the function with a rate limiting throttler
		localSpring[fname] = function(...)
			--WG.Debug.Echo(fname .. ' use from ' .. widgetName .. ' being tracked for rate limiting.')
			-- Check if the frame number and window need updating since the last call.
			if currentGameFrame ~= lastFrame then
				local currentWindow = math.floor(currentGameFrame / FRAMES_PER_SECOND)
				if currentWindow ~= lastWindow then
					-- If the window has moved, which may involve moving more than once space, discard old windows.
					local delta = math.min(CIRCLE_BUFFER_SIZE, currentWindow - lastWindow)
					for j=1,delta do
						-- Any window representing actions made more than 10 seconds in the past is discarded.
						circleBufferIndex = circleBufferIndex + 1
						if circleBufferIndex > CIRCLE_BUFFER_SIZE then
							circleBufferIndex = 1
						end
						-- The actions from any window so removed is subtracted from the current count of actions.
						currentWindowCalls = currentWindowCalls - circleBuffer[circleBufferIndex]
						circleBuffer[circleBufferIndex] = 0
					end
					lastWindow = currentWindow
				end
				lastFrame = currentGameFrame
			end
			-- Rate limited command increments happen before command blocking, so any malfunctioning widget *will* continue to be shut off when silenced. Fix your widgets!
			circleBuffer[circleBufferIndex] = circleBuffer[circleBufferIndex] + 1
			currentWindowCalls = currentWindowCalls + 1

			-- Finally, check against our thresholds.
			if currentWindowCalls > MAX_ORDERS_PER_BUFFER then
				-- If the "burst" budget has been exceeded, no more commands from you until you calm down.
				-- WG.Debug.Echo(fname .. ' use from ' .. widgetName .. ' hit hard ratelimit.')
				-- if not dbHit then dbHit = WG.Debouncer:new(warnExcess, 60) end
				-- dbHit(100)
				if BLOCK_MODE == 2 then
					spLog(widgetName, LOG.ERROR, "Rate limit exceeded in " .. fname .. " from Widget " .. widgetName .. ". Command dropped, update/fix your widgets!")
					return
				elseif noEnforceWarningYet and BLOCK_MODE == 1 then
					spLog(widgetName, LOG.ERROR, "Rate limit exceeded in " .. fname .. " from Widget " .. widgetName .. ". Excessive bursts of commands will soon be dropped, update/fix your widgets!")
				end
			elseif circleBuffer[circleBufferIndex] > MAX_ORDERS_PER_SECOND then
				-- If we're running an an unsustainable rate, give one off warnings at 20%, 50%, and 80% of the "burst" budget.
				if highestPercentageWarned < 80 and currentWindowCalls * 1.25 > MAX_ORDERS_PER_BUFFER then
					warnExcess(80)
				elseif highestPercentageWarned < 50 and currentWindowCalls * 2 > MAX_ORDERS_PER_BUFFER then
					warnExcess(50)
				elseif highestPercentageWarned < 20 and currentWindowCalls * 5 > MAX_ORDERS_PER_BUFFER then
					warnExcess(20)
				end
			end
			-- A-OK
			return realFunction(...)
		end
	end
	widget.Spring = localSpring
end
