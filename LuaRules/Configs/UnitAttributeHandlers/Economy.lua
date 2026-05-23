local INLOS_ACCESS = {inlos = true}
local spSetUnitRulesParam=Spring.SetUnitRulesParam

GG.att_EconomyChange={}
return {
    ---@type AttributesHandlerFactory
    Economy = {
        handledAttributeNames={econ=true,energy=true},
        new = function(unitID, unitDefID)
            local econMultCur = 1
            local energyMultCur = 1

            return {
                newDataHandler = function(frame)
                    local econMult = 1
                    local energyMult = 1

                    return {
                        fold = function(data)
                            econMult = econMult * (data.econ or 1)
                            energyMult = energyMult * (data.energy or 1)
                        end,
                        apply = function()
                            GG.att_EconomyChange[unitID] = econMult
                            if econMult ~= econMultCur or energyMult ~= energyMultCur then
	                            spSetUnitRulesParam(unitID, "totalEconomyChange", econMult, INLOS_ACCESS)
                                spSetUnitRulesParam(unitID, "metalGenerationFactor", econMult, INLOS_ACCESS)
                                spSetUnitRulesParam(unitID, "energyGenerationFactor", econMult * energyMult, INLOS_ACCESS)

                                econMultCur = econMult
                                energyMultCur = energyMult
                            end
                        end
                    }
                end,
                clear = function()
                    GG.att_EconomyChange[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}