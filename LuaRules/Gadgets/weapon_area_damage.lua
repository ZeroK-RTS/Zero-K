function gadget:GetInfo()
	return {
		name = "Area Denial",
		desc = "Lets a weapon's damage persist in an area",
		author = "KDR_11k (David Becker), Google Frog",
		date = "2007-08-26",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local frameNum
local explosionList = {}
local DAMAGE_PERIOD ,weaponInfo = include("LuaRules/Configs/area_damage_defs.lua")

function gadget:Explosion(weaponID, px, py, pz, ownerID)
	if (weaponInfo[weaponID]) then
		local w = {
			radius = weaponInfo[weaponID].radius,
			damage = weaponInfo[weaponID].damage,
			expiry = frameNum + weaponInfo[weaponID].duration,
			rangeFall = weaponInfo[weaponID].rangeFall,
			timeLoss = weaponInfo[weaponID].timeLoss,
			id = weaponID,
			pos = {x = px, y = py, z = pz},
			owner=ownerID,
		}
		table.insert(explosionList,w)
	end
	return false
end

local totalDamage = 0

function gadget:GameFrame(f)
	frameNum=f
	if (f%DAMAGE_PERIOD == 0) then
		for i,w in pairs(explosionList) do
			local ulist = Spring.GetUnitsInSphere(w.pos.x, w.pos.y, w.pos.z, w.radius)
			if (ulist) then
				for _,u in ipairs(ulist) do
					local ux, uy, uz = Spring.GetUnitPosition(u)
					local damage = w.damage
					if w.rangeFall ~= 0 then
						damage = damage - damage*w.rangeFall*math.sqrt((ux-w.pos.x)^2 + (uy-w.pos.y)^2 + (uz-w.pos.z)^2)/w.radius
					end
					Spring.AddUnitDamage(u, damage, 0, w.owner, w.id, 0, 0, 0)
				end
			end
			w.damage = w.damage - w.timeLoss
			if f >= w.expiry then
				explosionList[i] = nil
			end
		end
	end
end

function gadget:Initialize()
	for w,_ in pairs(weaponInfo) do
		Script.SetWatchWeapon(w, true)
	end
end

end
