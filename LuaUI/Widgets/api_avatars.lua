local versionName = "v3.27"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Avatars",
    desc      = versionName .. " An API for a per-user avatar-icon system, + Hello/Hi protocol",
    author    = "jK, +msafwan",
    date      = "2009, +2012 (2 April)",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    api       = true,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--Global Variables--------------------------------------------------------------

local enableEcho_debug = false
local resetDownloadedRetryFlag_debug = false

local avatarsTable_g = {}
local wdgtID 		= "&" --// 'selectionsend.lua' used "=", 'allyCursor.lua' used "%", 'unitMarker.lua' used "dFl", 'lagmonitor.lua' used "AFK", so api_avatar.lua use "&".
local msgID       	= wdgtID .. "AAA"	--an identifier that identify a packet with this widget
local hi 			= "1"	--to identify packet's purposes
local yes  			= "2"
local checksumA     = "3"
local checksumB		= "4"
local payloadA		= "5"
local payloadB		= "6"
local bye			= "7"
local broadcastID 	= wdgtID .. "AAB"	--an identifier for packet that work differently than all the above but still belong here
local operatingModeThis_g = "A"	--a switch to enable one-on-one Custom Avatar functionality: "A", and sync-ing Avatars functionality:"B" *may have bugs*
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
--Players with low ID number has more right to communicate (to simulate Token). 
--Other users can 'snif' other user's communication and use the exchange data to complete own's request list.
--
local maxFileSize = 10 --in kB (for operating mode A)
local numberOfRetry_g = 3 --times to send "hi" before remote computer reply until they are listed in "ignore" for the duration of "refresh delay"
local maxChecksumLenght= 2000  --if greater than 2049 will cause unpack error 
--reference: http://www.promixis.com/forums/showthread.php?15419-Lua-Limits-on-Table-Size

local networkDelayMultiplier = 1.15 --// constant: 1 trip (A to B) delay + extra 15% delay for safety.

local configFile = "LuaUI/Configs/avatars.lua" --//default database
local avatarsDir = "LuaUI/Configs/Avatars/" --//default directory
local avatar_fallback = avatarsDir .. "Crystal_personal.png" --//default avatar
local avatar_fallback_checksum = 13686070 --//checksum of "Crystal_personal.png". Shortcut

local myPlayerID=-1
local myPlayerName_g =-1 
local myAllyTeamID_g=-1
local playerIDlist_g={} --//variable: store playerID.

local nextUpdate = 0 --//variable: indicate when to run widget:Update()
local delayUpdate = 0.1 --//constant: tiny delay for widget:Update() to reduce CPU usage
local nextRefreshTime = 0 --//variable: indicate when to activate player list refresh.
local refreshDelay_g = 10 --//variable, (determined by number of players): seconds before playerIDlist_g is refreshed and retry list resetted.

--communication protocol variables
local currentTime_g=0 --//variable: used to indicate current ingame seconds
local waitTransmissionUntilThisTime_g =currentTime_g --//variable:allow widget:Update() polling to wait until at time calculated using reported ping.
local waitBusyUntilThisTime_g=currentTime_g --//variable: allow NetworkProtocol replying to wait until at time calculate using reported ping.
local checklistTable_g={} --//variable: widget's stack/queue
local waitForTransmission_g=false --//variable: used as a switch to wait for reply before sending another "hi"
local lineIsBusy_g=false --//variable: used as a switch to stop replying using Network protocol
local openPortForID_g=-1 --//variable: used to filter out message not intended for us 
local tableIsCompleted_g=false --//variable: used as switch to stop checking checklistTable
local fileRequestTableG_g={} --//variable: used by Operation Mode "B" to store file requested by others.
local msgRecv_g={} --//variable: store message before it is processed.
local networkDelay_g = {sentTimestamp = 0, sumOfDelay = 0, msgCount = 0, averageDelay = 0, offset = 0}

--------------------------------------------------------------------------------
--File operation----------------------------------------------------------------

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


local function SaveToFile(filename, data, checksum)
	local duplicateFilePath = SearchFileByChecksum(checksum)
	local filepath="none"
	if (duplicateFilePath) then --//use existing filename & filepath if a duplicate file is found. This prevent widget from saving multiple duplicate under different name.
		filepath = duplicateFilePath
	else --//save file and extract filepath when no duplicate if found
	
		if(data:len()/1024 >= maxFileSize) then --//enable neat/original filename only for operational mode "A" where file size can be greater than 10Kb
			filepath = avatarsDir .. filename --original filename only (look neat and filename consistent with web based avatar, but risk overwrite similar named file)
		else --//add checksum to filename to prevent name duplication
			filepath = avatarsDir .. checksum .. '_' .. filename --filename + checksum as name (very safe but messy filename)
		end
		Spring.CreateDir(avatarsDir)
		local out = assert(io.open(filepath, "wb"))
		out:write(data)
		assert(out:close())
		
	end
	Spring.Echo(filepath) --echo out saved file
	
	return filepath
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
--Avatar information------------------------------------------------------------
local function SetAvatar(playerName, filename, checksum, avatarsTable) --//to save value into "avatarsTable[]"
	avatarsTable[playerName] = {
		checksum = checksum,
		file = filename,
		age = 0,
	}
	table.save(avatarsTable, configFile)
	return avatarsTable
end

local function DeleteAvatar(playerName, avatarsTable)   --//to delete value from "avatarsTable[]"
	avatarsTable[playerName] = nil
	table.save(avatarsTable, configFile)
	return avatarsTable
end

local function GetAvatar(playername) --//to be called by Chatbubble widget. Return player's avatar
	local avInfo = avatarsTable_g[playername]
	local filepath = nil
	if avInfo then 
		if (avInfo.age or 0) <= 5 then --//block all outdated picture from being shown on chatbubble after ~5 games.
			filepath = avInfo.file 
		end
	end
	return filepath --else return nil (chatbubble can handle the nil value)
end

local function SetMyAvatar(filename)
--[[
	fixme!!!
	if (filename == nil) then
		avatarsTable_g[myPlayerName_g] = nil
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
	avatarsTable_g = SetAvatar(myPlayerName_g,filename,checksum, avatarsTable_g)
	Spring.SendLuaUIMsg(broadcastID) --send 'checkout my new pic!' to everyone
	networkDelay_g.sentTimestamp = os.clock() --//for measuring actual lag
end

--------------------------------------------------------------------------------
--Player Infos------------------------------------------------------------------

local function GetPlayersData(switch, playerID) --//group player's info as a function to facilitate debuggings. Values can be injected to test multi-player condition.
	if switch == 1 then --//used by self
		local _,_,_,_,_,_,_,_,_,customKeys = Spring.GetPlayerInfo(playerID)
		return customKeys
		--[[
		local customKeys ={avatar="picA"}
		return customKeys
		Spring.Echo("---")
		Spring.Echo("Switch 1")
		Spring.Echo("playerID")
		Spring.Echo(playerID)
		Spring.Echo("customKeys")
		Spring.Echo(customKeys)
		Spring.Echo("---")
		--]]
	elseif switch == 2 then --//used by all players
		local playerName = Spring.GetPlayerInfo(playerID)
		return playerName
		--[[
		local playerName = {"A", "B", "C", "D", "E"}
		return playerName[playerID+1]
		Spring.Echo("---")
		Spring.Echo("Switch 2")
		Spring.Echo("playerID")
		Spring.Echo(playerID)
		Spring.Echo("playerName")
		Spring.Echo(playerName)
		Spring.Echo("---")
		--]]
	elseif switch == 3 then --//used by self or other players
		local _,_,_,_,_,targetPingTime,_,_,_,_= Spring.GetPlayerInfo(playerID)
		return targetPingTime
		--local targetPingTime = 666
		--return targetPingTime
	elseif switch == 4 then --//used by all players
		local playerName, activePlayer ,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,playerCustomKeys = Spring.GetPlayerInfo(playerID)
		--[[
		Spring.Echo("---")
		Spring.Echo("Switch 4")
		Spring.Echo("playerID")
		Spring.Echo(playerID)
		Spring.Echo("playerName")
		Spring.Echo(playerName)
		Spring.Echo("playerIsSpectator")
		Spring.Echo(playerIsSpectator)
		Spring.Echo("playerAllyTeamID")
		Spring.Echo(playerAllyTeamID)
		Spring.Echo("playerCustomKeys")
		Spring.Echo(playerCustomKeys)
		Spring.Echo("---")
		--]]		
		return playerName, activePlayer, playerIsSpectator,playerAllyTeamID, playerCustomKeys
		--local playerName = {"A", "B", "C", "D", "E"}
		--local playerIsSpectator = {false,false,false,false,false}
		--local playerAllyTeamID = {1, 1, 1, 1, 1}
		--local playerCustomKeys = {"picA","picB","picC","picD","picE"}
		--return playerName[playerID+1], playerIsSpectator[playerID+1],playerAllyTeamID[playerID+1], playerCustomKeys[playerID+1]
	elseif switch == 5 then --//used by all players
		local _,playerIsActive,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
		--[[
		Spring.Echo("---")
		Spring.Echo("Switch 5")
		Spring.Echo("playerID")
		Spring.Echo(playerID)
		Spring.Echo("playerIsActive")
		Spring.Echo(playerIsActive)
		Spring.Echo("playerIsSpectator")
		Spring.Echo(playerIsSpectator)
		Spring.Echo("playerAllyTeamID")
		Spring.Echo(playerAllyTeamID)
		Spring.Echo("---")
		--]]
		return playerIsActive,playerIsSpectator,playerAllyTeamID
		--[[
		local playerIsActive = {true,true, true,true,true}
		local playerIsSpectator = {false,false,false,false,false}
		local playerAllyTeamID = {1, 1, 1, 1, 1}
		return playerIsActive[playerID+1],playerIsSpectator[playerID+1],playerAllyTeamID[playerID+1]
		--]]
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
--Chilli interface--------------------------------------------------------------

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
	if operatingModeThis_g == "A" then 
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
		file   = GetAvatar(myPlayerName_g);
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
				SetMyAvatar(image.file) --//use the image shown on the GUI as my current avatar
				local customKeys = GetPlayersData(1, myPlayerID) --//equal to Spring.GetPlayerInfo(myPlayerID)
				local myDefaultAvatar=InitializeDefaultAvatar(customKeys)
				if image.file == myDefaultAvatar.file then
					avatarsTable_g = DeleteAvatar("useCustom",avatarsTable_g) --//delete entry "useCustom" if player is using default avatar. A "nil" entry will ensure that this widget update the default avatar everytime it start (non-"nil" make it use cached value).
				else
					avatarsTable_g = SetAvatar("useCustom", "yes", 0000, avatarsTable_g ) --//store a "yes" under playerName "useCustom" as a tool to indicate whether user is using custom avatar or not.
				end
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
				local customKeys = GetPlayersData(1, myPlayerID) --//equal to Spring.GetPlayerInfo(myPlayerID)
				local myAvatar=InitializeDefaultAvatar(customKeys)
				image.file = myAvatar.file --//show the default image (server assigned image) on GUI
				image:Invalidate()
			end
		}
	}	

	local sizeA = "0%"
	if operatingModeThis_g == "A" then 
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
							Spring.Echo('Avatar: selected image file exceed the preset size limit (size limit is ' .. maxFileSize .. 'kB)')
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
--Converts string into file-request (Mode B operation)--------------------------

local function ConvertFileRequestIntoString (playerIDlist, checklistTable)
	local playerID=-1
	local fileRequestCode=1
	local fileRequestIndex=100
	for iteration=1, #playerIDlist, 1 do
		playerID=playerIDlist[iteration]
		if checklistTable[(playerID+1)].accept then --check self and others but don't check the ignore list
			if (checklistTable[(playerID+1)].downloaded==false) then --check checklist if complete
				fileRequestCode=(fileRequestCode*100)+playerID
				fileRequestIndex=fileRequestIndex+1
			end
		end
	end
	local theRequestCode=fileRequestIndex .. fileRequestCode --IF there is 3 player then 'fileRequestIndex' will do: 100+1+1+1= 103, and 'fileRequestCode' will do: (((1*100+02)*100+01)*100+00) = 1000102. eg: 'theRequestCode'== "1031000102", meaning "3 player" & playerID == "00","01","02".
	return theRequestCode
end

local function ConvertStringIntoFileRequest (fileRequestCode)
	local fileRequestTable={}
	local requestCount = tonumber(fileRequestCode:sub(2,3))
	fileRequestCode = fileRequestCode:sub(5,4+requestCount*2) --eg: (5,6) or (5,8) or (5,10) or (5,12) or (5,14)
	local index = 1
	for i=1, requestCount,1 do
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
--Network Protocols-------------------------------------------------------------

local function RecordActualNetworkDelay (networkDelay)
	local actualDelay = os.clock() - networkDelay.sentTimestamp
	networkDelay.sumOfDelay = networkDelay.sumOfDelay + actualDelay
	networkDelay.msgCount = networkDelay.msgCount +1
	networkDelay.averageDelay = networkDelay.sumOfDelay /networkDelay.msgCount
	return networkDelay
end

local function RetrieveTotalNetworkDelay(playerIDa, playerIDb)
	local aTargetPingTime = GetPlayersData(3, playerIDa) --//equal to Spring.GetPlayerInfo(playerIDa)
	local bTargetPingTime = GetPlayersData(3, playerIDb)
	if playerIDa == myPlayerID then --//IF playerIDa is myPlayerID: try to actually measure the ping
		if networkDelay_g.averageDelay > aTargetPingTime then --//if actual delay greater than reported delay (ping)
			local delayOffset = 0
			if aTargetPingTime == 0 then   --//if my delay is "0"
				aTargetPingTime = 1 --//arbitrarily assume 1 second delay
			else 
				delayOffset = networkDelay_g.averageDelay - aTargetPingTime --// get difference between reported and actual delay
				aTargetPingTime = aTargetPingTime + delayOffset --//add the difference in delay to the output values
				networkDelay_g.offset = delayOffset
			end
			if bTargetPingTime == 0 then --//if remote computer's delay is "0"
				bTargetPingTime = 1 --//arbitrarily assume 1 second delay
			else
				bTargetPingTime = bTargetPingTime + delayOffset --//add the difference in delay to output
			end
		end
	else --if both player is not myPlayerID: add offset anyway
		aTargetPingTime = aTargetPingTime + networkDelay_g.offset
		bTargetPingTime = bTargetPingTime + networkDelay_g.offset
	end
	local totalDelay= aTargetPingTime+bTargetPingTime
	if totalDelay == 0 then return (2 + delayUpdate) --//if reported delay is "0" then arbitrarily assume each side has 1 second delay
	elseif totalDelay<0.5 then return (0.5 + delayUpdate) --if delay too low don't spam message out too quickly
	elseif totalDelay>=2 then return (2 + delayUpdate) --if delay too high then don't wait too long, just send until the retry depleted (end connection)
	else return totalDelay --//use the calculated delay if the delay is within reasonable range
	end
end

local function NetworkProtocol(waitTransmissionUntilThisTime,waitBusyUntilThisTime,checklistTable,waitForTransmission,lineIsBusy,openPortForID,tableIsCompleted,currentTime)
	local msgRecv= msgRecv_g
	local fileRequestTableG=fileRequestTableG_g
	local avatarsTable = avatarsTable_g
	---------------------------
	
	if (#msgRecv or 0)>=1 then --check lua message from 'inbox'
		local entryEmpty = true
		local remotePlayerID, msg = nil, nil
		local msgRecvLenght = (#msgRecv or 0)
		while msgRecvLenght >= 1 and entryEmpty do
			remotePlayerID=msgRecv[#msgRecv].playerID
			msg=msgRecv[#msgRecv].msg
			if (msg:sub(1,4) == msgID or msg:sub(1,4) == broadcastID) then --if message belong to hello/hi file transfer protocol
				entryEmpty = false
			end
			msgRecv[#msgRecv]=nil --//add 'nil' here so #msgRecv index shift backward by 1
			msgRecvLenght = #msgRecv --//retrieve the updated table lenght
		end
		if (entryEmpty == false) then --//activate only when relevant message received.		
			local destinationID=tonumber(msg:sub(8,9)) --//get the "openPortForID" sent from remote computer
			local myAvatar = avatarsTable[myPlayerName_g]
			
			if openPortForID==remotePlayerID and destinationID==myPlayerID and not lineIsBusy then --//if sender is expected & line is clear, then:
				if msg:sub(6,6)==hi then --receive hi from target remotePlayerID.  This is a rare case where me & sender sent "hi" at same time.
					if myPlayerID>remotePlayerID then --IF myID is greater than sender'sID then I am 'low ranking', so I must reply yes.
						--reply with yes
						local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
						local msgType = yes
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100)
						waitForTransmission=true
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking (including "hi" sending) until there's enough time for remote computer to reply (is x2 totalNetworkDelay)
					end
				elseif msg:sub(6,6)==yes then --received yes from targetted remotePlayerID. This is when sender received my "hi" and replied with "yes".
					local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
					if operationMode == "A" then
					----
						local msgType = checksumA
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. myAvatar.checksum) --send checksum, "x" is payload request flag (not available at this stage)
						---// default message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID)...
					----
					else --if mode B
					----
						local myRequestList = ConvertFileRequestIntoString (playerIDlist_g, checklistTable)
						local msgType = checksumA
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. myRequestList)
					----
					end
					local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay)
				elseif msg:sub(6,6)==checksumA then --receive checksumA
					local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
					if operationMode == "A" then
					----
						local checksum = tonumber(msg:sub(11)) --//get the "myAvatar.checksum" sent from remote computer					
						local playerName = GetPlayersData(2, remotePlayerID) --//equal to Spring.GetPlayerInfo(remotePlayerID)

						local payloadRequestFlag=0
						local file = SearchFileByChecksum(checksum)
						if (file) then --// if already downloaded it, reuse it
							avatarsTable = SetAvatar(playerName,file,checksum, avatarsTable)
							checklistTable[(remotePlayerID+1)].downloaded=true --tick 'done' on file downloaded
						else --// if doesn't have it, request it
							payloadRequestFlag=1
						end
						
						local msgType = checksumB
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. payloadRequestFlag .. myAvatar.checksum) --send checksum
						---// default message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID)...
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
						local myRequestList = ConvertFileRequestIntoString (playerIDlist_g, checklistTable) --compose our file request
						local msgType = checksumB
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. willSendFile .. myRequestList)
					----
					end
					local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay)
				elseif msg:sub(6,6)==checksumB then --receive checksumB
					local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
					if operationMode == "A" then
					----
						local checksum = tonumber(msg:sub(11)) --//get the "myAvatar.checksum" sent from remote computer
						local playerName = GetPlayersData(2, remotePlayerID) --//equal to Spring.GetPlayerInfo(remotePlayerID)

						local payloadRequestFlag=0
						local file = SearchFileByChecksum(checksum)
						if (file) then --// if already downloaded it, reuse it
							avatarsTable = SetAvatar(playerName,file,checksum, avatarsTable)
							checklistTable[(remotePlayerID+1)].downloaded=true --tick 'done' on file downloaded
						else --// if doesn't have it, request it
							payloadRequestFlag=1
						end
						
						if (msg:sub(10,10)=="1") then --if remote computer sent a 'payload request'
							local cdata = VFS.LoadFile(myAvatar.file) --//load my pic into "cdata"
							local filename = ExtractFileName(myAvatar.file) --//extract my picture's filename from my picture's filepath
							local msgType = payloadA
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. payloadRequestFlag .. "1" .. filename .. '$' .. cdata) --send payload, "1" is payload flag
							---// default payload message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID), 10(payloadRequestFlag), 11(has Payload Flag)...
						else --if remote computer sent NO 'payload request'
							if payloadRequestFlag==1 then --if I have a 'payload request' of my own
								local msgType = payloadA
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. payloadRequestFlag .. "0") --send "payload package" without payload ("0")
							else --if I DON'T have any 'payload request'
								local msgType = bye
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
								openPortForID = -1 --//reset the openPortID if has sent BYE
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
						while (willSendFile == 0) and (iteration <= #fileRequestTableG) do --check if we have any file to send
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
							local msgType = payloadA
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
							---// default message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID)...
						else
							if (msg:sub(10,10) == "1") then  --if remote computer has any file to send
								local msgType = payloadA
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
							else --if NOT us and NOT remote computer has any file to send
								local msgType = bye
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
								openPortForID = -1 --//reset the openPortID if has sent BYE
							end
						end
					----
					end
					local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay)
				elseif msg:sub(6,6)==payloadA then --//receive payload from sender A (assuming we are sender B).
					local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
					if operationMode == "A" then
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local payloadMsg = msg:sub(12) --//character 12 & above contain filename and the payload itself. Default payload message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID), 10(payloadRequestFlag), 11(has Payload Flag)...
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(remotePlayerID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, remotePlayerID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum, avatarsTable)
						end
						if (msg:sub(10,10)=="1") then --remote client's payloadRequestFlag
							local cdata = VFS.LoadFile(myAvatar.file)
							local filename = ExtractFileName(myAvatar.file)
							local msgType = payloadB
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "1" .. filename .. '$' .. cdata) --send payload,"x" is payload request flag(unavailable), "1" is payload flag
						else
							local msgType = payloadB
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
						end
					----
					else --if mode B
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local userID = msg:sub(13,14)
							local payloadMsg = msg:sub(15)
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(userID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, userID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum, avatarsTable)
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
							local msgType = payloadB
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. willSendFile .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
							---// default message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID)...
						else
							local msgType = payloadB
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. willSendFile .. "0") --send "payload package" without payload
						end
					----
					end
					local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay)
				elseif (msg:sub(6,6)==payloadB) then --//receive payload from sender B (assuming we are sender A).
					local operationMode = msg:sub(5,5) --get the sender's operation mode. Propagate operation mode to the entire protocol
					if operationMode == "A" then
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local payloadMsg = msg:sub(12) --//character 12 & above contain filename and the payload itself. Default payload message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID), 10(payloadRequestFlag), 11(has Payload Flag)...
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(remotePlayerID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, remotePlayerID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum,avatarsTable)
						end
						local msgType = bye
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100)
						waitForTransmission=false
						openPortForID = -1 --//reset the openPortID if has sent BYE
					----
					else --if mode B
					----
						if (msg:sub(11,11)=="1") then --payload "is here!" flag
							local userID = msg:sub(13,14)
							local payloadMsg = msg:sub(15)
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(userID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, userID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum, avatarsTable)
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
							local msgType = payloadA
							Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "1" .. 100+ownerID .. filename .. '$' .. cdata) --send payload, "1" is payload flag
						else
							if (msg:sub(10,10) == "1") then  --if remote computer has any file to send
								local msgType = payloadA
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
							else --if NOT us and NOT remote computer has any file to send
								local msgType = bye
								Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100) --skip next protocol if both player don't need payload
								waitForTransmission=false
								openPortForID = -1 --//reset the openPortID if has sent BYE
							end
						end
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay). This only apply to operation mode 'B' since mode 'A' protocol ended here.
					----
					end
				elseif (msg:sub(6,6)==bye) then
					waitForTransmission=false
					openPortForID = -1 --//reset the openPortID if has sent BYE
				end
			elseif myPlayerID==destinationID then --//if message is from others & is meant for me
				if msg:sub(6,6)==hi then --receive hi from someone who target you
					if enableEcho_debug then Spring.Echo(tableIsCompleted) Spring.Echo(" tableIsComplete =? , NetworkProtocol()") end
					if myPlayerID>remotePlayerID or tableIsCompleted then --if I have the 'low ranking' PlayerID then reply yes, else don't (high ranking do not answer to low ranking unless its checklist table is completed (idle))
						--reply with yes
						local operationMode = msg:sub(5,5) --propagate operation mode to the subsequent protocol
						openPortForID=remotePlayerID
						waitForTransmission=true --turn off "hi" sending, turn off checklist table checking
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, remotePlayerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking further until there's enough time for remote computer to reply (is x2 totalNetworkDelay). This only apply to operation mode 'B' since mode 'A' protocol ended here.
						local msgType = yes
						Spring.SendLuaUIMsg(msgID .. operationMode .. msgType .. openPortForID+100)
					end 
				end
			elseif (myPlayerID~=destinationID) and (myPlayerID~=remotePlayerID) then --if message is noise (not targetted to me) and message not from me
				if msg:sub(6,6)==yes then --heard "yes" from someone to someone else
					if myPlayerID>remotePlayerID then --if they are the 'higher ranking' PlayerID: close your own connection for them
						lineIsBusy=true --assume they took command of the communication medium, close all protocol/cancel ongoing protocol. lineBusy always triggered by high ranking noise
						waitForTransmission=true
						openPortForID = -1 --//reset the openPortID
						--[[ --//commented because using a same waiting method for both operationMode
						local operationMode = msg:sub(5,5)
						if operationMode == "A" then
							local totalNetworkDelay= RetrieveTotalNetworkDelay(destinationID, remotePlayerID) --delay between 2 computer
							waitBusyUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 + (totalNetworkDelay*0.5) --assume twice the delay for complete back and forth + 3rd message. Wait until3rd message.
							waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 + (totalNetworkDelay*0.5)--assume twice the delay for complete back and forth + 3rd message. Wait until3rd message.
						else --if mode B
							local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, destinationID) --delay between us (listener) and the replier. As an accurate estimate of delay between sender & receiver
							waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend communication protocol until next checksum is sent either by sender/receiver.
							waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend checklist check until next checksum is sent either by sender/receiver.
						end --]]
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, destinationID) --delay between us (listener) and the replier. As an accurate estimate of delay between sender & receiver
						waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend communication protocol until next checksum is sent either by sender/receiver.
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend checklist check until next checksum is sent either by sender/receiver.						
					end
				elseif msg:sub(6,6)==checksumA or msg:sub(6,6)==checksumB then --snif checksum transfer and save it for our own
					local operationMode = msg:sub(5,5)
					if operationMode == "A" then
						local checksum = tonumber(msg:sub(11))
						local playerName = GetPlayersData(2, remotePlayerID)
						local file = SearchFileByChecksum(checksum)
						if (file) then
							--// already downloaded it once, reuse it
							avatarsTable = SetAvatar(playerName,file,checksum, avatarsTable)
							checklistTable[(remotePlayerID+1)].downloaded=true
						else
							checklistTable[(remotePlayerID+1)].retry=0 --if we have no file yet, but heard this broadcast then reset retry count to continue trying to reach this remotePlayerID
							tableIsCompleted=false --recheck checklist
						end
					else
						--intentionally empty--
						--[[ --//commented because using a same waiting method for both operationMode
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, destinationID) --delay between us (listener) and the replier. As an accurate estimate of delay between sender & receiver
						waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend communication protocol until next checksum/payload is sent either by sender/receiver.
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend checklist check until next checksum/payload is sent either by sender/receiver.
						--]]
					end	
					local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, destinationID) --delay between us (listener) and the replier. As an accurate estimate of delay between sender & receiver
					waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend communication protocol until next checksum/payload is sent either by sender/receiver.
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend checklist check until next checksum/payload is sent either by sender/receiver.
					
				elseif (msg:sub(6,6)==payloadB or msg:sub(6,6)==payloadA) then --snif package transfer and save for our own
					if (msg:sub(11,11)=="1") then --payload "is here!" flag
						local operationMode = msg:sub(5,5)
						if operationMode == "A" then
							local payloadMsg = msg:sub(12) --//character 12 & above contain filename and the payload itself. Default payload message template: 1-4 (msgID), 5(operationMode), 6(msgType), 7-9(openPortForID), 10(payloadRequestFlag), 11(has Payload Flag)...
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(remotePlayerID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, remotePlayerID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum, avatarsTable)
						else --if mode B
							local userID = msg:sub(13,14)
							local payloadMsg = msg:sub(15)
							local endOfFilename = payloadMsg:find('$',1,true)
							local filename = payloadMsg:sub(1,endOfFilename-1)
							local cdata    = payloadMsg:sub(endOfFilename+1)
							local checksum   = CalcChecksum(cdata)
							checklistTable[(userID+1)].downloaded=true --tick 'done' on file downloaded

							local playerName = GetPlayersData(2, userID)
							local filepath = SaveToFile(filename, cdata, checksum)
							avatarsTable = SetAvatar(playerName,filepath,checksum, avatarsTable)
						end
						local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, destinationID) --delay between us (listener) and the replier
						waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend communication protocol until next payload is sent either by sender/receiver.
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*networkDelayMultiplier --//suspend checklist check until next payload is sent either by sender/receiver.
					end
				elseif (msg:sub(6,6)==bye) then
					lineIsBusy=false
					waitForTransmission=false
				end
			elseif myPlayerID == remotePlayerID then --//if message is from me (an echo of myself), then record delay
				if msg:sub(6,6)==hi then --//listen hi from self
					networkDelay_g = RecordActualNetworkDelay (networkDelay_g)
				end
			end
			if (msg:sub(1,4) == broadcastID) then --if message is a 'look at my new pic!'.
				if checklistTable[(remotePlayerID+1)] ==nil then
					checklistTable[(playerID+1)]={downloaded=false, retry=0, accept=true} --fill checklist with default values. This value allow widget to initiate communication with other players.
				else
					checklistTable[(remotePlayerID+1)].downloaded=false --reset checklist entry for this player
					--checklistTable[(remotePlayerID+1)].accept=true
					checklistTable[(remotePlayerID+1)].retry=0 --reset retry
				end
				tableIsCompleted=false --redo checklist check
				if myPlayerID == remotePlayerID then --//if broadcast is an echo of myself: record delay
					networkDelay_g = RecordActualNetworkDelay (networkDelay_g)
				end
			end
		end
	end
	
	---------------------------
	msgRecv_g = msgRecv
	fileRequestTableG_g =fileRequestTableG
	avatarsTable_g = avatarsTable
	
	return waitTransmissionUntilThisTime,waitBusyUntilThisTime,checklistTable,waitForTransmission,lineIsBusy,openPortForID,tableIsCompleted
end

--------------------------------------------------------------------------------
--Polling function--------------------------------------------------------------

function widget:Update(n)
	local currentTime = currentTime_g
	local waitTransmissionUntilThisTime = waitTransmissionUntilThisTime_g
	local waitForTransmission = waitForTransmission_g
	local waitBusyUntilThisTime = waitBusyUntilThisTime_g
	local lineIsBusy = lineIsBusy_g
	local tableIsCompleted = tableIsCompleted_g
	local checklistTable = checklistTable_g
	local openPortForID = openPortForID_g
	local operatingModeThis = operatingModeThis_g
	local playerIDlist = playerIDlist_g
	local refreshDelay = refreshDelay_g
	---------------------------
	
	currentTime=currentTime+n
	local now = currentTime
	if (now > nextUpdate) then
		nextUpdate = now + delayUpdate
	else
		currentTime_g = currentTime --//return "currentTime" back to global environment 
		return
	end
	if (now > nextRefreshTime) then
		nextRefreshTime = now + refreshDelay
		if enableEcho_debug then Spring.Echo("updatePlayerList()") end
		tableIsCompleted, operatingModeThis, checklistTable, playerIDlist, refreshDelay =UpdatePlayerList(tableIsCompleted,operatingModeThis, checklistTable, playerIDlist, refreshDelay)
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
		local continue=true
		for iteration=1, #playerIDlist, 1 do
			playerID=playerIDlist[iteration]
			if playerID~=myPlayerID and checklistTable[(playerID+1)].accept then --don't check self and don't check ignore list
				if (checklistTable[(playerID+1)].downloaded==false) then --check if has downloaded the player's file
					if checklistTable[(playerID+1)].retry < numberOfRetry_g then
						continue=false --//escape current loop, signal an interruption, and continue with next function
						checklistTable[(playerID+1)].retry=checklistTable[(playerID+1)].retry+1 -- ++ retry count
						break
					end
				end
			end
		end
		if continue then --if last check performed without any interruption (continue = true) then all entry are complete
			tableIsCompleted=true
			if enableEcho_debug then Spring.Echo(tableIsCompleted) Spring.Echo("^tableIsCompleted = true, Update()") end
			if operatingModeThis == "B" then
				if checklistTable[(myPlayerID+1)].downloaded == false then
					Spring.SendLuaUIMsg(broadcastID) --send 'I still don't have my pic!' to everyone (Operation Mode: "B")
					networkDelay_g.sentTimestamp = os.clock()
				end
			end
		else --//if checking was interrupted (continue = false) then some player hasn't been contacted/communicated yet, then contact them
			openPortForID=playerID
			waitForTransmission=true --//prevent another checklist check in the next Update() cycle (wait until contact is complete)
			local totalNetworkDelay= RetrieveTotalNetworkDelay(myPlayerID, playerID) --//return 1 trip delay, including Update(n)'s interval & measured LUA-msg delay. 
			waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay*networkDelayMultiplier)*2 --suspend any table checking (including "hi" sending) until there's enough time for remote computer to reply (x2 totalDelay)
			local msgType = hi
			Spring.SendLuaUIMsg(msgID .. operatingModeThis .. msgType .. openPortForID+100) --send 'hi' to colleague
			networkDelay_g.sentTimestamp = os.clock() --//remember current time for delay checking later
			-- if enableEcho_debug then 
				-- Spring.Echo(checklistTable[(playerID+1)].accept) Spring.Echo("^accept")
				-- Spring.Echo(checklistTable[(playerID+1)].downloaded) Spring.Echo("^downloaded")
				-- Spring.Echo(checklistTable[(playerID+1)].retry) Spring.Echo("^retry")
			-- end
		end
	end
	waitTransmissionUntilThisTime,waitBusyUntilThisTime,checklistTable,waitForTransmission,lineIsBusy,openPortForID,tableIsCompleted = NetworkProtocol(waitTransmissionUntilThisTime,waitBusyUntilThisTime,checklistTable,waitForTransmission,lineIsBusy,openPortForID,tableIsCompleted,currentTime) --// perform Hello/Hi network protocol
	--if enableEcho_debug then Spring.Echo(not tableIsCompleted) Spring.Echo("^tableIsCompleted") end
	---------------------------
	currentTime_g = currentTime
	waitTransmissionUntilThisTime_g = waitTransmissionUntilThisTime
	waitForTransmission_g = waitForTransmission
	waitBusyUntilThisTime_g = waitBusyUntilThisTime
	lineIsBusy_g = lineIsBusy
	tableIsCompleted_g = tableIsCompleted
	checklistTable_g = checklistTable
	openPortForID_g = openPortForID
	playerIDlist_g = playerIDlist
end

--------------------------------------------------------------------------------
--Receiver----------------------------------------------------------------------

function widget:RecvLuaMsg(msg, playerID) --each update will put message into "msgRecv_g"
	if msg:sub(1,1)== wdgtID then
		msgRecv_g[(#msgRecv_g or 0) +1]={msg=msg, playerID=playerID}
		if enableEcho_debug then
			Spring.Echo(msg:sub(6,6) .. "<--msgType") --//echo out the message type (for debugging)
			Spring.Echo(playerID .. "<--playerID")
			Spring.Echo(msg:sub(8,9) .. "<--destinationID") --//echo out the message type (for debugging)
		end
	end
end

--------------------------------------------------------------------------------
--Player List-------------------------------------------------------------------

function widget:PlayerChanged(playerID) --in case where player status changed (eg: active, non-active)
	tableIsCompleted_g, operatingModeThis_g, checklistTable_g, playerIDlist_g, refreshDelay_g =UpdatePlayerList(tableIsCompleted_g,operatingModeThis_g, checklistTable_g, playerIDlist_g, refreshDelay_g)
end
--[[
function widget:PlayerAdded(playerID) --in case where player status changed (eg: joined, spec)
	UpdatePlayerList()
end

function widget:PlayerRemoved(playerID)
	UpdatePlayerList()
end
--]]
function UpdatePlayerList(tableIsCompleted, operatingModeThis, checklistTable, playerIDlist, refreshDelay)
	local numberOfRetry = numberOfRetry_g
	local myAllyTeamID = myAllyTeamID_g
	local avatarsTable = avatarsTable_g
	------------------localized global variable/constant
	--get info on self
	local iAmSpectator= (Spring.GetSpectatingState()) or (false) --//return true if I am spectator (Spring.GetSpectatingState() = true), or return false if I'm not spectating (Spring.GetSpectatingState() = nil).
	--get all playerID list
	playerIDlist= GetPlayersData(8, nil) --//equal to Spring.GetPlayerList()
	
	--use playerIDlist to update checklist
	local playerCount = #playerIDlist
	for iteration=1, #playerIDlist, 1 do --update checklist and fill it with appropriate value
		local playerID = playerIDlist[iteration]
		if checklistTable[(playerID+1)]==nil then 
			checklistTable[(playerID+1)]={downloaded=true, retry=0, accept=true} --add new entry with default value. This value PREVENT widget to initiate communication with other players unless they sent a "broadcastID".
		else 
			checklistTable[(playerID+1)].accept=true --reset previous ignore list
			checklistTable[(playerID+1)].retry=0 --reset retry counter
		end
		
		if operatingModeThis == "B" then
			local playerName,playerIsSpectator,playerAllyTeamID, playerCustomKeys = GetPlayersData(4, playerID)
			if (playerCustomKeys ~= nil and playerCustomKeys.avatar~=nil) then 
				local customKeyAvatarFile = avatarsDir .. playerCustomKeys.avatar .. ".png" --check if we have that file on disk
				if (VFS.FileExists(customKeyAvatarFile)) then
					local checksum = CalcChecksum(VFS.LoadFile(customKeyAvatarFile))
					avatarsTable = SetAvatar(playerName, customKeyAvatarFile , checksum, avatarsTable)
					checklistTable[(playerID+1)].downloaded=true
				end
			end
		end
		
		--the following code add "ignore" flag to some selected playerID
		local playerIsActive,playerIsSpectator,playerAllyTeamID = GetPlayersData(5, playerID) --//is equal to Spring.GetPlayerInfo(playerID)
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator or not playerIsActive then --ignore non-specs and inactive player(don't send hi/request file)
				checklistTable[(playerID+1)].accept=false 
				playerCount = playerCount-1
			end
		else --if I am not spectator
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator or not playerIsActive then --if player is the enemy or a spec or inactive then
				checklistTable[(playerID+1)].accept=false --ignore enemy & spec and inactive player(don't send hi/request file)
				playerCount = playerCount-1
			end
		end
		-- if resetDownloadedRetryFlag_debug then
			-- checklistTable[(playerID+1)].downloaded=false
			-- checklistTable[(playerID+1)].retry=0
		-- end
	end
	local derivedRefreshDelay = (4*numberOfRetry*networkDelayMultiplier)*playerCount
	refreshDelay = math.max(derivedRefreshDelay, 4) --// set a 4 second delay (max) for each retry, times the number of players, OR set to a minimum of 4 second (in case at gamestart it return 0 delay). This determine the "refresh delay" (amount of second before the ignore list being resetted)
	tableIsCompleted=false --unlock checklist for another check
	--if enableEcho_debug then Spring.Echo(iAmSpectator) Spring.Echo("^iAmSpectator, updatePlayerList()") end
	--if enableEcho_debug then Spring.Echo(playerCount) Spring.Echo("^playerCount, updatePlayerList()") end
	------------------
	avatarsTable_g = avatarsTable
	
	return tableIsCompleted, operatingModeThis, checklistTable, playerIDlist, refreshDelay
end

function InitializeDefaultAvatar(customKeys)
	--initialize own avatar using the default fallback (Crystal_Personal)
	local myAvatar={
			checksum = avatar_fallback_checksum,
			file = avatar_fallback
		}  
	--initialize own avatar using server assigned avatar
	if (customKeys ~= nil and customKeys.avatar~=nil) then 
		local customKeyAvatarDir = avatarsDir .. customKeys.avatar --file path
		if (VFS.FileExists(customKeyAvatarDir .. ".png")) then --check if we have the file on disk with a ".png" extension
			myAvatar.file = customKeyAvatarDir .. ".png"
			myAvatar.checksum = CalcChecksum(VFS.LoadFile(myAvatar.file))
		elseif (VFS.FileExists(customKeyAvatarDir .. ".jpg")) then --check again if we have the file on disk with a ".jpg" extension instead
			myAvatar.file = customKeyAvatarDir .. ".jpg"
			myAvatar.checksum = CalcChecksum(VFS.LoadFile(myAvatar.file))
		end
		--if we don't have the file then use fallback avatar
	end
	return myAvatar
end

function widget:Initialize()
	local operatingModeThis = operatingModeThis_g
	local checklistTable = checklistTable_g
	local playerIDlist = playerIDlist_g
	local refreshDelay = refreshDelay_g
	local myPlayerName = myPlayerName_g
	local myAllyTeamID = myAllyTeamID_g
	local avatarsTable = avatarsTable_g
	local numberOfRetry = numberOfRetry_g
	------------------ localized global variable/constant
	--get info on self
	myPlayerID = GetPlayersData(7, nil) --//equal to Spring.GetMyPlayerID()
	local name,iAmSpectator,allyTeamID,customKeys = GetPlayersData(6, myPlayerID) --//equal to Spring.GetPlayerInfo(myPlayerID)
	myPlayerName =name
	myAllyTeamID=allyTeamID
	
	--get all playerID list
	playerIDlist= GetPlayersData(8, nil) --//equal to Spring.GetPlayerList()
	--Spring.Echo(playerIDlist)
	avatarsTable = (VFS.FileExists(configFile) and VFS.Include(configFile)) or {}

	--use player list to build checklist
	local playerCount = #playerIDlist
	for iteration=1, #playerIDlist, 1 do --fill checklist with initial value
		local playerID=playerIDlist[iteration]
		checklistTable[(playerID+1)]={downloaded=true, retry=0, accept=true} --fill checklist with default values. This value PREVENT widget to initiate communication with other players unless they sent a "broadcastID".
		
		local playerName, activePlayer , playerIsSpectator,playerAllyTeamID, playerCustomKeys = GetPlayersData(4, playerID) --//equal to Spring.GetPlayerInfo(playerID)
		if operatingModeThis == "B" then
			if (playerCustomKeys ~= nil and playerCustomKeys.avatar~=nil) then 
				local customKeyAvatarFile = avatarsDir .. playerCustomKeys.avatar .. ".png" --check if we have that file on disk
				if (VFS.FileExists(customKeyAvatarFile)) then
					local checksum = CalcChecksum(VFS.LoadFile(customKeyAvatarFile))
					avatarsTable = SetAvatar(playerName, customKeyAvatarFile , checksum, avatarsTable)
					checklistTable[(playerID+1)].downloaded=true
				end
			end
		end
		
		--the following codes add "ignore" flag to a selected playerID
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator or not activePlayer then --ignore non-specs and non-ingame(don't send hi/request file)
				checklistTable[(playerID+1)].accept=false 
				playerCount = playerCount-1
			end
		else --if I am not spectator:
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator or not activePlayer then --ignore enemy and spec and non-ingame (don't send hi/request file)
				checklistTable[(playerID+1)].accept=false
				playerCount = playerCount-1
			end
		end
	end
	local derivedRefreshDelay = (4*numberOfRetry*networkDelayMultiplier)*playerCount
	refreshDelay = math.max(derivedRefreshDelay, 4) --// set a 4 second delay (max) for each retry, times the number of players, OR set to a minimum of 4 second (in case at gamestart it return 0 delay). This determine the "refresh delay" (amount of second before the ignore list being resetted)
	
	--// remove broken entries & update entry age
	for playerName,avInfo in pairs(avatarsTable) do
		if (not VFS.FileExists(avInfo.file)) and playerName~="useCustom" then --//remove player entry that has no corresponding file
			avatarsTable[playerName] = nil
		elseif playerName~="useCustom" then --//++ the age for player entry with corresponding file. This ensure that outdated entry can be tracked
			avatarsTable[playerName].age = (avatarsTable[playerName].age or 0) +1
		end
	end
	
	local myAvatar= InitializeDefaultAvatar(customKeys)
	
	if operatingModeThis == "A" then
		if (avatarsTable[myPlayerName]~=nil) and (avatarsTable["useCustom"]~=nil) then --initialize custom avatar if was applied by user once and if it is available
			if VFS.FileExists(avatarsTable[myPlayerName].file) then --if selected file exist, then use it
				if  avatar_fallback_checksum ~= avatarsTable[myPlayerName].checksum then --proceed if NOT the default Crystal_Personal
					myAvatar.file=avatarsTable[myPlayerName].file
					myAvatar.checksum=avatarsTable[myPlayerName].checksum
				end --if we don't select more exciting avatar then fallback OR server-default remain
			end --if we don't have the selected avatar then fallback OR server-default remain
		end 
	end
	avatarsTable = SetAvatar(myPlayerName, myAvatar.file, myAvatar.checksum, avatarsTable) --save value into table and broadcast 'checkout my new avatar' message
	Spring.SendLuaUIMsg(broadcastID) --send 'checkout my new pic!' to everyone
	networkDelay_g.sentTimestamp = os.clock() --//for measuring actual lag
	
	WG.Avatar = {
		GetAvatar   = GetAvatar;
		SetMyAvatar = SetMyAvatar;
	}

	widgetHandler:AddAction("setavatar", SetAvatarGUI, nil, "t"); --// sending command "/setavatar" will execute SetAvatarGUI.
	------------------
	checklistTable_g = checklistTable
	playerIDlist_g = playerIDlist
	refreshDelay_g = refreshDelay
	myPlayerName_g = myPlayerName
	myAllyTeamID_g = myAllyTeamID
	avatarsTable_g = avatarsTable
end

function widget:Shutdown()
	--table.save(avatarsTable_g, configFile) <--will not save when exiting because if the widget exit too early it will save incomplete table

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
--thx to jseah for idea of using echo on commit version (for debugging).
