function gadget:GetInfo()
  return {
    name      = "AA exception",
    desc      = "Allow ground AA and air-superiority fighter to target and shot down any ground unit that is thrown up into air by Newton or explosion. AA targetting is triggered only by Newton or weapon explosion but can also be triggered externally thru GG table.",
    author    = "msafwan",
    date      = "WIP",
    license   = "GNU GPL, v2 or later",
    layer     = -99,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then -- SYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spCreateUnit         = Spring.CreateUnit
local spDestroyUnit        = Spring.DestroyUnit
local spSetUnitNoDraw      = Spring.SetUnitNoDraw
local spSetUnitNoMinimap   = Spring.SetUnitNoMinimap
local spSetUnitNoSelect    = Spring.SetUnitNoSelect
local spGetUnitPosition  = Spring.GetUnitPosition
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitIsCloaked  = Spring.GetUnitIsCloaked
local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitCloak  = Spring.SetUnitCloak 
local spSetUnitStealth  = Spring.SetUnitStealth
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spSetUnitMidAndAimPos  = Spring.SetUnitMidAndAimPos 
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spSetUnitDirection  = Spring.SetUnitDirection 
local spTransferUnit = Spring.TransferUnit
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitDefID = Spring.GetUnitDefID

local spGetUnitVelocity  = Spring.GetUnitVelocity
--local spSetUnitPhysics  = Spring.SetUnitPhysics
local spSetUnitVelocity = Spring.SetUnitVelocity
local spMoveCtrlSetVelocity = Spring.MoveCtrl.SetVelocity
local spMoveCtrlEnable = Spring.MoveCtrl.Enable
--local spMoveCtrlSetPhysics = Spring.MoveCtrl.SetPhysics
local spMoveCtrlSetGravity = Spring.MoveCtrl.SetGravity
local spMoveCtrlSetPosition = Spring.MoveCtrl.SetPosition
--------------------------------------------------------------------------------
--local gunshipsID = {}
--local airplaneID = {}
--local updateRate_1 = 1 --update rate for checking airplane landing
local measureMapGravity ={1, fakeUnitID= nil, gravity=nil}
local flyingGroundUnitsID = {}
local updateRate_2 = 5 --update rate for ground unit's free flying trajectory
local updateRate_3 =1 --update rate for cloak status
--------------------------------------------------------------------------------
GG.isflying_watchout = {} --allow other gadget to signal gadget that this unit is flying. ie: "unit_jumpjet.lua" can do "GG.isflying_watchout[unitID]=true" to indicate that such unit is flying and should be targeted by AA.
--[[
	MANUAL:

	Do this to trigger AA detection from other gadget:
	1) make sure unit fulfill this condition: 
		- upward (or downward) velocity is > Game.gravity/30/30, OR the height below unit's feet is > 100 elmo (100 elmo from feet to ground).
	2) add the following value:
		- GG.isflying_watchout[unitID]=true
		
	The following happen:
	1) gadget iterate over the "GG.isflying_watchout",
	2) unitID(s) is added to a watchlist
	2) "GG.isflying_watchout" is emptied
	3) unitID get shot by AA when:
		- squareroot of its component-speed-squared combined is > 3.8 elmo-per-frame, AND the height below unit's feet is > 100 elmo.
	4) unit become landed when:
		- upward (or downward) velocity is < Game.gravity/30/30, AND the height below unit's feet is < 100 elmo.
	5) landed unitID(s) removed from watchlist
		
	You can exert velocity on any unit by:
	1) Spring.AddUnitImpulse(unitID, +velx, +vely, +velz); or...
	2) Spring.MoveCtrl.Enable(unitID); Spring.MoveCtrl.SetVelocity(unitID, velx, vely,velz); Spring.MoveCtrl.Disable(unitID)
--]]

function gadget:GameFrame(n)
	if n==1 and measureMapGravity[1] ==1 then --only took 2 frame to finish measurement
		measureMapGravity.fakeUnitID = spCreateUnit("fakeunit_aatarget", 0, 200, 0, "n", 0)
		spSetUnitNoSelect(measureMapGravity.fakeUnitID, true)
		spSetUnitNoDraw(measureMapGravity.fakeUnitID, true)
		spSetUnitNoMinimap(measureMapGravity.fakeUnitID, true)
		measureMapGravity[1] = 2
	elseif measureMapGravity[1] == 2 then
		local gravity = select(2,spGetUnitVelocity(measureMapGravity.fakeUnitID))
		spDestroyUnit(measureMapGravity.fakeUnitID, false, true)
		measureMapGravity.gravity= gravity
		--Spring.Echo("(2)Planet gravity is: "..gravity.. " elmo-per-frame-per-frame")
		measureMapGravity[1] = 3
	end
	--TODO: find way to save landed airplane from AA
	-- if n%updateRate_1 == 0 then --check all airplane every 1 frame. ~30fps.
		-- for unitID,_ in pairs(airplaneID) do
			-- local bx,by,bz = spGetUnitPosition(unitID)
			-- local groundHeight = spGetGroundHeight(bx,bz)
			-- if groundHeight+20 > by then
			-- end
		-- end
	-- end
	if n%updateRate_2 == 0 then --check flying units position every 5 frame. ~6fps. ballistic trajectory rarely need updates (unless unit accelerate then its good for dodging!).
		if #GG.isflying_watchout > 0 then
			for unitID,_ in pairs(GG.isflying_watchout) do --retrieve any new AA target from outside
				if unitID and flyingGroundUnitsID[unitID] == nil then
					local unitTeam = spGetUnitTeam(unitID)
					local unitDefID = spGetUnitDefID(unitID)
					local stealth = UnitDefs[unitDefID].stealth
					flyingGroundUnitsID[unitID]={unitTeam=unitTeam,stealth=stealth, aaMarker=nil, teamChange=nil}
					GG.isflying_watchout[unitID] = nil
				end
			end
		end
		for unitID,_ in pairs(flyingGroundUnitsID) do
			local bx,by,bz,mx,my,mz = spGetUnitPosition(unitID, true)
			local velX,velY,velZ = spGetUnitVelocity(unitID)
			local groundHeight = spGetGroundHeight(bx,bz)
			local landed = false
			if by < groundHeight+100 and math.abs(velY) < math.abs(measureMapGravity.gravity) then --if low-elevation and vertical speed is less than of gravity then: assume unit has landed.
				landed = true
			end
			if not landed then
				if groundHeight+100 < by then
					local netVelocity = math.sqrt(velX*velX+velY*velY +velZ*velZ)
					if netVelocity > 3.8 then --if flying unit is flying faster than the fastest "glaives", then mark it for AA. (Such floating unit look like airplane in radar dot.)  
						local aaMarker = flyingGroundUnitsID[unitID].aaMarker
						if not aaMarker then --if flying unit not yet have FAKE AA marker:
							local unitTeam = flyingGroundUnitsID[unitID].unitTeam
							local stealth = flyingGroundUnitsID[unitID].stealth
							local cloaked = spGetUnitIsCloaked(unitID)
							local _,_,_,offX,offY,offZ = spGetUnitCollisionVolumeData(unitID)
							aaMarker = spCreateUnit("fakeunit_aatarget",mx,my+100,mz, "s", unitTeam) --create FAKE AA marker 100 elmo above unit. We can't spawn it inside flying unit because they will collide.
							spSetUnitRadiusAndHeight(aaMarker,0,0) --set FAKE unit's colvol as small as possible
							spSetUnitMidAndAimPos(aaMarker,0,0,0,offX,-100+offY,offZ, true)  --translate FAKE's aimpoin to flying unit's midpoint. NOTE: We rely on AA to have "cylinderTargeting" which can detect unit at infinite height (ie: +100 elmo)
							spSetUnitBlocking(aaMarker, false,false) --set FAKE to not collide. But its not perfect, that's why we need to move FAKE's colvol 100elmo away
							spSetUnitNoSelect(aaMarker, true)  --don't allow player to use the FAKE
							spSetUnitNoDraw(aaMarker, true) --don't hint player that FAKE exist
							spSetUnitNoMinimap(aaMarker, true)
							flyingGroundUnitsID[unitID].aaMarker = aaMarker
							spMoveCtrlEnable(aaMarker) --needed because "spSetUnitVelocity" callins has issues (setting velocity in x & z axis didn't do anything)
							spMoveCtrlSetGravity(aaMarker,measureMapGravity.gravity) --we use our measured gravity value. Conversion for gravity: "mapGravity/30/30" doesn't look like a valid conversion, thus we better make a system that is both compatible with future fixes and current system.
							spSetUnitCloak(aaMarker,cloaked,0)
							spSetUnitStealth(aaMarker,stealth)
						end
						--spSetUnitPhysics(aaMarker,mx, my+100,mz,velX,velY,velZ,0,0,0)
						--spMoveCtrlSetPhysics(aaMarker,mx, my+100,mz,velX,velY,velZ,0,0,0) --NOTE: physics callins has issues setting velocity
						spMoveCtrlSetVelocity(aaMarker,velX,velY,velZ)
						spMoveCtrlSetPosition(aaMarker,mx, my+100,mz)
						spSetUnitDirection(aaMarker,0,0,1) --make sure FAKE is exactly facing at right angle. This make sure that aiming point below it stays on the unit
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
	if n%updateRate_3 == 0 then --update cloak status every 1 frame. ~30fps. depends on player's energy and ect.
		for unitID,_ in pairs(flyingGroundUnitsID) do
			local aaMarker = flyingGroundUnitsID[unitID].aaMarker
			if aaMarker then
				if flyingGroundUnitsID[unitID].teamChange == 1 then --if flying unit is transfered to enemy team, then: recreate FAKE AA
					--// recreate unit so that its targeting doesn't get fixated on FAKE AA (shooting ownself)
					spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
					local bx,by,bz,mx,my,mz = spGetUnitPosition(unitID, true)
					local velX,velY,velZ = spGetUnitVelocity(unitID)
					local _,_,_,offX,offY,offZ = spGetUnitCollisionVolumeData(unitID)
					aaMarker = spCreateUnit("fakeunit_aatarget",mx,my+100,mz, "s", flyingGroundUnitsID[unitID].unitTeam) --create FAKE AA marker 100 elmo above unit. We can't spawn it inside flying unit because they will collide.
					flyingGroundUnitsID[unitID].aaMarker = aaMarker
					spSetUnitRadiusAndHeight(aaMarker,0,0) --set FAKE unit's colvol as small as possible
					spSetUnitMidAndAimPos(aaMarker,0,0,0,offX,-100+offY,offZ, true)  --translate FAKE's aimpoin to flying unit's midpoint. NOTE: We rely on AA to have "cylinderTargeting" which can detect unit at infinite height (ie: +100 elmo)
					spSetUnitBlocking(aaMarker, false,false) --set FAKE to not collide. But its not perfect, that's why we need to move FAKE's colvol 100elmo away
					spSetUnitNoSelect(aaMarker, true)  --don't allow player to use the FAKE
					spSetUnitNoDraw(aaMarker, true) --don't hint player that FAKE exist
					spSetUnitNoMinimap(aaMarker, true)
					spMoveCtrlEnable(aaMarker) --needed because "spSetUnitVelocity" callins has issues (setting velocity in x & z axis didn't do anything)
					spMoveCtrlSetGravity(aaMarker,measureMapGravity.gravity) --we use our measured gravity value. Conversion for gravity: "mapGravity/30/30" doesn't look like a valid conversion, thus we better make a system that is both compatible with future fixes and current system.
					spMoveCtrlSetVelocity(aaMarker,velX,velY,velZ)
					spSetUnitDirection(aaMarker,0,0,1) --make sure FAKE is exactly facing at right angle. This make sure that aiming point below it stays on the unit
				elseif flyingGroundUnitsID[unitID].teamChange == 2 then --if flying unit is transfered to ally team, then: transfer FAKE AA
					--// transfer unit instead of recreating, so that it doesn't get abused to mess with enemy AA
					GG.allowTransfer = true --allow unit transfer. Ref: game_lagmonitor.lua, KingRaptor
					spTransferUnit(aaMarker, flyingGroundUnitsID[unitID].unitTeam) --transfer unit to other team
					GG.allowTransfer = false
				end
				flyingGroundUnitsID[unitID].teamChange = nil
				--// update cloak status
				local stealth = flyingGroundUnitsID[unitID].stealth
				local cloaked = spGetUnitIsCloaked(unitID)
				spSetUnitCloak(aaMarker,cloaked,0)
				spSetUnitStealth(aaMarker,stealth)
			end
		end
	end
end

--[[
function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if UnitDefs[unitDefID].canFly then
		local bx,by,bz,mx,my,mz,ax,ay,az = spGetUnitPosition(unitID, true,true)
		if UnitDefs[unitDefID].hoverAttack then
			gunshipsID[unitID]={ax=ax,ay=ay,az=az}
		else
			airplaneID[unitID]={ax=ax,ay=ay,az=az}
		end
	end 
end
--]]

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
			spDestroyUnit(flyingGroundUnitsID[unitID].aaMarker, false, true)
		end
		flyingGroundUnitsID[unitID] = nil
	end
	--airplaneID[unitID] = nil
	--gunshipsID[unitID] = nil
end

--We going to rely on UnitPreDamaged() to identify any units that might fly due to hax (ie: Newton, explosion, or collision with other units). This mean we exclude jumpjet since the jumping is not caused by weapons or collision.
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam) -- Working example: "Fall Damage", unit_fall_damage.lua, "Weapon Impulse", weapon_impulse.lua, by GoogleFrog 
	if not UnitDefs[unitDefID].canFly and not flyingGroundUnitsID[unitID] then
		if (not UnitDefs[unitDefID].isBuilding
		and not UnitDefs[unitDefID].isFactory) then --precautionary check of units that shouldn't be in combat. 
			local stealth = UnitDefs[unitDefID].stealth
			flyingGroundUnitsID[unitID]={unitTeam=unitTeam,stealth=stealth, aaMarker=nil, teamChange=nil} --we check again later if they actually fly
		end
	end
	if flyingGroundUnitsID[unitID] and flyingGroundUnitsID[unitID].aaMarker and (weaponDefID>0 and damage > 0) and attackerTeam ~= unitTeam then --flying unit's AA marker is active
		local attackerIsAA = false
		local listOfWeapons = UnitDefs[attackerDefID].weapons
		for i=1, #listOfWeapons do
			if listOfWeapons[i].weaponDef == weaponDefID then
				local attacker_target = listOfWeapons[i].onlyTargets 
				attackerIsAA = (attacker_target["fixedwing"] and attacker_target["gunship"]) and not (attacker_target["sink"] or attacker_target["land"] or attacker_target["sub"])
				break
			end
		end
		if attackerIsAA then
			local defaultDamage = WeaponDefs[weaponDefID].damages
			local maxDamage=0
			for i=1, #defaultDamage do --cycle thru all armortype
				if WeaponDefs[weaponDefID].damages[i] > maxDamage then
					maxDamage = WeaponDefs[weaponDefID].damages[i]
				end
			end
			return maxDamage --return designed damage, not 10% (we do not change the UnitDef because 10% sounds good to prevent friendly fire from stray missile)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else-- UNSYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end