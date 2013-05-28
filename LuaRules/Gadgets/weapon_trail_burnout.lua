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

local spGetGameFrame     = Spring.GetGameFrame
local spSetProjectileCeg = Spring.SetProjectileCEG
local scSetWatchWeapon   = Script.SetWatchWeapon

function gadget:Initialize()
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]
		if wd.customParams then
			if wd.customParams.trail_burnout then
				burnoutWeapon[wd.id] = {
					burnout = wd.customParams.trail_burnout,
					burnoutCeg = wd.customParams.trail_burnout_ceg or defaultCeg
				}
				scSetWatchWeapon(wd.id, true)
			end
		end
	end
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponID)
	if burnoutWeapon[weaponID] then
		burnoutProjectile[proID] = {
			startFrame = spGetGameFrame(),
			burnout = burnoutWeapon[weaponID].burnout,
			burnoutCeg = burnoutWeapon[weaponID].burnoutCeg or defaultCeg
		}
	end
end

function gadget:ProjectileDestroyed(proID, proOwnerID, weaponID)
	burnoutProjectile[proID] = nil
end

function gadget:GameFrame(f)
	for id, proj in pairs(burnoutProjectile) do
		if proj.startFrame+proj.burnout <= f then
			spSetProjectileCeg(id, proj.burnoutCeg)
			burnoutProjectile[id] = nil
		end
	end
end

end
----- END SYNCED ---------------------------------------------------
