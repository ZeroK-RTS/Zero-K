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

------ SYNCED -------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 

local singleHitWeapon = {}
local singleHitProjectile = {}

function gadget:Initialize()
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]
		if wd.customParams then
			if wd.customParams.single_hit then
				Script.SetWatchWeapon(wd.id, true)
				singleHitWeapon[wd.id] = true;
				--Spring.Echo('Registered '..wd.name..' as single-hit weapon');
			end
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if singleHitWeapon[weaponID] then
		singleHitProjectile[proID] = {};
	end
end	

function gadget:ProjectileDestroyed(proID)
	if singleHitProjectile[proID] then -- apparently setwatchweapon is not per-gadget. sad but true.
		singleHitProjectile[proID] = nil;
	end
end

function gadget:UnitPreDamaged(unitID,unitDefID,_, damage,_, weaponDefID,_,_,_, projectileID)
	if singleHitWeapon[weaponDefID] then
		if projectileID then
			if singleHitProjectile[projectileID] == nil then
				singleHitProjectile[projectileID] = {};
				singleHitProjectile[projectileID][unitID] = true;
			else
				if singleHitProjectile[projectileID][unitID] then
					return 0;
				else
					singleHitProjectile[projectileID][unitID] = true;
				end
			end
			
			local unitFPX = UnitDefs[unitDefID].xsize / 2 -- somewhy these sizes are footprint doubled; 
			local unitFPZ = UnitDefs[unitDefID].zsize / 2
			local sizeFactor = math.sqrt(unitFPX*unitFPZ);

			-- original 0.5 + diag*0.5 causes glaives to be instagibbed because they're 2x2 -> multiplier is 2
			-- presumably this could be fixed by tweaking the actual damages instead... on everything
			return (damage/2 + sizeFactor*damage/4) 
	
		end
	end
	
	return damage;
end

	
end 
----- END SYNCED ---------------------------------------------------
