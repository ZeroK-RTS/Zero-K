-- $Id: unit_webweapon.lua 4598 2009-05-09 21:26:39Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Web Weapons",
    desc      = "Anti Air Web Weapon",
    author    = "CarRepairer",
    date      = "2008-05-22",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- SYNCED
if (not gadgetHandler:IsSyncedCode()) then
  return false
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spGetUnitVelocity     = Spring.GetUnitVelocity
local spGetUnitSeparation   = Spring.GetUnitSeparation

local spSetUnitVelocity     = Spring.SetUnitVelocity
local spAddUnitImpulse      = Spring.AddUnitImpulse


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local webWeaponDefs = {}



function gadget:Initialize()
	for i=1,#WeaponDefs do
		if (WeaponDefs[i].name =="chicken_spidermonkey_web") then
			webWeaponDefs[i]=true
		end
	end
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)

	if not webWeaponDefs[weaponID] then return end
	local ud = UnitDefs[unitDefID or -1]
	if attackerID then -- and ud and ud.canFly then

		--local dist = spGetUnitSeparation(unitID, attackerID)
		
		local x1,y1,z1 = spGetUnitPosition(unitID)
		local gh = Spring.GetGroundHeight(x1,z1)
		if y1 > gh then
			
			local vx, vy, vz = spGetUnitVelocity(unitID)
			--spSetUnitVelocity(unitID, vx * 0.95, vy, vz * 0.95)
			spSetUnitVelocity(unitID, vx, vy -1, vz)
		else
			Spring.SetUnitPosition(unitID, x1,gh,z1)
		end
		--[[
		local mult = 1
		
		--if (ud.mass  > 100) then
		
		if ud.canFly then
			--mult = 0.5
		else
			if dist < 200 then return end
		end

		local x1,y1,z1 = spGetUnitPosition(unitID)
		local x2,y2,z2 = spGetUnitPosition(attackerID)

		local vecx = (x2-x1)*mult / dist
		local vecy = (y2-y1)*mult / dist
		local vecz = (z2-z1)*mult / dist

		spAddUnitImpulse(unitID, vecx, vecy, vecz)
		--]]

	end

end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
