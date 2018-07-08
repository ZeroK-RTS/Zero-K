--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
    return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Wade Effects",
		desc      = "Spawn wakes when non-ship ground units move while partially, but not completely submerged",
		author    = "Anarchid",
		date      = "March 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

local SFXTYPE_WAKE1 = 2
local SFXTYPE_WAKE2 = 3

local unit = {}
local units = {count = 0, data = {}}

local fold_frames = 7 -- every seventh frame
local n_folds = 4 -- check every fourth unit
local current_fold = 1

local function canWade(unitDefID)
    local moveDef = UnitDefs[unitDefID].moveDef
    if (moveDef and moveDef.family) then
        local mdFamily = moveDef.family
        if mdFamily == "kbot" or mdFamily == "tank" then
            return true
        end
    end
    return false
end

local function isMoving(unitID)
    local velocity = select(4, Spring.GetUnitVelocity(unitID))
    return velocity > 0
end

function gadget:UnitCreated(unitID, unitDefID)
    if canWade(unitDefID) then
        local uddim = Spring.GetUnitDefDimensions(unitDefID)
        if not unit[unitID] then
            units.count = units.count + 1
            units.data[units.count] = unitID
            unit[unitID] = {id = units.count, h = uddim.height}
        end
    end
end

function gadget:UnitDestroyed(unitID)
    if unit[unitID] then
        units.data[unit[unitID].id] = units.data[units.count]
        unit[units.data[units.count]].id = unit[unitID].id --shift last entry into empty space
        units.data[units.count] = nil
        units.count = units.count - 1
        unit[unitID] = nil
    end
end

function gadget:GameFrame(n)
    if n%fold_frames == 0 then
        local listData = units.data
        if current_fold > n_folds then
             current_fold = 1
        end
		
        for i = current_fold, units.count, n_folds do
            local unitID = listData[i]             
            local x,y,z = Spring.GetUnitPosition(unitID)
            local h = unit[unitID].h
            if y and h then
				-- emit wakes only when moving and not completely submerged
				if y > -h and y <= 0 and isMoving(unitID) and not Spring.GetUnitIsCloaked(unitID) then 
					local radius = Spring.GetUnitRadius(unitID)
					local effect = SFXTYPE_WAKE1
					if radius > 50 then 
						effect = SFXTYPE_WAKE2 
					end
					Spring.UnitScript.CallAsUnit(unitID, 
						function()
							Spring.UnitScript.EmitSfx(1,effect);
						end
					)
				end
			else
				gadget:UnitDestroyed(unitID)
            end
        end
        current_fold = current_fold + 1
    end
end
