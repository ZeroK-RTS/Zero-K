--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo() 
	return {
		name      = "Mantis 5480",
		desc      = "Workaround https://springrts.com/mantis/view.php?id=5480 for features",
		author    = "GoogleFrog",
		date      = "15 February 2017",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge, -- Load before everything else
		enabled   = true,
	} 
end

function gadget:FeatureCreated(featureID)
	if Spring.SetFeatureSelectionVolumeData then
		local a,b,c,d,e,f,g,h,i,j = Spring.GetFeatureCollisionVolumeData(featureID)
		Spring.SetFeatureSelectionVolumeData(featureID, a,b,c,d,e,f,g,h,i,j)
	end
end

function gadget:GameFrame()
	for _, featureID in ipairs(Spring.GetAllFeatures()) do
		gadget:FeatureCreated(featureID)
	end
	gadgetHandler:RemoveCallIn('GameFrame')
end

function gadget:Initialize()
	for _, featureID in ipairs(Spring.GetAllFeatures()) do
		gadget:FeatureCreated(featureID)
	end
end
