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

local units = {}
local n_units = 0

local fold_frames = 7 -- every seventh frame
local n_folds = 4 -- check every fourth unit
local current_fold = 0

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
        units[unitID] = uddim.height
    end
end

function gadget:UnitDestroyed(unitID)
    units[unitID] = nil
end

function gadget:GameFrame(n)
    if n%fold_frames == 0 then
        if current_fold > n_folds then
            current_fold = 0
        end
        
        local i = 0
        for u,h in pairs(units) do
            i = i+1
            if i % n_folds == current_fold then
                local udn = UnitDefs[Spring.GetUnitDefID(u)].name
                local x,y,z = Spring.GetUnitPosition(u)
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
        n_units = i -- this is now usable for dynamic folding 
        current_fold = current_fold+1
    end
end
