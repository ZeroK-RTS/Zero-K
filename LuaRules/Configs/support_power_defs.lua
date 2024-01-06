
--[[ This file lists support powers, which are global abilities similar to
     the ones in Age of Mythology, C&C Generals/RA3, SC2:LotV coop/campaign or even DOTA glyph.

     Each entry has a few mandatory fields.

     TargetType: a string. Can be one of:

      * "unit", will target a visible unit.
        For example, AoM Zeus Bolt.

      * "feature", self-explanatory.

      * "position", a pair of X/Z coordinates.
        For example, AoM Earthquake, Generals A-10 strafe run,
        or DOTA Scan. Probably the most common power type.

      * "unit_or_position": either a unit or a position.
        This lets you target into the fog of war or give
        some leeway to snap. An example here is DOTA Zeus Bolt.
        If the second argument is nil, then the first arg is
        unit, otherwise it's the X coordinate of position.

      * "feature_or_position": obvious.

      * "unit_and_position": both a unit or a position.
        Useful for movement and vector-targeting.

      * "feature_and_position", obvious.

      * "position_and_position", accepts two positions.
        Think SC2 Solar Lance, RA Chronosphere or AoM Underground Passage.

      * "freestyle", can accept anything and it is up to the implementer
        to do validity checks and provide a casting UI. Examples here could include:
        - parameterless, like the DOTA glyph or AoM Rain (technically Rain was
          position-targeted, but its effects weren't).
        - accepts a teamID and a number, to transfer that much mana.
        - accepts an allyTeamID, to somehow curse that team.
        - accepts a height and a timer, to control rising lava tide cycle.
        - accepts a unitDefID to apply some unit type wide boost.
        - whatever else you can think of that can be done with up to 4 nonnegative integers.

    Another mandatory field is Cost:
     - has to be a function (FIXME make it possible to be a table or number)
     - accepts (self, teamID, arg1, arg2, arg3, arg4), with args dependent on the target type.
       Usually unit-targeted functions will want to define it as (self, teamID, unitID)
       while position-targeted will want to use (self, teamID, x, z), and so forth.
     - returns the mana cost of casting given power at given target (FIXME: let it return a table {metal, energy, mana})
     - also responsible for validity checks; returns `nil` if invalid
     - the function is called also from unsynced context, so be mindful of things
       being `nil` in unsynced (like private rules params on enemy units), currently
       these are disallowed. (FIXME solve this)
     - tip: perform allyteam checks here (no bolting allies, etc) (FIXME have default 'avoidFriendly' style tags for this)
     - tip: returned value can change depending on target (e.g. more expensive units == more cost)

     Apply:
     - a function with same args as Cost
     - no need for validity checks, every call is preceded by a valid Cost call and runs in synced only
     - applies the effects of the power

     Cooldown:
     - a function with same args as Cost
     - no need for validity checks, every call is preceded by a valid Cost+Apply call and runs in synced only
     - returns the cooldown in seconds (can be a fraction)
     - tip: avoid 0, set something low like 2 to avoid misclicks (FIXME it's the job of the gui part and not mechanics?)

     Then there's the optional Initialize field.
     - a function, accepts (self) as a parameter
     - ran once, at the start of the game
     - tip: initialize metadata here (see below)
     - tip: set initial cooldown here (FIXME have a default tag? or perhaps let a gadget set it in some other nice way)

	!! FIXME nothing in the GUI section below is actually implemented !!
			 The optional GUI table has the following optional fields:
			 - Image, the path to an icon for GUI button purposes.
			 - Description, a backup for when you don't provide a translation
			   via localisation files. This will be displayed unless the i18n
			   localisation for "support_desc_X" can be found, where X
			   is the name of the power.
			 - Name. Similar to the above, except for the name of the power
			   and with the i18n key being "support_name_X".
			 - AreaReticle. The radius of the targeting reticle
			   for use with area-of-effect powers.
			 - CursorGood. The name of the cursor to use for valid targets.
			   Defaults to "FIXME".
			 - CursorBad. The name of the cursor to use for invalid targets.
			   Defaults to "FIXME".
			 - Hidden. The default GUI widget won't display the power so requires
			   manual implementation.
			 - Priority. Decides the default order in which powers are listed.

     A power def can also contain arbitrary other fields. These are
     accessible via the `self` param in function calls. Use these
     for templated powers or tracking data between invocations.
]]

local sp = Spring

--[[ The first few entries here are simple examples which aren't polished enough for online play,
     so that modders can learn how to work with this interface; look below for the "real" ones. ]]
local PowerDefs = {

	add_resources = {
		TargetType = "freestyle", -- accepts no arguments
		Cost = function (self, teamID)
			return 50 -- just a flat mana cost, no fancy logic around potential excess and whatnot
		end,
		Cooldown = function (self, teamID)
			return 2 -- in seconds. Zero would've been fine, but it's good to prevent misclicks
		end,
		Apply = function (self, teamID)
			sp.AddTeamResource(teamID, "m", 20)
			sp.AddTeamResource(teamID, "e", 40)
		end,
		GUI = {
			Image = "LuaUI/Images/ibeam.png", -- For the button on the GUI.
			Name = "Add resources",
			Desc = "Receive 20 metal and 40 energy."
		},
	},



	zombify = {
		TargetType = "feature",

		Cost = function (self, teamID, featureID)
			local unitDefName = sp.GetFeatureResurrect(featureID)
			if not unitDefName or unitDefName == "" then
				--[[ Cost is responsible for validity checks, too.
				     Return nil to signify an invalid target.
				     "n00b, u cant rez a tree lol" ]]
				return
			end

			-- Dynamic cost example: scales with zombie cost
			return UnitDefNames[unitDefName].buildTime * (3 / 5)
		end,

		Cooldown = function (self, teamID, featureID)
			return 15
		end,

		Apply = function (self, teamID, featureID)
			local unitDefName, facing = sp.GetFeatureResurrect(featureID)
			local x, y, z = sp.GetFeaturePosition(featureID)
			sp.DestroyFeature(featureID)

			-- Make some fancy effects.
			sp.SpawnCEG("resurrect", x, y, z, 0, 0, 0, 5)
			GG.PlayFogHiddenSound("sounds/misc/resurrect.wav", 12, x, y, z) -- FIXME zk-specific gg func (also below)

			--[[ Hope the zombie modoption handles the unit from now on.
			     A fancier implementation could babysit the unit though. ]]
			sp.CreateUnit(unitDefName, x, y, z, facing, sp.GetGaiaTeamID())
		end,

		GUI = {
			Image = "LuaUI/Images/commands/Bold/resurrect.png",
			--[[ no name and desc (which results in cryptic text
			     in the GUI, but just to show it's optional) ]]
		},
	},



	cripple = {
		TargetType = "unit",
		Cost = function (self, teamID, unitID)
			--[[ Unit-targeted powers should remember to have
			     a team check in most cases. Note that the unitID,
			     and similar params for other target types, can
			     be assumed valid. ]]
			if sp.AreTeamsAllied(teamID, sp.GetUnitTeam(unitID)) then
				-- return nil to mark use as invalid
				return
			end

			return 25
		end,

		Cooldown = function (self, teamID, unitID)
			--[[ Example: cooldown gets lower over time for more liberal lategame use,
			     starting at 120s and going down at 1s per 30s of gametime, down to 5s ]]
			return math.max(5, 120 - (sp.GetGameFrame() / (Game.gameSpeed * 30)))
		end,

		Apply = function (self, teamID, unitID)
			--[[ Applies 2s EMP, 6s disarm, and 2s overslow.
			     The thresholds are magic values for simplicity, they
			     could be taken from various global constants probably. ]]
			local health, maxHealth, currentEMP = sp.GetUnitHealth(unitID)

			local empThreshold = 1.05 * maxHealth
			if currentEMP < empThreshold then
				sp.SetUnitHealth(unitID, {paralyze = empThreshold})
			end

			local disarmThreshold = 1.15 * maxHealth
			GG.addParalysisDamageToUnit(unitID, disarmThreshold, 6 * Game.gameSpeed)

			local slowThreshold = 0.58 * maxHealth
			GG.addSlowDamage(unitID, slowThreshold, 2)
		end,

		GUI = {
			Image = "LuaUI/Images/AttritionCounter/Skull.png",
			--[[ no name/desc here either, but it's present
			     in i18n so you can compare the results ]]
		},
	},


---------------------------------------------------------------------------------------------------------------------
-- Examples end here ------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------


	tacnuke = {
		TargetType = "position",
		Cost = function (self, teamID, x, z)
			if not sp.IsPosInLos(teamID, x, z) then
				return
			end

			return 600 -- maybe could be cheaper with multiple bombardment sources?
		end,
		Cooldown = function (self, teamID, x, z)
			return 70 -- enough for a single area shield to regen (for jethro cheeze etc)
		end,
		Apply = function (self, teamID, x, z)
			--[[ Reuses the real tacnuke for now, but would ideally
			     be a custom weapon (whose def can just copy the real
			     tacnuke if that is desired) ]]
			local weaponDefID = WeaponDefNames.tacnuke_weapon.id

			local y = math.max(0, sp.GetGroundHeight(x, z))
			sp.SpawnProjectile(weaponDefID, {
				pos = {x, y + 4500, z}, -- Maybe should come at an angle (for terrablock etc)?
				speed = {0, -50, 0}, -- ETA: 3s
			})
		end,
	},

	impalation = {
		TargetType = "position",
		Cost = function (self, teamID, x, z)
			if not sp.IsPosInLos(teamID, x, z) then
				return
			end
			return 125
		end,
		Cooldown = function (self, teamID, x, z)
			return 5
		end,
		Apply = function (self, teamID, x, z)
			-- see tacnuke for remarks
			local weaponDefID = WeaponDefNames.vehheavyarty_cortruck_rocket.id

			local y = math.max(0, sp.GetGroundHeight(x, z))
			sp.SpawnProjectile(weaponDefID, {
				pos = {x, y + 2250, z},
				speed = {0, -25, 0}, -- ETA: 3s
			})
		end,
	},
}

-- template that autogenerates "spawn unit" powers

local mexDefID = UnitDefNames.staticmex.id
local function IsNearMex(teamID, x, z, radius)
	local spGetUnitDefID = sp.GetUnitDefID
	local spGetUnitAllyTeam = sp.GetUnitAllyTeam
	local spGetUnitHealth = sp.GetUnitHealth
	local allyTeamID = select(6, sp.GetTeamInfo(teamID))
	local units = CallAsTeam(teamID, sp.GetUnitsInCylinder, x, z, radius, Script.ALLIED_UNITS)
	for i = 1, #units do
		local unitID = units[i]
		if  spGetUnitDefID(unitID) == mexDefID
		and spGetUnitAllyTeam(unitID) == allyTeamID
		and select(5, spGetUnitHealth(unitID)) == 1 then
			return true
		end
	end
	return false
end

local spawn_template = {
	TargetType = "position",
	Cost = function (self, teamID, x, z)
		if not sp.IsPosInLos(teamID, x, z) or (sp.TestBuildOrder(self.unitDefID, x, 0, z, 0) == 0) then
			return
		end

		if not IsNearMex(teamID, x, z, 256) then
			return
		end

		return UnitDefs[self.unitDefID].buildTime
	end,
	Apply = function (self, teamID, x, z)
		-- FIXME: GG.OrbitalDrop?
		sp.CreateUnit(self.unitDefID, x, 0, z, 0, teamID, false, false)
	end,
	Cooldown = function (self, teamID, x, z)
		return 2
	end,
	GUI = {
		Hidden = true, -- wants a fancy unit picker probably
	}
}

local sputCopyTable = sp.Utilities.CopyTable
local UnitDefs = UnitDefs
for _, facDef in pairs(UnitDefNames) do
	if facDef.customParams.factorytab then
		local roster = facDef.buildOptions
		for i = 1, #roster do
			local unitDefID = roster[i]
			PowerDefs["pw_spawn_" .. UnitDefs[unitDefID].name] = sputCopyTable(spawn_template, false, {unitDefID = unitDefID})
		end
	end
end



local vfs = VFS

if vfs.FileExists("LuaRules/Configs/support_powers_mod.lua", vfs.GAME) then
	sp.Utilities.CopyTable(vfs.Include("LuaRules/Configs/support_powers_mod.lua", nil, vfs.GAME), false, PowerDefs)
end

--[[ Maybe maps can have some fancy mechanics using the powers interface,
     like people could use a power to manually raise lava or something. ]]
if vfs.FileExists("LuaRules/Configs/support_powers_map.lua", vfs.MAP) then
	sp.Utilities.CopyTable(vfs.Include("LuaRules/Configs/support_powers_map.lua", nil, vfs.MAP), false, PowerDefs)
end

return PowerDefs
