function gadget:GetInfo()
	return {
		name = "Trail Burnout",
		desc = "Changes weapon trail CEG after a customParam-specified time",
		author = "Anarchid",
		date = "14.01.2013",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

------ SYNCED -------------------------------------------------------
if (gadgetHandler:IsSyncedCode() and enabled) then 

local defaultCeg = ''
local burnoutWeapon = {}
local burnoutProjectile = {}
local spSetProjectileCeg = Spring.SetProjectileCEG
local curFrame = 0

function gadget:Initialize()
	local j = 0;
	for i=1,#WeaponDefs do
		j=j+1;
		local wd = WeaponDefs[i]
		if wd.customParams then
			if wd.customParams.trail_burnout then
				burnoutWeapon[wd.id] = {
					burnout = wd.customParams.trail_burnout,
					burnoutCeg = wd.customParams.trail_burnout_ceg or defaultCeg
				}
				Script.SetWatchWeapon(wd.id, true)
			end
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if burnoutWeapon[weaponID] then
		burnoutProjectile[proID] = {
			startFrame = curFrame,
			burnout = burnoutWeapon[weaponID].burnout,
			burnoutCeg = burnoutWeapon[weaponID].burnoutCeg or defaultCeg
		}
	end
end	

function gadget:ProjectileDestroyed(proID, proOwnerID, weaponID)
	burnoutProjectile[proID] = nil
end	

function gadget:GameFrame(f)
	curFrame = f
	for id, proj in pairs(burnoutProjectile) do
		if proj.startFrame+proj.burnout <= f then
			spSetProjectileCeg(id, proj.burnoutCeg)
			burnoutProjectile[id] = nil
		end
	end	
end
	
end 
----- END SYNCED ---------------------------------------------------
