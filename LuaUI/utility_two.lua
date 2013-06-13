-- Utility function for ZK

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