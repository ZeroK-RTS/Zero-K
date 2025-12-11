local INLOS_ACCESS = {inlos = true}

local function GetMass(health, cost)
	return (((cost/2) + (health/8))^0.6)*6.5
end
local spGetUnitHealth=Spring.GetUnitHealth
local spSetUnitMaxHealth=Spring.SetUnitMaxHealth
local spSetUnitHealth=Spring.SetUnitHealth
local spSetUnitCosts=Spring.SetUnitCosts
local spSetUnitMass=Spring.SetUnitMass
local spSetUnitRulesParam=Spring.SetUnitRulesParam

GG.att_CostMult={}
GG.att_HealthMult={}

---@type {[string|number]:AttributesHandlerFactory}
return{
    ---@type AttributesHandlerFactory
    HealthCostMass={
        handledAttributeNames={
            healthMult=true,healthAdd=true,cost=true,mass=true
        },
        new=function (unitID,unitDefID)
            local ud=UnitDefs[unitDefID]
            local origUnitHealth= ud.health
            local origUnitCost= ud.buildTime
            local HealthMultCur=1
            local HealthAddCur=0
            local CostMultCur=1
            local MassMultCur=1
            ---@type AttributesHandler
            return{
                newDataHandler=function (frame)
                    local healthMult=1
                    local healthAdd=0
                    local costMult=1
                    local massMult=1

                    ---@type AttributesDataHandler
                    return {
                        ---@param data {healthAdd:number?,healthMult:number?,cost:number?,mass:number?}
                        fold=function (data)
                            healthMult=healthMult*(data.healthMult or 1)
                            healthAdd=healthAdd+(data.healthAdd or 0)
                            costMult=costMult*(data.cost or 1)
                            massMult=massMult*(data.mass or 1)
                        end,
                        apply=function ()
                            GG.att_CostMult[unitID] = costMult
                            GG.att_HealthMult[unitID] = healthMult
	                        spSetUnitRulesParam(unitID, "costMult", costMult, INLOS_ACCESS)

                            if CostMultCur~=costMult or HealthAddCur~=healthAdd or MassMultCur~=massMult or HealthMultCur~=healthMult then
                                
                                local newMaxHealth = (origUnitHealth + healthAdd) * healthMult
                                local oldHealth, oldMaxHealth = spGetUnitHealth(unitID)
                                spSetUnitMaxHealth(unitID, newMaxHealth)
                                spSetUnitHealth(unitID, oldHealth * newMaxHealth / oldMaxHealth)
                                
                                local origCost = origUnitCost
                                local cost = origCost*costMult
                                spSetUnitCosts(unitID, {
                                    metalCost = cost,
                                    energyCost = cost,
                                    buildTime = cost,
                                })
                                
                                if massMult == 1 then
                                    -- Default to update mass based on new stats, if a multiplier is not set.
                                    local mass = GetMass(newMaxHealth, cost)
                                    spSetUnitMass(unitID, mass)
                                    spSetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
                                else
                                    local mass = GetMass(origUnitHealth, origCost) * massMult
                                    spSetUnitMass(unitID, mass)
                                    spSetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
                                end
                                CostMultCur=costMult
                                HealthAddCur=healthAdd
                                MassMultCur=massMult
                                HealthMultCur=healthMult
                            end
                        end
                    }
                end,
                clear=function ()
                    GG.att_CostMult[unitID] = nil
                    GG.att_HealthMult[unitID] = nil
                    
                end
            }
        end
    }
}