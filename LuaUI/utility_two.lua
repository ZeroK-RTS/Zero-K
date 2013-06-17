-- Utility function for ZK

--Workaround for Spring.SetCameraTarget() not working in Freestyle mode.
local SetCameraTarget = Spring.SetCameraTarget
function Spring.SetCameraTarget(x,y,z,transTime) 
	local cs = Spring.GetCameraState()
	if cs.mode==4 then --if using Freestyle cam, especially when using "camera_cofc.lua"
		--"0.46364757418633" is the default pitch given to FreeStyle camera (the angle between Target->Camera->Ground, tested ingame) and is the only pitch that original "Spring.SetCameraTarget()" is based upon.
		--"cs.py-y" is the camera height.	
		--"math.pi/2 + cs.rx" is the current pitch for Freestyle camera (the angle between Target->Camera->Ground). Freestyle camera can change its pitch by rotating in rx-axis.
		--The original equation is: "x/y = math.tan(rad)" which is solved for "x"
		local ori_zDist = math.tan(0.46364757418633)*(cs.py-y) --the ground distance (at z-axis) between default FreeStyle camera and the target. We know this is only for z-axis from our test.
		local xzDist = math.tan(math.pi/2 + cs.rx)*(cs.py-y) --the ground distance (at xz-plane) between FreeStyle camera and the target.
		local xDist = math.sin(cs.ry)*xzDist ----break down "xzDist" into x and z component.
		local zDist = math.cos(cs.ry)*xzDist
		x = x-xDist --add current FreeStyle camera to x-component 
		z = z-ori_zDist-zDist --remove default FreeStyle z-component, then add current Freestyle camera to z-component
	end
	return SetCameraTarget(x,y,z,transTime) --return new results
end

-- Will try to read LUA content from target file and create BACKUP if have a successful read (in user's Spring folder) OR DELETE them if have a failure read
-- This prevent corrupted file from being used.
function CheckLUAFileAndBackup(filePath, headerString)
	local chunk, err = loadfile(filePath)
	if (chunk) then --if original content is LUA OK:
		local tmp = {}
		setfenv(chunk, tmp)
		local tab = chunk()
		if tab and type(tab) == "table" then
		    table.save(chunk(),filePath..".bak",headerString) --write to backup
		end
	else --if original content is not LUA OK:
		Spring.Log("CheckLUAFileAndBackup","warning", tostring(err) .. " (Now will find backup file)")
		chunk, err = loadfile(filePath..".bak")
		if (chunk) then --if backup content is LUA OK:
			local tmp = {}
			setfenv(chunk, tmp)
			local tab = chunk()
			if tab and type(tab) == "table" then
			    table.save(chunk(),filePath,headerString) --overwrite original
			end
		else --if backup content is also not LUA OK:
			Spring.Log("CheckLUAFileAndBackup","warning", tostring(err) .. " (Backup file not available)")
			Spring.Echo(os.remove (filePath)) --delete original
			Spring.Echo(os.remove (filePath..".bak")) --delete backup
		end
	end
end