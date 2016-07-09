
function SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	if WG.COFC_SetCameraTarget then
		WG.COFC_SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	else
		Spring.SetCameraTarget(x, y, z, smoothness)
	end
end

function SetCameraTargetBox(minX, minZ, maxX, maxZ, minDist, maxY, smoothness, useSmoothMeshSetting)
	if WG.COFC_SetCameraTargetBox then
		WG.COFC_SetCameraTargetBox(minX, minZ, maxX, maxZ, minDist, maxY, smoothness, useSmoothMeshSetting)
	else
		local x, z = (minX + maxX) / 2, (minZ + maxZ) / 2
		Spring.SetCameraTarget(x, Spring.GetGroundHeight(x, z), z, smoothness or 0)
	end
end
