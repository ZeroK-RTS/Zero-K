--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
SFXTYPE_WAKE1 = 2
SFXTYPE_WAKE2 = 3

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
local unit = {}
local units = {count = 0, data = {}}

local fold_frames = 7 -- every seventh frame
local n_folds = 4 -- check every fourth unit
local current_fold = 1

function canWade(unitDefID)
    local moveDef = UnitDefs[unitDefID].moveDef
    if(moveDef and moveDef.family) then
        local mdFamily = moveDef.family
        if mdFamily == "kbot" or mdFamily == "tank" then
            return true
        end
    else
        return false
    end
end

function isMoving(unitID)
    local _,_,_,velocity = Spring.GetUnitVelocity(unitID);
    return velocity > 0
end

function gadget:UnitCreated(unitID, unitDefID)
    if(canWade(unitDefID)) then
        local uddim = Spring.GetUnitDefDimensions(unitDefID)
		if not unit[unitID] then
			units.count = units.count + 1
			units.data[units.count] = unitID
            unit[unitID] = uddim.height
		end
    end
end

function gadget:GameFrame(n)
    if n%fold_frames == 0 then
        local listData = units.data
        if current_fold > n_folds then
             current_fold = 1
        end
	    for i=current_fold, units.count, n_folds do
      		local u = listData[i]
              
            if not Spring.ValidUnitID(u) then
                listData[i] = listData[units.count]
                listData[units.count] = nil
                units.count = units.count - 1
                unit[u] = nil
            else
                local x,y,z = Spring.GetUnitPosition(u)
                local h = unit[u]
                if y > -h and y <= 0 and isMoving(u) and not Spring.GetUnitIsCloaked(u) then -- emit wakes only when moving and not completely submerged
                    local radius = Spring.GetUnitRadius(u);
                    local effect = SFXTYPE_WAKE1
                    if radius>50 then sfx = SFXTYPE_WAKE2 end
                    Spring.UnitScript.CallAsUnit(u, function()
                        Spring.UnitScript.EmitSfx(1,effect);
                    end);
                end
            end
        end
        current_fold = current_fold+1
    end
end
