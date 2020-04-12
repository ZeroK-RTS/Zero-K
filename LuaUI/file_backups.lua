-- Utility function for ZK

-- Will try to read LUA content from target file and create BACKUP if have a successful read (in user's Spring folder) OR DELETE them if have a failure read
-- This prevent corrupted file from being used.
-- Note: currently only a "table" is considered a valid file

local function CheckLUAFileAndBackup(filePath)
	Spring.Log("CheckLUAFileAndBackup", LOG.INFO, "Creating backup for file", filePath)

	local backupPath = filePath .. ".bak"
	local chunk, err = loadfile(filePath)
	if chunk then
		setfenv(chunk, {})
		local tab = chunk()
		if tab and type(tab) == "table" then
			table.save(tab, backupPath)
			return
		end
	end
	Spring.Log("CheckLUAFileAndBackup", LOG.WARNING, tostring(err), "Trying to load backup instead", backupPath)

	local backupChunk, backupErr = loadfile(backupPath)
	if backupChunk then
		setfenv(backupChunk, {})
		local tab = backupChunk()
		if tab and type(tab) == "table" then
			table.save(tab, filePath)
			return
		end
	end
	Spring.Log("CheckLUAFileAndBackup", LOG.ERROR, tostring(backupErr), "Backup also failed, removing both")

	os.remove (filePath)
	os.remove (backupPath)
end

return CheckLUAFileAndBackup