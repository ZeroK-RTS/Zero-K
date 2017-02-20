function widget:GetInfo() return {
	name    = "Sniper Finder 2",
	desc    = "sniper on the roof!",
	license = "PD",
	layer   = -2,
	enabled = false,
} end

local sniperDefID = WeaponDefNames.armsnipe_shockrifle.id
local sniperRange = WeaponDefNames.armsnipe_shockrifle.range

local basicTacnuke = {b = 900, r = 300, l = 15}
local empTacnuke = {b = 2500, r = 700, l = 200} -- fairly asspulled but roughly works
local tacnukeRanges = {
	[WeaponDefNames.tacnuke_weapon.id] = basicTacnuke,
	[WeaponDefNames.napalmmissile_weapon.id] = basicTacnuke,
	[WeaponDefNames.empmissile_emp_weapon.id] = empTacnuke,
	[WeaponDefNames.seismic_seismic_weapon.id] = basicTacnuke,
}
local tacnukeRange = WeaponDefNames.tacnuke_weapon.range

local berthas = {
	[WeaponDefNames.armbrtha_plasma.id] = true,

	-- two are enough to triangulate
	[WeaponDefNames.raveparty_red_killer.id] = true,
	[WeaponDefNames.raveparty_orange_roaster.id] = true,
}
local foundBerthas = {}
local potentialBerthas = {}

local enabledSnipers
local enabledTacnukes
local enabledBerthas
local enabledAny

local myTeamID
local spectating

local function RebuildGlobals()
	spectating = Spring.GetSpectatingState ()
	enabledAny = (not spectating) and (enabledSnipers or enabledTacnukes or enabledBerthas)
	myTeamID = Spring.GetMyTeamID()
end

options_path = 'Game/Unit Marker'
options_order = { 'trace_snipers', 'trace_tacnukes', 'trace_berthas' }
options = {
	trace_snipers = {
		name = "Trace snipers",
		desc = "Approximate location of snipers based on shot trajectory.",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			enabledSnipers = self.value
			RebuildGlobals()
		end,
	},
	trace_tacnukes = {
		name = "Trace tacnukes",
		desc = "Approximate location of tacnuke silo based on shot trajectory.",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			enabledTacnukes = self.value
			RebuildGlobals()
		end,
	},
	trace_berthas = {
		name = "Trace berthas",
		desc = "Approximate location of long range plasma artillery based on shot trajectory.",
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			enabledBerthas = self.value
			RebuildGlobals()
		end,
	},
}

local abs = math.abs
local max = math.max
local spAreTeamsAllied            = Spring.AreTeamsAllied
local spGetGroundHeight           = Spring.GetGroundHeight
local spGetProjectileDefID        = Spring.GetProjectileDefID
local spGetProjectileTeamID       = Spring.GetProjectileTeamID
local spGetProjectilePosition     = Spring.GetProjectilePosition
local spGetProjectilesInRectangle = Spring.GetProjectilesInRectangle

local count = 0
local bullets = {}
local bulletsByID = {}

function widget:Initialize()
	RebuildGlobals()
end

function widget:PlayerChanged ()
	RebuildGlobals()
end

function widget:GameFrame (n)
	if not enabledAny then
		return
	end

	for i = 1, count do
		local bulletID = bullets[i]
		local bullet = bulletsByID[bulletID]
		bullet.alive = false
	end

	local projectiles = spGetProjectilesInRectangle (0, 0, Game.mapSizeX, Game.mapSizeZ)
	for i = 1, #projectiles do
		local projID = projectiles[i]
		local teamID = spGetProjectileTeamID (projID)
		local defID = spGetProjectileDefID (projID)

		if teamID and not spAreTeamsAllied(teamID, myTeamID) and defID
		and ((enabledSnipers and defID == sniperDefID)
		or (enabledTacnukes and tacnukeRanges[defID])
		or (enabledBerthas and berthas[defID])) then
			local bullet = bulletsByID[projID]
			local x, y, z = spGetProjectilePosition (projID)
			if bullet then
				bullet.alive = true
				bullet.x2 = x
				bullet.y2 = y
				bullet.z2 = z
			else
				count = count + 1
				bullets[count] = projID
				local newBullet = {
					x1 = x,
					x2 = x,
					y1 = y,
					y2 = y,
					z1 = z,
					z2 = z,
					alive = true,
					defID = defID,
					unitID = Spring.GetProjectileOwnerID(projID)
				}
				bulletsByID[projID] = newBullet
			end
		end
	end

	local i = 1
	while i <= count do
		local bulletID = bullets[i]
		local bullet = bulletsByID[bulletID]
		if not bullet.alive then
			local lastBulletID = bullets[count]
			bullets[i] = lastBulletID
			bullets[count] = nil
			count = count - 1
			bulletsByID[bulletID] = nil

			local x = bullet.x2
			local y = bullet.y2
			local z = bullet.z2

			local xx = bullet.x1 - x
			local yy = bullet.y1 - y
			local zz = bullet.z1 - z
	
			local angle = math.atan2(zz, xx)
			local dx = math.cos (angle)
			local dz = math.sin (angle)

			local defID = bullet.defID
			if defID == sniperDefID then
				local tx = x + sniperRange * dx
				local tz = z + sniperRange * dz
				local ty = spGetGroundHeight (tx, tz) + 10

				Spring.MarkerAddLine (x, y, z, tx, ty, tz)
				Spring.MarkerAddPoint (tx, ty, tz, "!")
			elseif tacnukeRanges[defID] then
				local dy = yy / math.sqrt(xx * xx + zz * zz)
				local found = false
				local heightData = tacnukeRanges[defID]
				local wantedHeight = heightData.b + heightData.r * math.tan((math.atan(dy) / 2) + math.pi / 4)
				local leeway = heightData.l
				local consecutiveX, consecutiveZ
				for i = 0, tacnukeRange, 20 do
					local tx = x + i * dx
					local ty = y + i * dy
					local tz = z + i * dz
					if tx < 0 or tz < 0 or tx >= Game.mapSizeX or tz >= Game.mapSizeZ then
						break
					end
					local h = max(0, spGetGroundHeight(tx, tz))
					if (abs (ty - h - wantedHeight) < leeway) then
						if not consecutiveX then
							found = true
							consecutiveX = tx
							consecutiveZ = tz
						end
					else
						if consecutiveX then
							Spring.MarkerAddLine (consecutiveX, spGetGroundHeight(consecutiveX, consecutiveZ), consecutiveZ, tx, spGetGroundHeight(tx, tz), tz)
							local avgX = (consecutiveX + tx) / 2
							local avgZ = (consecutiveZ + tz) / 2
							Spring.MarkerAddPoint (avgX, spGetGroundHeight(avgX, avgZ), avgZ, "!")
							consecutiveX = nil
						end
					end
				end
				if not found then
					local tx = x + dx * tacnukeRange
					local tz = z + dz * tacnukeRange
					local ty = spGetGroundHeight(tx, tz) + 5
					Spring.MarkerAddPoint (tx, ty, tz, "!")
					Spring.MarkerAddLine (x, y, z, tx, ty, tz)
				end
			else -- elseif berthas[defID] then
				local bertha = bullet.unitID
				if bertha then
					if potentialBerthas[bertha] then
						local previousBullet = potentialBerthas[bertha]
						potentialBerthas[bertha] = nil

						local tx, tz = 123, 123 -- FIXME: i forgot how to intersect and dont have internet atm to check
						--Spring.MarkerAddPoint (tx, spGetGroundHeight(tx, tz), tz, "!")

						foundBerthas[bertha] = true
					elseif not foundBerthas[bertha] then
						potentialBerthas[bertha] = bullet
					end
				end
			end
		else
			i = i + 1
		end
	end
end
