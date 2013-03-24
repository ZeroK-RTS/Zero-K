
function gadget:GetInfo()
  return {
    name      = "Max HP increasing attack",
    desc      = "When any unit is damaged by a predefined unit with a predefined " ..
	"weapon, an amount of HP equal to the damage is added to the max HP of the attacking unit",
    author    = "Sphiloth aka. Alcur",
    date      = "18 February 2013",
    license   = "BSD 3-clause",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if not gadgetHandler:IsSyncedCode() then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- options start

local affectedUnitName = "corsumo"

-- 304 is the Sumo/Scorpion pulsed beam weapon
local affectedWeaponDefID = 304

-- options end


local spGetUnitStates = Spring.GetUnitStates
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spEcho = Spring.Echo
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spSetUnitMaxHealth = Spring.SetUnitMaxHealth
local spAreTeamsAllied = Spring.AreTeamsAllied
local abs = math.abs


local maxEchoableTableValues = 10000
function recEcho(t, prefix)
    local maxValues = maxEchoableTableValues
    local i = 0

    local function insideEcho(t, prefix)
        for k,v in pairs(t) do
            if i >= maxValues then
                return
            end
            spEcho(tostring(prefix) .. tostring(k) .. ", " .. tostring(v))
            i = i + 1
            if type(v) == "table" then
                insideEcho(v, prefix .. k .. ": ")
            end
        end
    end

    insideEcho(t, prefix)
end



function gadget:UnitDamaged(uID, uDefID, teamID, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)

    if attackerID and UnitDefs[attackerDefID].name == affectedUnitName and
	not (attackerTeam == teamID or spAreTeamsAllied(teamID, attackerTeam)) then

		--[[
        spEcho("Unit damaged - unit ID: " .. uID .. ", unit def ID: " .. uDefID .. ", team ID: " .. teamID ..
        ", damage: " .. damage .. ", paralyzer: " .. tostring(paralyzer) .. ", weaponDefID: " .. weaponDefID ..
        ", attackerID: " .. attackerID .. ", attackerDefID: " .. attackerDefID .. ", attackerTeam: " .. attackerTeam)
		]]--


		-- the following crude commented out code can be used to echo all weaponDef key-value pairs for the used weapon
		-- maxEchoableTableValues can be used reduce the amount of lines printed

		--[[
        local i = 0
        for k, v in WeaponDefs[weaponDefID]:pairs() do
            if i > maxEchoableTableValues then break end
            local prefix = "WeaponDefs[" .. weaponDefID .. "]: "
            spEcho(prefix .. tostring(k) .. ", " .. tostring(v))
            if type(v) == "table" then
                prefix = prefix .. k .. ": "
                recEcho(v, prefix)
            end
            i = i + 1
        end
		]]--


        if weaponDefID == affectedWeaponDefID then
			local _, maxH = spGetUnitHealth(attackerID)
            spSetUnitMaxHealth(attackerID, maxH + damage)
        end


    end

end

