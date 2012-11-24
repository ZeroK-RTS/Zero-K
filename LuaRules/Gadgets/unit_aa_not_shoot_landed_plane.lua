function gadget:GetInfo()
  return {
    name      = "AA do not target landed airplane",
    desc      = "Make airplane not targetable by AA when it land while still targetable by ground units.",
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
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetGroundHeight = Spring.GetGroundHeight
local spGetUnitIsCloaked  = Spring.GetUnitIsCloaked
local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spSetUnitBlocking = Spring.SetUnitBlocking
local spSetUnitCloak  = Spring.SetUnitCloak 
local spSetUnitStealth  = Spring.SetUnitStealth
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight
local spSetUnitMidAndAimPos  = Spring.SetUnitMidAndAimPos 
local spSetUnitCollisionVolumeData = Spring.SetUnitCollisionVolumeData
local spSetUnitDirection  = Spring.SetUnitDirection 
local spTransferUnit = Spring.TransferUnit
local spGetTeamInfo = Spring.GetTeamInfo
local spGetUnitTeam = Spring.GetUnitTeam
local spGetUnitTooltip  = Spring.GetUnitTooltip
local spSetUnitTooltip  = Spring.SetUnitTooltip

local mcEnable = Spring.MoveCtrl.Enable
local mcSetGravity = Spring.MoveCtrl.SetGravity
--------------------------------------------------------------------------------
local airplaneID = {}
local fakeGroundToAirplaneID ={}
local updateRate_1 = 10 --update rate for checking airplane landing
local updateRate_3 =1 --update rate for cloak status
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if n%updateRate_1 == 0 then --check all airplane every 10 frame (0.33 sec). ~3fps.
		for unitID,_ in pairs(airplaneID) do
			local bx,by,bz = spGetUnitPosition(unitID)
			if bx and bz then --check if inside map & to fix a strange behaviour where airplane taking off suddenly return a NIL position.
				local groundHeight = spGetGroundHeight(bx,bz)
				local velX,velY,velZ = spGetUnitVelocity(unitID)
				if groundHeight+30 > by and math.abs(velY) < 0.1 then
					local fakeGround = airplaneID[unitID].fakeGround
					if not fakeGround then
						local sclX = airplaneID[unitID].colvol[1]
						local sclY = airplaneID[unitID].colvol[2]
						local sclZ = airplaneID[unitID].colvol[3]
						local offX = airplaneID[unitID].colvol[4]
						local offY = airplaneID[unitID].colvol[5]
						local offZ = airplaneID[unitID].colvol[6]
						local a = airplaneID[unitID].colvol[7]
						local b = airplaneID[unitID].colvol[8]
						local c = airplaneID[unitID].colvol[9]
						spSetUnitMidAndAimPos(unitID,0,-30,0,0,0,0, true)
						spSetUnitCollisionVolumeData(unitID, sclX,sclY,sclZ,offX,30,offZ,a,b,c)
						local tooltip = spGetUnitTooltip(unitID)
						local fakeGround = spCreateUnit("fakeunit_groundtarget",bx,by,bz, "s", airplaneID[unitID].unitTeam)
						local stealth = airplaneID[unitID].stealth
						local cloaked = spGetUnitIsCloaked(unitID)
						mcEnable(fakeGround)
						mcSetGravity(0)
						spSetUnitBlocking(fakeGround, false,false)
						spSetUnitRadiusAndHeight(fakeGround,1,1)
						spSetUnitNoSelect(fakeGround, true)  --don't allow player to use the FAKE
						spSetUnitNoDraw(fakeGround, true) --don't hint player that FAKE exist
						spSetUnitNoMinimap(fakeGround, true)				
						spSetUnitStealth(fakeGround,stealth)
						spSetUnitTooltip(fakeGround, tooltip)
						spSetUnitCloak(fakeGround,cloaked,0)
						airplaneID[unitID].fakeGround = fakeGround
					end
				else --if floating or is trying to take-off/landing
					if airplaneID[unitID].fakeGround then
						spDestroyUnit(airplaneID[unitID].fakeGround, false, true)
						spSetUnitMidAndAimPos(unitID,0,0,0,0,0,0, true)
						local sclX = airplaneID[unitID].colvol[1]
						local sclY = airplaneID[unitID].colvol[2]
						local sclZ = airplaneID[unitID].colvol[3]
						local offX = airplaneID[unitID].colvol[4]
						local offY = airplaneID[unitID].colvol[5]
						local offZ = airplaneID[unitID].colvol[6]
						local a = airplaneID[unitID].colvol[7]
						local b = airplaneID[unitID].colvol[8]
						local c = airplaneID[unitID].colvol[9]
						spSetUnitCollisionVolumeData(unitID, sclX,sclY,sclZ,offX,offY,offZ,a,b,c) 
						airplaneID[unitID].fakeGround = nil
					end
				end
			else --if return NIL position or is outside map
				if airplaneID[unitID].fakeGround then
					spDestroyUnit(airplaneID[unitID].fakeGround, false, true)
					spSetUnitMidAndAimPos(unitID,0,0,0,0,0,0, true)
					local sclX = airplaneID[unitID].colvol[1]
					local sclY = airplaneID[unitID].colvol[2]
					local sclZ = airplaneID[unitID].colvol[3]
					local offX = airplaneID[unitID].colvol[4]
					local offY = airplaneID[unitID].colvol[5]
					local offZ = airplaneID[unitID].colvol[6]
					local a = airplaneID[unitID].colvol[7]
					local b = airplaneID[unitID].colvol[8]
					local c = airplaneID[unitID].colvol[9]
					spSetUnitCollisionVolumeData(unitID, sclX,sclY,sclZ,offX,offY,offZ,a,b,c) 
					airplaneID[unitID].fakeGround = nil
				end
			end
		end
	end
	if n%updateRate_3 == 0 then --handle cloak status, unit transfer, and unit explode. Update every 1 frame. ~30fps.
		for unitID,_ in pairs(airplaneID) do
			local fakeGround = airplaneID[unitID].fakeGround
			if fakeGround then
				if airplaneID[unitID].teamChange == 1 then --if flying unit is transfered to enemy team, then: recreate FAKE AA
					--// recreate unit so that its targeting doesn't get fixated on FAKE AA (shooting ownself)
					spDestroyUnit(airplaneID[unitID].fakeGround, false, true)
					local bx,by,bz = spGetUnitPosition(unitID)
					local tooltip = spGetUnitTooltip(unitID)
					local stealth = airplaneID[unitID].stealth
					local cloaked = spGetUnitIsCloaked(unitID)
					fakeGround = spCreateUnit("fakeunit_groundtarget",bx,by,bz, "s", airplaneID[unitID].unitTeam) --create FAKE AA marker 100 elmo above unit. We can't spawn it inside flying unit because they will collide.
					mcEnable(fakeGround)
					mcSetGravity(0)
					airplaneID[unitID].fakeGround = fakeGround
					spSetUnitRadiusAndHeight(fakeGround,1,1) --set FAKE unit's colvol as small as possible
					spSetUnitBlocking(fakeGround, false,false)
					spSetUnitNoSelect(fakeGround, true)  --don't allow player to use the FAKE
					spSetUnitNoDraw(fakeGround, true) --don't hint player that FAKE exist
					spSetUnitNoMinimap(fakeGround, true)
					spSetUnitStealth(fakeGround,stealth)
					spSetUnitTooltip(fakeGround, tooltip)
					spSetUnitCloak(fakeGround,cloaked,0)
				elseif airplaneID[unitID].teamChange == 2 then --if flying unit is transfered to ally team, then: transfer FAKE AA
					--// transfer unit instead of recreating, so that it doesn't get abused to mess with enemy AA
					GG.allowTransfer = true --allow unit transfer. Ref: game_lagmonitor.lua, KingRaptor
					spTransferUnit(fakeGround, airplaneID[unitID].unitTeam) --transfer unit to other team
					GG.allowTransfer = false
				end
				if airplaneID[unitID].destroyfake then
					spDestroyUnit(airplaneID[unitID].fakeGround, false, true)
					spSetUnitMidAndAimPos(unitID,0,0,0,0,0,0, true)
					local sclX = airplaneID[unitID].colvol[1]
					local sclY = airplaneID[unitID].colvol[2]
					local sclZ = airplaneID[unitID].colvol[3]
					local offX = airplaneID[unitID].colvol[4]
					local offY = airplaneID[unitID].colvol[5]
					local offZ = airplaneID[unitID].colvol[6]
					local a = airplaneID[unitID].colvol[7]
					local b = airplaneID[unitID].colvol[8]
					local c = airplaneID[unitID].colvol[9]
					spSetUnitCollisionVolumeData(unitID, sclX,sclY,sclZ,offX,offY,offZ,a,b,c) 
					airplaneID[unitID].fakeGround = nil
				else
					--// update cloak status
					local cloaked = spGetUnitIsCloaked(unitID)
					spSetUnitCloak(fakeGround,cloaked,0)
				end
				airplaneID[unitID].destroyfake = nil
				airplaneID[unitID].teamChange = nil
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if UnitDefs[unitDefID].canFly then
		local stealth = UnitDefs[unitDefID].stealth
		local sclX,sclY,sclZ,offX,offY,offZ,a,b,c = spGetUnitCollisionVolumeData(unitID)
		airplaneID[unitID]={stealth=stealth, fakeGround=nil, unitTeam=unitTeam, colvol={sclX,sclY,sclZ,offX,offY,offZ,a,b,c}}
	end 
end

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if airplaneID[unitID] then --change FAKE AA's team (incase flying unit is transfered to enemy team)
		airplaneID[unitID].unitTeam = unitTeam
		if airplaneID[unitID].fakeGround then --if there is preexisting FAKE AA marker, then recreate new one for new team, and destroy old FAKE AA marker.
			local _,_,_,_,_,newAllyTeam = spGetTeamInfo(unitTeam) --copied from unit_mex_overdrive.lua, by googlefrog
			local _,_,_,_,_,oldAllyTeam = spGetTeamInfo(oldTeam)
			if newAllyTeam ~= oldAllyTeam then
				airplaneID[unitID].teamChange=1 --signal to recreate FAKE AA
			else
				airplaneID[unitID].teamChange=2 --signal to transfer unit
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if airplaneID[unitID] then
		if airplaneID[unitID].fakeGround then
			airplaneID[unitID].destroyfake = true
		else
			airplaneID[unitID] = nil
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
else-- UNSYNCED ---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

end