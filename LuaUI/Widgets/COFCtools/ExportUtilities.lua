
function SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	if WG.COFC_SetCameraTarget then
		WG.COFC_SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting, dist)
	else
		Spring.SetCameraTarget(x, y, z, smoothness)
	end
end
