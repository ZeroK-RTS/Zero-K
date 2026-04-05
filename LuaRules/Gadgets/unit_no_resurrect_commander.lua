function gadget:GetInfo()
  return {
    name      = "No Commander Resurrect",
    desc      = "Prevents resurrection of commander wrecks",
    author    = "Custom",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

if not gadgetHandler:IsSyncedCode() then
  return
end

function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
  if part > 0 then
    -- resurrection attempt: check what unit would be created
    local unitDefName = Spring.GetFeatureResurrect(featureID)
    if unitDefName and unitDefName ~= "" then
      local ud = UnitDefNames[unitDefName]
      if ud and ud.customParams then
        if ud.customParams.dynamic_comm or ud.customParams.commtype then
          return false
        end
      end
    end
  end
  return true
end
