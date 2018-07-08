
function SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	if WG.COFC_SetCameraTarget then
		WG.COFC_SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	else
		if dist then
			Spring.SetCameraState({px = x, py = Spring.GetGroundHeight(x, z), pz = z, height = dist}, smoothness or 0)
		else
			Spring.SetCameraTarget(x, y, z, smoothness)
		end
	end
end

function SetCameraTargetBox(minX, minZ, maxX, maxZ, minDist, maxY, smoothness, useSmoothMeshSetting, height)
	if WG.COFC_SetCameraTargetBox then
		WG.COFC_SetCameraTargetBox(minX, minZ, maxX, maxZ, minDist, maxY, smoothness, useSmoothMeshSetting)
	else
		local x, z = (minX + maxX) / 2, (minZ + maxZ) / 2
		if height then
			Spring.SetCameraState({px = x, py = Spring.GetGroundHeight(x, z), pz = z, height = height}, smoothness or 0)
		else
			Spring.SetCameraTarget(x, Spring.GetGroundHeight(x, z), z, smoothness or 0)
		end
	end
end
