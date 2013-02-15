--//Version 0.942
function gadget:GetInfo()
  return {
    name      = "AA shoot flying ground units",
    desc      = "Allow ground AA and air-superiority fighter to target and shot down any ground unit that is thrown up into air by Newton or explosion. AA targetting is triggered only by Newton or weapon explosion but can also be triggered externally thru GG table.",
    author    = "msafwan",
    date      = "16 Feb 2013",
    license   = "GNU GPL, v2 or later",
    layer     = -99,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) and gadget:GetInfo().enabled then -- SYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spCreateUnit         = Spring.CreateUnit
local spDestroyUnit        = Spring.DestroyUnit
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spSetUnitNoMinimap   = Spring.SetUnitNoMinimap
local spSetUnitNoSelect    = Spring.SetUnitNoSelect
local spSetUnitCloak  = Spring.SetUnitCloak 
local spSetUnitStealth  = Spring.SetUnitStealth
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spSetUnitMidAndAimPos  = Spring.SetUnitMidAndAimPos 
local spSetUnitDirection  = Spring.SetUnitDirection 
local spTransferUnit = Spring.TransferUnit
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitDirection  = Spring.GetUnitDirection
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitIsCloaked  = Spring.GetUnitIsCloaked
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitVectors = Spring.GetUnitVectors
local spGetUnitRadius  = Spring.GetUnitRadius 
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData

local spGetUnitVelocity  = Spring.GetUnitVelocity
local spSetUnitVelocity = Spring.SetUnitVelocity
local spMoveCtrlSetVelocity = Spring.MoveCtrl.SetVelocity
local spMoveCtrlEnable = Spring.MoveCtrl.Enable
local spMoveCtrlSetGravity = Spring.MoveCtrl.SetGravity
local spMoveCtrlSetPosition = Spring.MoveCtrl.SetPosition

--------------------------------------------------------------------------------
local gravity = -1*Game.gravity/30/30
local flyingGroundUnitsID = {}
local updateRate_2 =5 --update rate for free flying trajectory. Use lower value for unit that move erraticly
local updateRate_3 =1 --update rate for cloak status & unit's team
local lockOnSpeed_sq = 3.8*3.8 --speed which unit is targetable by AA
local speedWatchout = gravity --absolute y velocity which unit is considered "about to fly" 

local onlyTarget ={
	corpyro=true,
	corsumo=true,
	corsktl=true,
	corcan=true,
	corroach=true,
}
--------------------------------------------------------------------------------
GG.isflying_watchout = {} --allow other gadget to signal this gadget that this unit is flying. ie: "(impulse) unit_jumpjet.lua" can do "GG.isflying_watchout[unitID]=true" to indicate that such unit is flying and should be targeted by AA.
--[[
	MANUAL:

	Do this to trigger AA detection from other gadget:
	1) make sure unit's absolute Y velocity is > Game.gravity/30/30: 
	2) then choose the following to trigger detection:
		- GG.isflying_watchout[unitID]=true, OR: 
		- Spring.AddUnitDamage(unitID, 0) (note: only unit in "onlyTarget" list will be included if using 'AddDamage' method)
		
	The following happen:
	1) gadget iterate over the "GG.isflying_watchout" and check damage report,
	2) relevant unitID(s) is added to a watchlist
	2) "GG.isflying_watchout" is emptied
	NOTE: a fake AA target will be prepared for the unit (target category is FAKEAATARGET)
	3) unitID will get shot by AA when: 
		-its absolute speed is > 3.8 elmo-per-frame, AND the height above ground is > 100 elmo.
	4) unit is considered grounded when:
		- absolute Y velocity is < Game.gravity/30/30, AND the height below unit's feet is < 100 elmo.
	5) grounded unitID is immediately removed from watchlist
		
	You can exert velocity on any unit by:
	1) Spring.AddUnitImpulse(unitID, +velx, +vely, +velz); or...
	2) Spring.MoveCtrl.Enable(unitID); Spring.MoveCtrl.SetVelocity(unitID, velx, vely,velz); Spring.MoveCtrl.Disable(unitID)
--]]

function gadget:GameFrame(n)
	if n%updateRate_2 == 0 then --check flying units position every 5 frame. ~6fps. ballistic trajectory rarely need updates (unless unit accelerate then its good for dodging!).
		if #GG.isflying_watchout > 0 then
			for unitID,_ in pairs(GG.isflying_watchout) do --retrieve any new AA target from outside
				if unitID and flyingGroundUnitsID[unitID] == nil then
					local unitDefID = spGetUnitDefID(unitID)
					local unitName = UnitDefs[unitDefID].name
					local unitTeam = spGetUnitTeam(unitID)
					local stealth = UnitDefs[unitDefID].stealth
					local sclX,sclY,sclZ = spGetUnitCollisionVolumeData(unitID) --get the diameter of the hit volume
					local radX = spGetUnitRadius(unitID) --get the radius of the collision volume
					local safeDistance = math.max(sclX/2+20,sclY/2+20,sclZ/2+20,radX+20,100)
					flyingGroundUnitsID[unitID]={unitTeam=unitTeam,unitName=unitName,stealth=stealth, aaMarker=nil, teamChange=nil,safeDistance=safeDistance, forced=true }
					GG.isflying_watchout[unitID] = nil
				end
			end
		end
		for unitID,_ in pairs(flyingGroundUnitsID) do
			local bx,by,bz,mx,my,mz = spGetUnitPosition(unitID, true)
			local velX,velY,velZ = spGetUnitVelocity(unitID)
			local groundHeight = spGetGroundHeight(bx,bz)
			local unitName = flyingGroundUnitsID[unitID].unitName
			local forced = flyingGroundUnitsID[unitID].forced
			local landed = false
			if by < groundHeight+100 and math.abs(velY) < math.abs(speedWatchout) then --if low-elevation and vertical speed is less than of gravity then: assume unit has landed.
				landed = true
			end
			if not landed and (onlyTarget[unitName] or forced) then --only check for flying unit and unit in "onlyTarget" table (or unit with 'forced' flag).
				if by > groundHeight+100 then
					local netVelocity_sq = (velX*velX+velY*velY +velZ*velZ)
					local glaiveSpeed_sq = lockOnSpeed_sq
					if netVelocity_sq >= glaiveSpeed_sq then --if flying unit is flying faster than the fastest "glaives", then mark it for AA. (Such floating unit look like airplane in radar dot.)  
						local aaMarker = flyingGroundUnitsID[unitID].aaMarker
						local fakePosition = flyingGroundUnitsID[unitID].safeDistance
						if not aaMarker then --if flying unit not yet have FAKE AA marker:
							local unitTeam = flyingGroundUnitsID[unitID].unitTeam
							local stealth = flyingGroundUnitsID[unitID].stealth
							local cloaked = spGetUnitIsCloaked(unitID)
							aaMarker = spCreateUnit("fakeunit_aatarget",mx,(my+fakePosition),mz, "s", unitTeam) --create FAKE AA marker 100 elmo above unit. We can't spawn it inside flying unit because they will collide.
							spSetUnitCollisionVolumeData(aaMarker, 0,0,0,0,0,0,3,0,0) --set FAKE unit's hitbox as small as possible
							spSetUnitRadiusAndHeight(aaMarker,0,0) --set FAKE unit's colvol as small as possible
							spSetUnitMidAndAimPos(aaMarker,0,0,0,0,-fakePosition,0, true)  --translate FAKE's aimpoin to flying unit's midpoint. NOTE: target is higher than the flying unit (ie: +100 elmo)
							spSetUnitNoSelect(aaMarker, true)  --don't allow player to use the FAKE
							spSetUnitNoDraw(aaMarker, true) --don't hint player that FAKE exist
							spSetUnitNoMinimap(aaMarker, true)
							flyingGroundUnitsID[unitID].aaMarker = aaMarker
							spMoveCtrlEnable(aaMarker) --needed because "spSetUnitVelocity" callins has issues (setting velocity in x & z axis didn't do anything)
							spMoveCtrlSetGravity(aaMarker,gravity) 
							spSetUnitCloak(aaMarker,cloaked,0)
							spSetUnitStealth(aaMarker,stealth)
						end
						spMoveCtrlSetVelocity(aaMarker,velX,velY,velZ)
						spMoveCtrlSetPosition(aaMarker,mx, (my+fakePosition),mz)
						spSetUnitDirection(aaMarker,1,0,0) --make sure FAKE is exactly facing at right angle. This make sure that aiming point below it stays on the unit
					else --unit is not flying
						if flyingGroundUnitsID[unitID].aaMarker then
							spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
							flyingGroundUnitsID[unitID].aaMarker = nil
						end
					end
				else --unit is not floating
					if flyingGroundUnitsID[unitID].aaMarker then
						spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
						flyingGroundUnitsID[unitID].aaMarker = nil
					end
				end
			else --unit has landed
				if flyingGroundUnitsID[unitID].aaMarker then
					spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
					flyingGroundUnitsID[unitID].aaMarker = nil
				end
				flyingGroundUnitsID[unitID] = nil
			end
		end
	end
	if n%updateRate_3 == 0 then --update cloak status, teamChange,and unitDestroy every 1 frame. ~30fps.
		for unitID,_ in pairs(flyingGroundUnitsID) do
			local aaMarker = flyingGroundUnitsID[unitID].aaMarker
			local fakePosition = flyingGroundUnitsID[unitID].safeDistance
			if aaMarker then
				if flyingGroundUnitsID[unitID].teamChange == 1 then --if flying unit is transfered to enemy team, then: recreate FAKE AA
					--// recreate unit so that its targeting doesn't get fixated on FAKE AA (shooting ownself)
					spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
					local bx,by,bz,mx,my,mz = spGetUnitPosition(unitID, true)
					local velX,velY,velZ = spGetUnitVelocity(unitID)
					local stealth = flyingGroundUnitsID[unitID].stealth
					aaMarker = spCreateUnit("fakeunit_aatarget",mx,(my+fakePosition),mz, "s", flyingGroundUnitsID[unitID].unitTeam) --create FAKE AA marker 100 elmo above unit. We can't spawn it inside flying unit because they will collide.
					spSetUnitCollisionVolumeData(aaMarker, 0,0,0,0,0,0,3,0,0) --set FAKE unit's hitbox as small as possible
					flyingGroundUnitsID[unitID].aaMarker = aaMarker
					spSetUnitRadiusAndHeight(aaMarker,0,0) --set FAKE unit's colvol as small as possible
					spSetUnitMidAndAimPos(aaMarker,0,0,0,0,-fakePosition,0, true)  --translate FAKE's aimpoin to flying unit's midpoint. NOTE: We rely on AA to have "cylinderTargeting" which can detect unit at infinite height (ie: +100 elmo)
					spSetUnitNoSelect(aaMarker, true)  --don't allow player to use the FAKE
					spSetUnitNoDraw(aaMarker, true) --don't hint player that FAKE exist
					spSetUnitNoMinimap(aaMarker, true)
					spMoveCtrlEnable(aaMarker) --needed because "spSetUnitVelocity" callins has issues (setting velocity in x & z axis didn't do anything)
					spMoveCtrlSetGravity(aaMarker,gravity) 
					spMoveCtrlSetVelocity(aaMarker,velX,velY,velZ)
					spSetUnitDirection(aaMarker,1,0,0) --make sure FAKE is exactly facing at right angle. This make sure that aiming point below it stays on the unit
					spSetUnitStealth(aaMarker,stealth)
				elseif flyingGroundUnitsID[unitID].teamChange == 2 then --if flying unit is transfered to ally team, then: transfer FAKE AA
					--// transfer unit instead of recreating, so that it doesn't get abused to mess with enemy AA
					GG.allowTransfer = true --allow unit transfer. Ref: game_lagmonitor.lua, KingRaptor
					spTransferUnit(aaMarker, flyingGroundUnitsID[unitID].unitTeam) --transfer unit to other team
					GG.allowTransfer = false
				end
				flyingGroundUnitsID[unitID].teamChange = nil
				if flyingGroundUnitsID[unitID].destroyfake then
					--//destroy fakeAA
					spDestroyUnit(aaMarker, false, true)
					flyingGroundUnitsID[unitID] = nil
				else
					--//update fakeAA cloak status & collision volume position
					local cloaked = spGetUnitIsCloaked(unitID)
					local _,_,_,offX,offY,offZ = spGetUnitCollisionVolumeData(unitID) 
					if (offX~=0 or offY~=0 or offZ~=0) then
						local front, top, right = spGetUnitVectors(unitID)
						local offX_temp = offX
						local offY_temp = offY
						local offZ_temp = offZ
						offX = front[1]*offX_temp + top[1]*offY_temp + right[1]*offZ_temp
						offY = front[2]*offX_temp + top[2]*offY_temp + right[2]*offZ_temp
						offZ = front[3]*offX_temp + top[3]*offY_temp + right[3]*offZ_temp
						spSetUnitMidAndAimPos(aaMarker,0,0,0,offX,(-fakePosition+offY),offZ, true)
					end
					spSetUnitCloak(aaMarker,cloaked,0)
				end
			end
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if flyingGroundUnitsID[unitID] then --change FAKE AA's team (incase flying unit is transfered to enemy team)
		flyingGroundUnitsID[unitID].unitTeam = unitTeam
		if flyingGroundUnitsID[unitID].aaMarker then --if there is preexisting FAKE AA marker, then recreate new one for new team, and destroy old FAKE AA marker.
			local _,_,_,_,_,newAllyTeam = spGetTeamInfo(unitTeam) --copied from unit_mex_overdrive.lua, by googlefrog
			local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam)
			if newAllyTeam ~= oldAllyTeam then
				flyingGroundUnitsID[unitID].teamChange=1 --signal to recreate FAKE AA
			else
				flyingGroundUnitsID[unitID].teamChange=2 --signal to transfer unit
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if flyingGroundUnitsID[unitID] then
		if flyingGroundUnitsID[unitID].aaMarker then
			flyingGroundUnitsID[unitID].destroyfake = true --queue this fakeAA to be destroyed
			if GG.wasMorphedTo and GG.wasMorphedTo[unitID] then
				local newUnitID = GG.wasMorphedTo[unitID]
				GG.isflying_watchout[newUnitID] = true --add this new unit into watchlist
			end
		else
			flyingGroundUnitsID[unitID] = nil
		end
	end
end

function gadget:UnitUnloaded(unitID, unitDefID, teamID, transportID)
	GG.isflying_watchout[unitID]=true --unit fall from transport
end

--We going to rely on UnitPreDamaged() to identify any units that might fly due to hax (ie: Newton, explosion, or collision with other units). This mean we exclude jumpjet since the jumping is not caused by weapons or collision.
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) -- Working example: "Fall Damage", unit_fall_damage.lua, "Weapon Impulse", weapon_impulse.lua, by GoogleFrog 
	local unitName = UnitDefs[unitDefID].name
	if onlyTarget[unitName] then
		local stealth = UnitDefs[unitDefID].stealth
		local sclX,sclY,sclZ = spGetUnitCollisionVolumeData(unitID) --get the diameter of the hit volume
		local radX = spGetUnitRadius(unitID) --get the radius of the collision volume
		local safeDistance = math.max(sclX/2+20,sclY/2+20,sclZ/2+20,radX+20,100)
		flyingGroundUnitsID[unitID]={unitTeam=unitTeam,unitName=unitName,stealth=stealth, aaMarker=nil, teamChange=nil,safeDistance=safeDistance} --we check again later if they actually fly
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end