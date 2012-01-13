local versionName = "v3.073"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Avatars",
    desc      = "An API for a per-user avatar-icon system, + Hello/Hi protocol",
    author    = "jK, +msafwan",
    date      = "2009, +2012 (9 Jan)",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    api       = false,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local avatars = {}

local msgID       	= "&AAA"	--an identifier that identify a packet with this widget
local hi 			= "1"	--to identify packet's purposes
local yes  			= "2"
local checksumA     = "3"
local checksumB		= "4"
local payloadA		= "5"
local payloadB		= "6"
local bye			= "7"
local broadcastID 	= "&AAB"	--an identifier for packet that work differently than all the above but still belong here
local operatingModeThis = "A"	--a switch to enable old Custom Avatar functionality ("A") and new fixed Avatar functionality ("B")
--Operating Mode A: Exchange custom Avatar (an avatar supplied by user)
--Computer A
--|............|Computer B
--|....Hi>.....|
--|----------->|
--|..<Hello....|
--|<-----------|
--|..ChecksumA>|
--|----------->|
--|.<ChecksumB.|
--|<-----------|
--|..PayloadA>.|
--|----------->|
--|.<PayloadB..|
--|<-----------|
--|...Bye>.....|
--|----------->|
--|............|
--Operating Mode B: Exchange server's avatars (avatars supplied by server and distributed by users)
--Computer A
--|.............|Computer B
--|....Hi>......|
--|------------>|
--|..<Hello.....|
--|<------------|
--|..FileListA>.|
--|------------>|
--|.<FileListB..|
--|<------------|
--|..FileA1>....|
--|------------>|
--|.<FileB1.....|
--|<------------|
--|..FileA2>....|
--|------------>|
--|.<FileB2.....|
--|<------------|
--|...Bye>......|
--|------------>|
--|.............|
--Rules:
--Many users online and 'shared medium', but only one communication allowed at a time.
--Detect 'collision' by detecting "Hello" message and the "Bye".
--Players with low ID number has more right to communicate. 
--Other users can 'snif' the communication and use the exchange data to complete own's request list.
--
local maxFileSize = 10 --in kB (for operating mode A)
local numberOfRetry = 7 --times to send "hi" until remote computer reply
local maxChecksumLenght= 2000  --if greater than 2049 will cause unpack error 
--reference: http://www.promixis.com/forums/showthread.php?15419-Lua-Limits-on-Table-Size

local networkDelayMultiplier = 1.15 --// add extra 15% delay for safety.

local configFile = "LuaUI/Configs/avatars.lua"
local avatarsDir = "LuaUI/Configs/Avatars/"
local avatar_fallback = avatarsDir .. "Crystal_personal.png"
local avatar_fallback_checksum = 13686070

local myPlayerID=-1
local myPlayerName =-1 
local myAllyTeamID=-1
local playerIDlistG={}
local bufferIndex=0
local msgRecv={}
local currentTime=0

local nextUpdate = 0
local delayUpdate = 0.1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CalcChecksum(data)
	local bytes = 0
	if data:len()/4 > maxChecksumLenght then 
		bytes = VFS.UnpackU32(data,nil,maxChecksumLenght) --calculate checksum up to the maxChecksumLenght
	else
		bytes = VFS.UnpackU32(data,nil,data:len()/4) --calculate checksum based on file size
	end
	local checksum = math.bit_xor(0,unpack(bytes))
	return checksum
end


local function SaveToFile(filename, data, checksum)
	local file="none"
	if(data:len()/1024 >= maxFileSize) then --//enable neat/original filename only for operational mode "A" where file size can be greater than 10Kb
		file = avatarsDir .. filename --original filename only (look neat and filename consistent with web based avatar, but risk overwrite similar named file)
	else --//add checksum to filename to prevent name duplication
		file = avatarsDir .. checksum .. '_' .. filename --filename + checksum as name (very safe but messy filename)
	end
	Spring.CreateDir(avatarsDir)
	local out = assert(io.open(file, "wb"))
	out:write(data)
	assert(out:close())
	Spring.Echo(file) --echo out saved file
	
	return file
end

local function SearchFileByChecksum(checksum)
	local files = VFS.DirList(avatarsDir)
	for i=1,#files do
		local file = files[i]
		local data = VFS.LoadFile(file)
		local file_checksum = CalcChecksum(data)
		if (file_checksum == checksum) then
			return file --return file, or if not found: return nil
		end
	end
end

local function ExtractFileName(filepath)
	filepath = filepath:gsub("\\", "/")
	local lastChar = filepath:sub(-1)
	if (lastChar == "/") then
		filepath = filepath:sub(1,-2)
	end
	local pos,b,e,match,init,n = 1,1,1,1,0,0
	repeat
		pos,init,n = b,init+1,n+1
		b,init,match = filepath:find("/",init,true)
	until (not b)
	if (n==1) then
		return filepath
	else
		return filepath:sub(pos+1)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetAvatar(playername) --//to be called by Chatbubble widget. Return player's avatar
	local avInfo = avatars[playername]
	return (avInfo and avInfo.file) --else return nil (chatbubble can handle the nil value)
end


local function SetAvatar(playerName, filename, checksum)
	avatars[playerName] = {
		checksum = checksum,
		file = filename,
	}
	table.save(avatars, configFile)
end


local function SetMyAvatar(filename)
--[[
	fixme!!!
	if (filename == nil) then
		avatars[myPlayerName] = nil
	end
--]]

	if (not VFS.FileExists(filename)) then
		error('Unexpected error: api_avatar.lua could not find that file')
		return
	end

	local data = VFS.LoadFile(filename)

	--if (data:len()/1024 > maxFileSize) then --theoretically filesize could go bigger than this, but unknown effect on checksum
		--error('Avatar: selected image file is too large (sizelimit is' .. maxFileSize .. 'kB)')
		--return
	--end

	local checksum = CalcChecksum(data)
	SetAvatar(myPlayerName,filename,checksum)
	Spring.SendLuaUIMsg(broadcastID) --send 'checkout my new pic!' to everyone
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetPlayersData(switch, playerID) --//group player's info as a function to facilitate debuggings. Values can be injected to test multi-player condition.
	if switch == 1 then --//used by self
		local _,_,_,_,_,_,_,_,_,customKeys = Spring.GetPlayerInfo(playerID)
		return customKeys
		--local customKeys ={avatar="picA"}
		--return customKeys
		-- Spring.Echo("---")
		-- Spring.Echo("Switch 1")
		-- Spring.Echo("playerID")
		-- Spring.Echo(playerID)
		-- Spring.Echo("customKeys")
		-- Spring.Echo(customKeys)
		-- Spring.Echo("---")
	elseif switch == 2 then --//used by all players
		local playerName = Spring.GetPlayerInfo(playerID)
		return playerName
		--local playerName = {"A", "B", "C", "D", "E"}
		--return playerName[playerID+1]
		-- Spring.Echo("---")
		-- Spring.Echo("Switch 2")
		-- Spring.Echo("playerID")
		-- Spring.Echo(playerID)
		-- Spring.Echo("playerName")
		-- Spring.Echo(playerName)
		-- Spring.Echo("---")
	elseif switch == 3 then --//used by self or other players
		local _,_,_,_,_,targetPingTime,_,_,_,_= Spring.GetPlayerInfo(playerID)
		return targetPingTime
		--local targetPingTime = 666
		--return targetPingTime
	elseif switch == 4 then --//used by all players
		local playerName, activePlayer ,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,playerCustomKeys = Spring.GetPlayerInfo(playerID)
		-- Spring.Echo("---")
		-- Spring.Echo("Switch 4")
		-- Spring.Echo("playerID")
		-- Spring.Echo(playerID)
		-- Spring.Echo("playerName")
		-- Spring.Echo(playerName)
		-- Spring.Echo("playerIsSpectator")
		-- Spring.Echo(playerIsSpectator)
		-- Spring.Echo("playerAllyTeamID")
		-- Spring.Echo(playerAllyTeamID)
		-- Spring.Echo("playerCustomKeys")
		-- Spring.Echo(playerCustomKeys)
		-- Spring.Echo("---")		
		return playerName, activePlayer, playerIsSpectator,playerAllyTeamID, playerCustomKeys
		--local playerName = {"A", "B", "C", "D", "E"}
		--local playerIsSpectator = {false,false,false,false,false}
		--local playerAllyTeamID = {1, 1, 1, 1, 1}
		--local playerCustomKeys = {"picA","picB","picC","picD","picE"}
		--return playerName[playerID+1], playerIsSpectator[playerID+1],playerAllyTeamID[playerID+1], playerCustomKeys[playerID+1]
	elseif switch == 5 then --//used by all players
		local _,playerIsActive,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
		-- Spring.Echo("---")
		-- Spring.Echo("Switch 5")
		-- Spring.Echo("playerID")
		-- Spring.Echo(playerID)
		-- Spring.Echo("playerIsActive")
		-- Spring.Echo(playerIsActive)
		-- Spring.Echo("playerIsSpectator")
		-- Spring.Echo(playerIsSpectator)
		-- Spring.Echo("playerAllyTeamID")
		-- Spring.Echo(playerAllyTeamID)
		-- Spring.Echo("---")
		return playerIsActive,playerIsSpectator,playerAllyTeamID
		--local playerIsActive = {true,true, true,true,true}
		--local playerIsSpectator = {false,false,false,false,false}
		--local playerAllyTeamID = {1, 1, 1, 1, 1}
		--return playerIsActive[playerID+1],playerIsSpectator[playerID+1],playerAllyTeamID[playerID+1]
	elseif switch == 6 then --//used by self
		local name,_,iAmSpectator,_,allyTeamID,_,_,_,_,customKeys = Spring.GetPlayerInfo(playerID)
		return name,iAmSpectator,allyTeamID,customKeys
		--local name = "A"
		--local iAmSpectator = false
		--local allyTeamID = 1
		--local customKeys = {avatar="picA"}
		--return name,iAmSpectator,allyTeamID,customKeys
	elseif switch == 7 then --//used by self
		local myPlayerID_local=Spring.GetMyPlayerID()
		return myPlayerID_local
		--local myPlayerID_local = 1
		--return myPlayerID_local
	elseif switch == 8 then --//used by all players
		local playerIDlist_local=Spring.GetPlayerList()
		-- Spring.Echo("---")
		-- Spring.Echo("Switch 8")
		-- Spring.Echo("playerID")
		-- Spring.Echo(playerID)
		-- Spring.Echo("playerIDlist_local")
		-- Spring.Echo(playerIDlist_local)
		-- Spring.Echo("---")
		return playerIDlist_local
		--local playerIDlist_local = {0,1,2,3,4}
		--return playerIDlist_local
	elseif switch == 9 then --//used by all players (operation mode "B")
		local _,_,_,_,_,_,_,_,_,customKeys = Spring.GetPlayerInfo(playerID)
		return customKeys	
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local chili_window = false

local function SetAvatarGUI()
	if (chili_window) then
		return
	end

	local Chili = WG.Chili
	if (not Chili) then
		Spring.Echo('Chili not running.')
		return
	end

	chili_window = Chili.Window:New{
		parent    = Chili.Screen0;
		x         = "30%";
		y         = "30%";
		width     = "40%";
		height    = "50%";
	}
	
	local captionA = "Feature N/A"
	if operatingModeThis == "A" then 
		captionA = "Select your Avatar"
	end
	
	Chili.Label:New{
		parent     = chili_window;
		x          = 10;
		caption    = captionA;
		valign     = "ascender";
		align      = "left";
		fontshadow = true;
		fontsize   = 20;
	}

	Chili.Label:New{
		parent     = chili_window;
		x          = -100;
		y          = 20;
		width      = 100;
		caption    = "Current Avatar";
		valign     = "ascender";
		align      = "center";
		autosize   = false;
		fontshadow = true;
		fontsize   = 12;
	}

	local imagepanel = Chili.Panel:New{
		parent = chili_window;
		x      = -95;
		y      = 30;
		width  = 90;
		height = 90;
	}

	local grid = Chili.Grid:New{
		parent = imagepanel;
		width  = "100%";
		height = "100%";
	}

	local image = Chili.Image:New{
		parent = grid;
		file   = GetAvatar(myPlayerName);
		--file2  = "LuaUI/Images/Copy of waterbump.png";
		x      = 0;
		y      = 0;
		width  = 64;
		height = 64;
	}

	local b = Chili.Button:New{
		parent     = chili_window;
		x          = -100;
		y          = imagepanel.y + imagepanel.height + 2;
		width      = 100;
		caption    = "Select";
		OnClick    = {
			function()
				SetMyAvatar(image.file)
				chili_window:Dispose()
				chili_window = nil
			end
		}
	}

	local c = Chili.Button:New{
		parent     = chili_window;
		x          = -100;
		y          = b.y + b.height + 5;
		width      = 100;
		caption    = "Abort";
		OnClick    = {
			function()
				chili_window:Dispose()
				chili_window = nil
			end
		}
	}

	Chili.Button:New{
		parent     = chili_window;
		x          = -100;
		y          = c.y + c.height + 5;
		width      = 100;
		caption    = "Default";
		OnClick    = {
			function()
				local customKeys = GetPlayersData(1, myPlayerID)
				local myAvatar={}
				myAvatar=InitializeDefaultAvatar(myAvatar, customKeys)
				image.file = myAvatar.file
				image:Invalidate()
			end
		}
	}	

	local sizeA = "0%"
	if operatingModeThis == "A" then 
		sizeA = "100%"
	end
	
	local control = Chili.ScrollPanel:New{
		parent = chili_window;
		x      = 0;
		y      = 20;
		width  = -100;
		height = -20;
		children = {	
			Chili.ImageListView:New{
				name   = "AvatarSelectImageListView",
				width  = sizeA,
				height = sizeA,
				dir    = avatarsDir,
				OnDblClickItem = {
					function(obj,file,itemIdx)
						local data = VFS.LoadFile(file)
						if (data:len()/1024 > maxFileSize) then
							Spring.Echo('Avatar: selected image file is too large (sizelimit is' .. maxFileSize .. 'kB)')
							return;
						end
						image.file = file
						image:Invalidate()
					end,
				},
			}
		}
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function ConvertFileRequestIntoString (playerIDlist, checklistTable)
	local playerID=-1
	local fileRequestCode=1
	local fileRequestIndex=100
	for iteration=1, iteration <= #playerIDlist do
		playerID=playerIDlist[iteration]
		if not checklistTable[(playerID+1)].ignore then --check self and others but don't check the ignore list
			if (checklistTable[(playerID+1)].downloaded==false) then --check checklist if complete
				fileRequestCode=fileRequestCode*100+playerID
				fileRequestIndex=fileRequestIndex+1
			end
		end
		iteration=iteration+1 --check next entry
	end
	fileRequestCode=fileRequestIndex .. fileRequestCode --eg: "1031000102", means "3 player"= "00","01","02"
	return fileRequestCode
end

local function ConvertStringIntoFileRequest (fileRequestCode)
	local fileRequestTable={}
	local requestCount = tonumber(fileRequestCode:sub(2,3))
	fileRequestCode = fileRequestCode:sub(5,4+requestCount*2) --eg: (5,6) or (5,8) or (5,10) or (5,12) or (5,14)
	local index = 1
	for i=1, i <= requestCount do
		local id = tonumber(fileRequestCode:sub(i*2-1,i*2))
		local playerCustomKeys = GetPlayersData(9, id) --filter out request that has no server data
		if (playerCustomKeys ~= nil and playerCustomKeys.avatar~=nil) then 
			fileRequestTable[index]={
				id, --eg:(1,2),(3,4),(5,6),(7,8),(9,10)
				playerCustomKeys.avatar .. ".png"
			}
			index=index+1
		end
	end
	return fileRequestTable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--communication protocol variables
local waitTransmissionUntilThisTime =currentTime
local waitBusyUntilThisTime=currentTime
local checklistTableG={}
local waitForTransmission=false
local lineIsBusy=false
local openPortForID=-1 --used for filtering message
local tableIsCompleted=false
local fileRequestTableG={}
function widget:Update(n)
	currentTime=currentTime+n
	
	local now = currentTime
	if (now > nextUpdate) then
		nextUpdate = now + delayUpdate
	else
		return
	end
	
	if now>=waitTransmissionUntilThisTime then
		waitForTransmission=false
	end
	if now>=waitBusyUntilThisTime then
		lineIsBusy=false
	end
	if not waitForTransmission and not tableIsCompleted then
		local iteration=1
		local playerID=-1
		local doChecking=true
		while doChecking and iteration <= #playerIDlistG do
			playerID=playerIDlistG[iteration]
			if playerID~=myPlayerID and not checklistTableG[(playerID+1)].ignore then --don't check self and don't check ignore list
				if (checklistTableG[(playerID+1)].downloaded==false) then --check checklist if complete
					if checklistTableG[(playerID+1)].retry < numberOfRetry then
						doChecking=false
						checklistTableG[(playerID+1)].retry=checklistTableG[(playerID+1)].retry+1 -- ++ retry count
					end
				end
			end
			iteration=iteration+1 --check next entry
		end
		if doChecking then --if last check performed without interruption meaning all entry are complete
			tableIsCompleted=true
			if operatingModeThis == "B" then
				if checklistTableG[(myPlayerID+1)].downloaded == false then
					Spring.SendLuaUIMsg(broadcastID) --send 'I still don't have my pic!' to everyone
				end
			end
		else
			openPortForID=playerID
			waitForTransmission=true
			local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
			waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
			Spring.SendLuaUIMsg(msgID .. operatingModeThis .. hi .. openPortForID+100) --send 'hi' to colleague
		end
	end

	if bufferIndex>=1 then --check lua message from 'inbox'
		local found, playerID, msg=false ,nil, nil
		while bufferIndex >= 1 and not found do
			playerID=msgRecv[bufferIndex].playerID
			msg=msgRecv[bufferIndex].msg
			if (msg:sub(1,4) == msgID or msg:sub(1,4) == broadcastID) then
				found = true
			end
			msgRecv[bufferIndex]=nil
			bufferIndex=bufferIndex-1
		end
		if msg==nil then return end
		
		if (msg:sub(1,4) == msgID) then --if message belong to hello/hi file transfer protocol
			destinationID=tonumber(msg:sub(8,9))
			local myAvatar = avatars[myPlayerName]
			
			if openPortForID==playerID and destinationID==myPlayerID and not lineIsBusy then
				if msg:sub(6,6)==hi then --receive hi from target playerID
					if myPlayerID>playerID then --if I am 'low ranking' playerID then replied yes
						--reply with yes
						local operationMode = msg:sub(5,5) --propagate operation mode to the subsequent protocol
						Spring.SendLuaUIMsg(msgID .. operationMode .. yes .. openPortForID+100)
						waitForTransmission=true
						local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
					end
				elseif msg:sub(6,6)==yes then --received yes
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
					----
						Spring.SendLuaUIMsg(msgID .. operationMode .. checksumA .. openPortForID+100 .. "x" .. myAvatar.checksum) --send checksum, "x" is payload request flag (not available)
					----
					else --if mode B
					----
						local myRequestList = ConvertFileRequestIntoString (playerIDlistG, checklistTableG)
						Spring.SendLuaUIMsg(msgID .. operationMode .. checksumA .. openPortForID+100 .. "x" .. myRequestList)
					----
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
				elseif msg:sub(6,6)==checksumA then --receive checksum
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
					----
						local checksum = tonumber(msg:sub(11))					
						local playerName = GetPlayersData(2, playerID)
						local avatarInfo = avatars[playerName]
						local payloadRequestFlag=0
						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
							local file = SearchFileByChecksum(checksum)
							if (file) then
								--// already downloaded it once, reuse it
								SetAvatar(playerName,file,checksum)
								checklistTableG[(playerID+1)].downloaded=true --tick 'done' on file downloaded
							else
								payloadRequestFlag=1
							end
						end
						Spring.SendLuaUIMsg(msgID .. operationMode .. checksumB .. openPortForID+100 .. payloadRequestFlag .. myAvatar.checksum) --send checksum
					else --if mode B
					----
						local remoteRequestString = tonumber(msg:sub(11))
						fileRequestTableG = ConvertStringIntoFileRequest (remoteRequestString) --decode remote computer's file request
						local willSendFile = 0 --to flag remote computer to wait for file sending
						local iteration=1
						while (willSendFile == 0 and iteration <= #fileRequestTableG) do --check if we have any file to send
							local filepath = avatarsDir .. fileRequestTableG[iteration][2]
							if VFS.FileExists(filepath) then
								willSendFile = 1
							end
							iteration=iteration+1
						end
						local myRequestList = ConvertFileRequestIntoString (playerIDlistG, checklistTableG) --compose our file request
						Spring.SendLuaUIMsg(msgID .. operationMode .. checksumB .. openPortForID+100 .. willSendFile .. myRequestList)
					----
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
				elseif msg:sub(6,6)==checksumB then --receive checksum
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
					----
						local checksum = tonumber(msg:sub(11))
						local playerName = GetPlayersData(2, playerID)
						local avatarInfo = avatars[playerName]
						local payloadRequestFlag=0
						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
							local file = SearchFileByChecksum(checksum)
							if (file) then
								--// already downloaded it once, reuse it
								SetAvatar(playerName,file,checksum)
								checklistTableG[(playerID+1)].downloaded=true --tick 'done' on file downloaded
							else
								payloadRequestFlag=1
							end
						end
						if (msg:sub(10,10)=="1") then --if remote computer has payload request
							local cdata = VFS.LoadFile(myAvatar.file)
							local filename = ExtractFileName(myAvatar.file)
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. payloadRequestFlag .. "1" .. filename .. '$' .. cdata) --send payload, "1" is payload flag
						else
							if payloadRequestFlag==1 then --if we have a request
								Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. payloadRequestFlag .. "0") --send "payload package" without payload
							else 	
								Spring.SendLuaUIMsg(msgID .. operationMode .. bye .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
							end
						end
					----
					else --if mode B
					----
						local remoteRequestString = tonumber(msg:sub(11))
						fileRequestTableG = ConvertStringIntoFileRequest (remoteRequestString) --decode remote computer's file request
						local willSendFile = 0 --to flag remote computer to wait for file sending
						
						local fileToSend = "empty"
						local filename = "empty"
						local ownerID = -1
						
						local iteration = 1
						while (willSendFile == 0 and iteration <= #fileRequestTableG) do --check if we have any file to send
							filename = fileRequestTableG[iteration][2]
							local filepath = avatarsDir .. filename
							if VFS.FileExists(filepath) then
								willSendFile = 1
								fileToSend = filepath --use this file for sending
								ownerID = fileRequestTableG[iteration][1] --identify the file users too
								local newTable = {}
								iteration=iteration+1
								while (iteration <= #fileRequestTableG) do --copy request table into new table, skipping earlier entry if exist
									newTable = { fileRequestTableG[iteration][1] ,fileRequestTableG[iteration][2] }
									iteration=iteration+1
								end
								fileRequestTableG=newTable  --replace old table with new table which has skipped/removed some entry
							end
							iteration=iteration+1
						end

						if (willSendFile == 1) then --if we have file to send
							local cdata = VFS.LoadFile(fileToSend)
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. "x" .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
						else
							if (msg:sub(10,10) == "1") then  --if remote computer has any file to send
								Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
							else --if NOT us and NOT remote computer has any file to send
								Spring.SendLuaUIMsg(msgID .. operationMode .. bye .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
							end
						end
					----
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
				elseif msg:sub(6,6)==payloadA then
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							msg = msg:sub(12)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)
							
							local image      = cdata
							local checksum   = CalcChecksum(image)
							checklistTableG[(playerID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, playerID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
							end
						end
						if (msg:sub(10,10)=="1") then --remote client's payloadRequestFlag
							local cdata = VFS.LoadFile(myAvatar.file)
							local filename = ExtractFileName(myAvatar.file)
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadB .. openPortForID+100 .. "x" .. "1" .. filename .. '$' .. cdata) --send payload,"x" is payload request flag(unavailable), "1" is payload flag
						else
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadB .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
						end
					----
					else --if mode B
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local userID = msg:sub(13,14)
							msg = msg:sub(15)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)
							
							local image      = cdata
							local checksum   = CalcChecksum(image)
							checklistTableG[(userID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, playerID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
							end
						end

						local willSendFile = 0 --to flag remote computer to wait for file sending						
						local fileToSend = "empty"
						local filename = "empty"
						local ownerID = -1
						
						local iteration = 1
						while (willSendFile == 0 and iteration <= #fileRequestTableG) do --check if we have any file to send
							filename = fileRequestTableG[iteration][2]
							local filepath = avatarsDir .. filename
							if VFS.FileExists(filepath) then
								willSendFile = 1
								fileToSend = filepath --use this file for sending
								ownerID = fileRequestTableG[iteration][1] --identify the file users too
								local newTable = {}
								iteration=iteration+1
								while (iteration <= #fileRequestTableG) do --copy request table into new table, skipping earlier entry if exist
									newTable = { fileRequestTableG[iteration][1] ,fileRequestTableG[iteration][2] }
									iteration=iteration+1
								end
								fileRequestTableG=newTable  --replace old table with new table which has skipped/removed some entry
							end
							iteration=iteration+1
						end

						if (willSendFile == 1) then --if we have file to send
							local cdata = VFS.LoadFile(fileToSend)
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadB .. openPortForID+100 .. willSendFile .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
						else
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadB .. openPortForID+100 .. willSendFile .. "0") --send "payload package" without payload
						end
					----
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg				
				elseif (msg:sub(6,6)==payloadB) then
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							msg = msg:sub(12)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)					

							local image      = cdata
							local checksum   = CalcChecksum(image)
							checklistTableG[(playerID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, playerID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
							end
						end
						Spring.SendLuaUIMsg(msgID .. operationMode .. bye .. openPortForID+100)
						waitForTransmission=false
					----
					else --if mode B
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local userID = msg:sub(13,14)
							msg = msg:sub(15)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)
							
							local image      = cdata
							local checksum   = CalcChecksum(image)
							checklistTableG[(userID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, userID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
							end
						end

						local willSendFile = 0 --to flag remote computer to wait for file sending						
						local fileToSend = "empty"
						local filename = "empty"
						local ownerID = -1
						
						local iteration = 1
						while (willSendFile == 0 and iteration <= #fileRequestTableG) do --check if we have any file to send
							filename = fileRequestTableG[iteration][2]
							local filepath = avatarsDir .. filename
							if VFS.FileExists(filepath) then
								willSendFile = 1
								fileToSend = filepath --use this file for sending
								ownerID = fileRequestTableG[iteration][1] --identify the file users too
								local newTable = {}
								iteration=iteration+1
								while (iteration <= #fileRequestTableG) do --copy request table into new table, skipping earlier entry if exist
									newTable = { fileRequestTableG[iteration][1] ,fileRequestTableG[iteration][2] }
									iteration=iteration+1
								end
								fileRequestTableG=newTable  --replace old table with new table which has skipped/removed some entry
							end
							iteration=iteration+1
						end
						
						if (willSendFile == 1) then --if we have file to send
							local cdata = VFS.LoadFile(fileToSend)
							Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. "x" .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
						else
							if (msg:sub(10,10) == "1") then  --if remote computer has any file to send
								Spring.SendLuaUIMsg(msgID .. operationMode .. payloadA .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
							else --if NOT us and NOT remote computer has any file to send
								Spring.SendLuaUIMsg(msgID .. operationMode .. bye .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
							end
						end
						local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg
					----
					end
				elseif (msg:sub(6,6)==bye) then
					waitForTransmission=false
				end
			elseif myPlayerID==destinationID then
				if msg:sub(6,6)==hi then --receive hi from someone who target you
					if myPlayerID>playerID or tableIsCompleted then --if I am the'low ranking' playerID then reply yes, else don't (high rank will not answer to low ranking unless has no work to do)
						--reply with yes
						local operationMode = msg:sub(5,5) --propagate operation mode to the subsequent protocol
						openPortForID=playerID
						waitForTransmission=true --turn of "hi" sending
						local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --suspend "hi" sending until next reply msg				
						Spring.SendLuaUIMsg(msgID .. operationMode .. yes .. openPortForID+100)
					end 
				end
			elseif myPlayerID~=destinationID then --if noise (if not my message)
				if msg:sub(6,6)==yes then --listen hi from someone to someone else
					if myPlayerID>playerID then --if they are the 'higher ranking' playerID (close your own connection for high ranking player (players with low playerID))
						lineIsBusy=true --assume they took command of the communication medium, close all protocol/cancel ongoing protocol. lineBusy always triggered by high ranking noise
						waitForTransmission=true
						local operationMode = msg:sub(5,5)
						if operationMode == "A" then
							local totalNetworkDelay= retrieveTotalNetworkDelay(destinationID, playerID) --delay between 2 computer
							waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*(networkDelayMultiplier+networkDelayMultiplier+0.5)
							waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*(networkDelayMultiplier+networkDelayMultiplier+0.5) --assume twice the delay for complete back and forth. Wait until end.
						else --if mode B
							local totalNetworkDelay= retrieveTotalNetworkDelay(destinationID, myPlayerID) --delay between us (listener) and the replier
							waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier
							waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --wait until it end
						end
					end 
				elseif (msg:sub(6,6)==payloadB or msg:sub(6,6)==payloadA) then --snif package transfer and save for our own
					if (msg:sub(11,11)=="1") then --payload "is here!" flag
						local operationMode = msg:sub(5,5)
						if operationMode == "A" then
							msg = msg:sub(12)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)

							local image      = cdata
							local checksum   = CalcChecksum(image)
							local playerName = GetPlayersData(2, playerID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
								checklistTableG[(playerID+1)].downloaded=true --mark checklist as complete
							end
						else --if mode B
							local userID = msg:sub(13,14)
							msg = msg:sub(15)
							local endOfFilename = msg:find('$',1,true)
							local filename = msg:sub(1,endOfFilename-1)
							local cdata    = msg:sub(endOfFilename+1)

							local image      = cdata
							local checksum   = CalcChecksum(image)
							local playerName = GetPlayersData(2, userID)
							local avatarInfo = avatars[playerName]

							if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
								local filename = SaveToFile(filename, image, checksum)
								SetAvatar(playerName,filename,checksum)
								checklistTableG[(userID+1)].downloaded=true --mark checklist as complete
							end
							local totalNetworkDelay= retrieveTotalNetworkDelay(destinationID, myPlayerID) --delay between us (listener) and the replier
							waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier
							waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --wait until it end
						end
					end
				elseif msg:sub(6,6)==checksumA or msg:sub(6,6)==checksumB then --snif checksum transfer and save it for our own
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
						local checksum = tonumber(msg:sub(11))
						local playerName = GetPlayersData(2, playerID)
						local avatarInfo = avatars[playerName]
						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then --check if we have record of this player
							local file = SearchFileByChecksum(checksum)
							if (file) then
								--// already downloaded it once, reuse it
								SetAvatar(playerName,file,checksum)
								checklistTableG[(playerID+1)].downloaded=true
							else
								checklistTableG[(playerID+1)].retry=0 --if we have no file yet, but heard this broadcast then reset retry count to continue trying to reach this playerID
								tableIsCompleted=false --recheck checklist
							end
						end
					else
						local totalNetworkDelay= retrieveTotalNetworkDelay(destinationID, myPlayerID) --delay between us (listener) and the replier
						waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --wait until it end
					end
				elseif (msg:sub(6,6)==bye) then
					lineIsBusy=false
					waitForTransmission=false
				end
			end
		elseif (msg:sub(1,4) == broadcastID) then --if message is a 'look at my new pic!'.
			checklistTableG[(playerID+1)].downloaded=false --reset checklist entry for this player
			checklistTableG[(playerID+1)].retry=0 --reset retry
			tableIsCompleted=false --redo checklist check
		end
	end
end

function retrieveTotalNetworkDelay(playerIDa, playerIDb)
	local aTargetPingTime = GetPlayersData(3, playerIDa)
	local bTargetPingTime = GetPlayersData(3, playerIDb)
	local totalDelay= aTargetPingTime+bTargetPingTime
	if totalDelay == 0 then return (2 + delayUpdate)
	elseif totalDelay<0.5 then return (0.5 + delayUpdate) --if too low delay don't spam message out too quickly
	elseif totalDelay>=2 then return (2 + delayUpdate) --if too high delay then don't wait too long, just send until the retry depleted (end connection)
	else return totalDelay
	end
end

function widget:RecvLuaMsg(msg, playerID) --each update will put message into "msgRecv"
	if msg:sub(1,1)~="%" then
		bufferIndex=bufferIndex+1
		msgRecv[bufferIndex]={msg=msg, playerID=playerID}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:PlayerChanged(playerID) --in case where player status changed (eg: joined, spec)
	UpdatePlayerList()
end

function widget:PlayerAdded(playerID) --in case where player status changed (eg: joined, spec)
	UpdatePlayerList()
end

function widget:PlayerRemoved(playerID)
	UpdatePlayerList()
end

function UpdatePlayerList()
	--get info on self
	local iAmSpectator=false
	if Spring.GetSpectatingState() then 
		iAmSpectator=true
	end

	--get all playerID list
	playerIDlistG= GetPlayersData(8, nil)
	--Spring.Echo(playerIDlistG)	
	
	--use playerIDlistG to update checklist
	local iteration =1
	local playerID=-1
	while iteration <= #playerIDlistG do --update checklist with appropriate value
		playerID=playerIDlistG[iteration]
		if checklistTableG[(playerID+1)]==nil then 
			checklistTableG[(playerID+1)]={downloaded=false, retry=0, ignore=false} --add empty entry with new value
		else 
			checklistTableG[(playerID+1)].ignore=false --reset previous ignore list
			checklistTableG[(playerID+1)].retry=0 --reset retry counter
		end
		
		if operatingModeThis == "B" then
			local playerName,playerIsSpectator,playerAllyTeamID, playerCustomKeys = GetPlayersData(4, playerID)
			if (playerCustomKeys ~= nil and playerCustomKeys.avatar~=nil) then 
				local customKeyAvatarFile = avatarsDir .. playerCustomKeys.avatar .. ".png" --check if we have that file on disk
				if (VFS.FileExists(playerCustomKeyAvatarFile)) then
					local checksum = CalcChecksum(VFS.LoadFile(playerCustomKeyAvatarFile))
					SetAvatar(playerName, customKeyAvatarFile , checksum)
					checklistTableG[(playerID+1)].downloaded=true
				end
			end
		end
		
		--the following add ignore flag to selective playerID
		local playerIsActive,playerIsSpectator,playerAllyTeamID = GetPlayersData(5, playerID)
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator or not playerIsActive then --ignore non-specs and inactive player(don't send hi/request file)
				checklistTableG[(playerID+1)].ignore=true 
			end
		else --if I am not spectator
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator or not playerIsActive then --if player is the enemy or a spec then
				checklistTableG[(playerID+1)].ignore=true --ignore enemy & spec and inactive player(don't send hi/request file)
			end
		end
		iteration=iteration+1
	end
	tableIsCompleted=false --unlock checklist for another check
end

function InitializeDefaultAvatar(myAvatar, customKeys)
	--initialize own avatar using fallback
	myAvatar={
			checksum = avatar_fallback_checksum,
			file = avatar_fallback
		}  
	--initialize own avatar using server assigned avatar
	if (customKeys ~= nil and customKeys.avatar~=nil) then 
		local customKeyAvatarDir = avatarsDir .. customKeys.avatar .. ".png" --check if we have that file on disk
		if (VFS.FileExists(customKeyAvatarDir)) then
			myAvatar.file = avatarsDir .. customKeys.avatar .. ".png"
			myAvatar.checksum = CalcChecksum(VFS.LoadFile(myAvatar.file))
		--if we don't have the file then fallback avatar remains
		end
	end
	return myAvatar
end

function widget:Initialize()
	--get info on self
	myPlayerID = GetPlayersData(7, nil)
	local name,iAmSpectator,allyTeamID,customKeys = GetPlayersData(6, myPlayerID)
	myPlayerName =name
	myAllyTeamID=allyTeamID
	
	--get all playerID list
	playerIDlistG= GetPlayersData(8, nil)
	--Spring.Echo(playerIDlistG)
	avatars = (VFS.FileExists(configFile) and VFS.Include(configFile)) or {}

	--use player list to build checklist
	local iteration =1
	local playerID=-1
	while iteration <= #playerIDlistG do --fill checklist with initial value
		playerID=playerIDlistG[iteration]
		checklistTableG[(playerID+1)]={downloaded=false, retry=0, ignore=false} --fill checklist with default values (promote communication)
		
		local playerName, activePlayer , playerIsSpectator,playerAllyTeamID, playerCustomKeys = GetPlayersData(4, playerID)
		if operatingModeThis == "B" then
			if (playerCustomKeys ~= nil and playerCustomKeys.avatar~=nil) then 
				local customKeyAvatarFile = avatarsDir .. playerCustomKeys.avatar .. ".png" --check if we have that file on disk
				if (VFS.FileExists(playerCustomKeyAvatarFile)) then
					local checksum = CalcChecksum(VFS.LoadFile(playerCustomKeyAvatarFile))
					SetAvatar(playerName, customKeyAvatarFile , checksum)
					checklistTableG[(playerID+1)].downloaded=true
				end
			end
		end
		
		--the following add ignore flag to selective playerID
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator or not activePlayer then --ignore non-specs and non-ingame(don't send hi/request file)
				checklistTableG[(playerID+1)].ignore=true 
			end
		else --if I am not spectator
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator or not activePlayer then --if player is enemy or spec or not ingame then
				checklistTableG[(playerID+1)].ignore=true --ignore enemy & spec (don't send hi/request file)
			end
		end
		iteration=iteration+1
	end
	
	--// remove broken entries
	for playerName,avInfo in pairs(avatars) do
		if (not VFS.FileExists(avInfo.file)) then
			avatars[playerName] = nil
		end
	end
	
	local myAvatar={}
	myAvatar= InitializeDefaultAvatar(myAvatar, customKeys)
	
	if operatingModeThis == "A" then
		if (avatars[myPlayerName]~=nil) then --initialize custom avatar if available
			if VFS.FileExists(avatars[myPlayerName].file) then --if selected file exist then use it
				myAvatar.file=avatars[myPlayerName].file
				myAvatar.checksum=avatars[myPlayerName].checksum
			end --if we don't have the selective avatar then fallback remains
		end 
	end
	SetAvatar(myPlayerName, myAvatar.file, myAvatar.checksum) --save value into table and broadcast 'checkout my new avatar' message
	
	WG.Avatar = {
		GetAvatar   = GetAvatar;
		SetMyAvatar = SetMyAvatar;
	}

	widgetHandler:AddAction("setavatar", SetAvatarGUI, nil, "t");
end

function widget:Shutdown()
	--table.save(avatars, configFile) <--will not save when exiting because if the widget exit too early it will save incomplete table

	WG.Avatar = nil
	widgetHandler:RemoveAction("setavatar");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--Reference:
--http://en.wikipedia.org/wiki/Carrier_sense_multiple_access
--gui_ally_cursors.lua , author: jK
--gui_chili_crudeplayerlist.lua, author: CarRepairer, +KingRaptor
--cawidgets.lua, author: Dave Rodgers, +jk, quantum, KingRaptor
