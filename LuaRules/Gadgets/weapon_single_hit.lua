function gadget:GetInfo()
	return {
		name = "Single-Hit Weapon",
		desc = "Forces marked weapons to only inflict damage once per projectile per unit",
		author = "Anarchid",
		date = "25.03.2013",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

local spGetGameFrame = Spring.GetGameFrame

------ SYNCED -------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 

local isNewEngine = not (Game.version:find('91.0') and (Game.version:find('91.0.1') == nil))

local singleHitWeapon = {}
local singleHitUnitId = {}

local singleHitMultiWeapon = {}
local singleHitProjectile = {}

function gadget:Initialize()
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]
		if wd.customParams then
			if wd.customParams.single_hit then
				singleHitWeapon[wd.id] = true;
			end
			if isNewEngine and wd.customParams.single_hit_multi then
				Script.SetWatchWeapon(wd.id, true)
				singleHitMultiWeapon[wd.id] = true;
			end
		end
	end
end


function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if singleHitMultiWeapon[weaponID] then
		singleHitProjectile[proID] = {};
	end
end	

function gadget:ProjectileDestroyed(proID)
	if singleHitMultiWeapon[proID] then -- apparently setwatchweapon is not per-gadget. sad but true.
		singleHitProjectile[proID] = nil;
	end
end


function gadget:UnitPreDamaged(unitID,unitDefID,_, damage,_, weaponDefID,attackerID,_,_, projectileID)
	if singleHitWeapon[weaponDefID] then
		if attackerID then
			local frame = spGetGameFrame()
			if singleHitUnitId[attackerID] == nil then
				singleHitUnitId[attackerID] = {}
				singleHitUnitId[attackerID][unitID] = frame
			else
				if singleHitUnitId[attackerID][unitID] and frame - singleHitUnitId[attackerID][unitID] < 10 then
					singleHitUnitId[attackerID][unitID] = frame
					return 0
				else
					singleHitUnitId[attackerID][unitID] = frame
				end
			end
			return damage 
	
		end
	end
	
	if singleHitMultiWeapon[weaponDefID] then
		if not singleHitProjectile[projectileID] then
			singleHitProjectile[projectileID] = {}
		end
		if singleHitProjectile[projectileID][unitID] then
			return 0
		else
			singleHitProjectile[projectileID][unitID] = true
		end
		return damage 
	end
	
	return damage;
end

	
end 
----- END SYNCED ---------------------------------------------------
