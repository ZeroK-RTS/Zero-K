local versionName = "v2.10"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Avatars",
    desc      = "An API for a per-user avatar-icon system, + Hello/Hi protocol",
    author    = "jK, +msafwan",
    date      = "2009, +2011 (7 Nov)",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    api       = true,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local avatars = {}

local msgID       	= "&AAA"
local hi 			= "1"
local yes  			= "2"
local checksumA     = "3"
local checksumB		= "4"
local payloadA		= "5"
local payloadB		= "6"
local bye			= "7"
local broadcastID 	= "&AAB"

local maxFileSize = 10 --in kB
local numberOfRetry = 7 --times to send "hi" until remote computer reply
local maxChecksumLenght= 2000  --if greater than 2049 will cause unpack error 
--reference: http://www.promixis.com/forums/showthread.php?15419-Lua-Limits-on-Table-Size

local configFile = "LuaUI/Configs/avatars.lua"
local avatarsDir = "LuaUI/Configs/Avatars/"
local avatar_fallback = avatarsDir .. "Crystal_personal.png"
local avatar_fallback_checksum = 13686070

local myPlayerID=-1
local myPlayerName =-1 
local myAllyTeamID=-1
local playerIDlist={}
local bufferIndex=0
local msgRecv={}
local currentTime=0
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
	if(data:len()/1024 >= maxFileSize) then
		file = avatarsDir .. filename --original filename only (look neat and filename consistent with web based avatar, but risk overwrite similar named file)
	else
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

local function GetAvatar(playername)
	local avInfo = avatars[playername]
	return (avInfo and avInfo.file) --if no entry then will return nil (chatbubble can handle the nil value)
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

	Chili.Label:New{
		parent     = chili_window;
		x          = 10;
		caption    = "Select your Avatar";
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
				local _,_,_,_,_,_,_,_,_,customKeys = Spring.GetPlayerInfo(myPlayerID)
				local myAvatar={}
				myAvatar=InitializeDefaultAvatar(myAvatar, customKeys)
				image.file = myAvatar.file
				image:Invalidate()
			end
		}
	}	

	local control = Chili.ScrollPanel:New{
		parent = chili_window;
		x      = 0;
		y      = 20;
		width  = -100;
		height = -20;
		children = {    
			Chili.ImageListView:New{
				name   = "AvatarSelectImageListView",
				width  = "100%",
				height = "100%",
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
--communication protocol variables
local waitTransmissionUntilThisTime =currentTime
local waitBusyUntilThisTime=currentTime
local checklistTable={}
local waitForTransmission=false
local lineIsBusy=false
local openPortForID=-1 --used for filtering message
local tableIsCompleted=false
function widget:Update(n)
	currentTime=currentTime+n
	local now=currentTime
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
		while doChecking and iteration <= #playerIDlist do
			playerID=playerIDlist[iteration]
			if playerID~=myPlayerID and not checklistTable[(playerID+1)].ignore then --don't check self and don't check ignore list
				if (checklistTable[(playerID+1)].downloaded==false) then --check checklist if complete
					if checklistTable[(playerID+1)].retry<numberOfRetry then
						doChecking=false
						checklistTable[(playerID+1)].retry=checklistTable[(playerID+1)].retry+1 -- ++ retry count
					end
				end
			end
			iteration=iteration+1 --check next entry
		end
		if doChecking then --if last check performed without interruption meaning all entry are complete
			tableIsCompleted=true
		else
			openPortForID=playerID
			waitForTransmission=true
			local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
			waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg
			Spring.SendLuaUIMsg(msgID .. hi .. openPortForID+100) --send 'hi' to colleague
		end
	end

	if bufferIndex>=1 then --check lua message from 'inbox'
		local playerID=msgRecv[bufferIndex].playerID
		local msg=msgRecv[bufferIndex].msg
		msgRecv[bufferIndex]=nil
		bufferIndex=bufferIndex-1
		
		if (msg:sub(1,4) == msgID) then --if message belong to hello/hi file transfer protocol
			destinationID=tonumber(msg:sub(7,8))
			local myAvatar = avatars[myPlayerName]
			
			if openPortForID==playerID and destinationID==myPlayerID and not lineIsBusy then
				if msg:sub(5,5)==hi then --receive hi from target playerID
					if myPlayerID>playerID then --if I am 'low ranking' playerID then replied yes
						--reply with yes
						Spring.SendLuaUIMsg(msgID .. yes .. openPortForID+100)
						waitForTransmission=true
						local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg
					end
				elseif msg:sub(5,5)==yes then --received yes
					Spring.SendLuaUIMsg(msgID .. checksumA .. openPortForID+100 .. "x" .. myAvatar.checksum) --send checksum, "x" is payload request flag (not available)
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg
				elseif msg:sub(5,5)==checksumA then --receive checksum
					local checksum = tonumber(msg:sub(10))					
					local playerName = Spring.GetPlayerInfo(playerID)
					local avatarInfo = avatars[playerName]
					local payloadRequestFlag=0
					if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
						local file = SearchFileByChecksum(checksum)
						if (file) then
							--// already downloaded it once, reuse it
							SetAvatar(playerName,file,checksum)
							checklistTable[(playerID+1)].downloaded=true --tick 'done' on file downloaded
						else
							payloadRequestFlag=1
						end
					end
					Spring.SendLuaUIMsg(msgID .. checksumB .. openPortForID+100 .. payloadRequestFlag .. myAvatar.checksum) --send checksum
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg
				elseif msg:sub(5,5)==checksumB then --receive checksum
					local checksum = tonumber(msg:sub(10))
					local playerName = Spring.GetPlayerInfo(playerID)
					local avatarInfo = avatars[playerName]
					local payloadRequestFlag=0
					if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
						local file = SearchFileByChecksum(checksum)
						if (file) then
							--// already downloaded it once, reuse it
							SetAvatar(playerName,file,checksum)
							checklistTable[(playerID+1)].downloaded=true --tick 'done' on file downloaded
						else
							payloadRequestFlag=1
						end
					end
					local myAvatar = avatars[myPlayerName]
					if (msg:sub(9,9)=="1") then --payload request by remote computer
						local cdata = VFS.LoadFile(myAvatar.file)
						local filename = ExtractFileName(myAvatar.file)
						Spring.SendLuaUIMsg(msgID .. payloadA .. openPortForID+100 .. payloadRequestFlag .. "1" .. filename .. '$' .. cdata) --send payload, "1" is payload flag
					else
						if payloadRequestFlag~=0 then 
							Spring.SendLuaUIMsg(msgID .. payloadA .. openPortForID+100 .. payloadRequestFlag .. "0") --send "payload package" without payload
						else 	
							Spring.SendLuaUIMsg(msgID .. bye .. openPortForID+100) --skip next protocol if both player don't need payload
							waitForTransmission=false
						end
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg
				elseif msg:sub(5,5)==payloadA then
					if (msg:sub(10,10)=="1") then --payload "is here!" flag
						msg = msg:sub(11)
						local endOfFilename = msg:find('$',1,true)
						local filename = msg:sub(1,endOfFilename-1)
						local cdata    = msg:sub(endOfFilename+1)
						
						local image      = cdata
						local checksum   = CalcChecksum(image)
						checklistTable[(playerID+1)].downloaded=true --tick 'done' on file downloaded

						local playerName = Spring.GetPlayerInfo(playerID)
						local avatarInfo = avatars[playerName]

						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
							local filename = SaveToFile(filename, image, checksum)
							SetAvatar(playerName,filename,checksum)
						end
					end
					if (msg:sub(9,9)=="1") then --remote client's payloadRequestFlag
						local cdata = VFS.LoadFile(myAvatar.file)
						local filename = ExtractFileName(myAvatar.file)
						Spring.SendLuaUIMsg(msgID .. payloadB .. openPortForID+100 .. "x" .. "1" .. filename .. '$' .. cdata) --send payload,"x" is payload request flag(unavailable), "1" is payload flag
					else
						Spring.SendLuaUIMsg(msgID .. payloadB .. openPortForID+100 .. "x" .. "0") --send "payload package" without payload
					end
					local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
					waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg				
				elseif (msg:sub(5,5)==payloadB) then
					if (msg:sub(10,10)=="1") then --payload "is here!" flag
						msg = msg:sub(11)
						local endOfFilename = msg:find('$',1,true)
						local filename = msg:sub(1,endOfFilename-1)
						local cdata    = msg:sub(endOfFilename+1)					

						local image      = cdata
						local checksum   = CalcChecksum(image)
						checklistTable[(playerID+1)].downloaded=true --tick 'done' on file downloaded

						local playerName = Spring.GetPlayerInfo(playerID)
						local avatarInfo = avatars[playerName]

						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
							local filename = SaveToFile(filename, image, checksum)
							SetAvatar(playerName,filename,checksum)
						end
					end
					Spring.SendLuaUIMsg(msgID .. bye .. openPortForID+100)
					waitForTransmission=false
				elseif (msg:sub(5,5)==bye) then
					waitForTransmission=false
				end
			elseif myPlayerID==destinationID then
				if msg:sub(5,5)==hi then --receive hi from someone who target you
					if myPlayerID>playerID or tableIsCompleted then --if I am the'low ranking' playerID then reply yes, else don't (high rank will not answer to low ranking unless has no work to do)
						--reply with yes
						openPortForID=playerID
						waitForTransmission=true --turn of "hi" sending
						local totalNetworkDelay= retrieveTotalNetworkDelay(myPlayerID, playerID)
						waitTransmissionUntilThisTime=currentTime + (totalNetworkDelay)*1.1 --suspend "hi" sending until next reply msg				
						Spring.SendLuaUIMsg(msgID .. yes .. openPortForID+100)
					end 
				end
			elseif myPlayerID~=destinationID then --if noise (if not my message)
				if msg:sub(5,5)==yes then --listen hi from someone to someone else
					if myPlayerID>playerID then --if they are the 'higher ranking' playerID (close your own connection for high ranking player (players with low playerID))
						lineIsBusy=true --assume they took command of the communication medium, close all protocol/cancel ongoing protocol. lineBusy always triggered by high ranking noise
						waitForTransmission=true
						local totalNetworkDelay= retrieveTotalNetworkDelay(destinationID, playerID)
						waitBusyUntilThisTime=currentTime + (totalNetworkDelay)*2.6
						waitTransmissionUntilThisTime=currentTime + (aTargetPingTime+bTargetPingTime)*2.6 --wait until it end
					end 
				elseif (msg:sub(5,5)==payloadB or msg:sub(5,5)==payloadA) then --snif package transfer and save for our own
					if (msg:sub(10,10)=="1") then --payload "is here!" flag
						msg = msg:sub(11)
						local endOfFilename = msg:find('$',1,true)
						local filename = msg:sub(1,endOfFilename-1)
						local cdata    = msg:sub(endOfFilename+1)

						local image      = cdata
						local checksum   = CalcChecksum(image)
						local playerName = Spring.GetPlayerInfo(playerID)
						local avatarInfo = avatars[playerName]

						if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
							local filename = SaveToFile(filename, image, checksum)
							SetAvatar(playerName,filename,checksum)
							checklistTable[(playerID+1)].downloaded=true --mark checklist as complete
						end
					end
				elseif msg:sub(5,5)==checksumA or msg:sub(5,5)==checksumB then --snif checksum transfer and save it for our own
					local checksum = tonumber(msg:sub(10))
					local playerName = Spring.GetPlayerInfo(playerID)
					local avatarInfo = avatars[playerName]
					if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then --check if we have record of this player
						local file = SearchFileByChecksum(checksum)
						if (file) then
							--// already downloaded it once, reuse it
							SetAvatar(playerName,file,checksum)
							checklistTable[(playerID+1)].downloaded=true
						else
							checklistTable[(playerID+1)].retry=0 --if we have no file yet, but heard this broadcast then reset retry count to continue trying to reach this playerID
							tableIsCompleted=false --recheck checklist
						end
					end
				elseif (msg:sub(5,5)==bye) then
					lineIsBusy=false
					waitForTransmission=false
				end
			end
		elseif (msg:sub(1,4) == broadcastID) then --if message is a 'look at my new pic!'.
			checklistTable[(playerID+1)].downloaded=false --reset checklist entry for this player
			checklistTable[(playerID+1)].retry=0 --reset retry
			tableIsCompleted=false --redo checklist check
		end
	end
end

function retrieveTotalNetworkDelay(playerIDa, playerIDb)
	local _,_,_,_,_,aTargetPingTime,_,_,_,_= Spring.GetPlayerInfo(playerIDa)
	local _,_,_,_,_,bTargetPingTime,_,_,_,_= Spring.GetPlayerInfo(playerIDb)
	local totalDelay= aTargetPingTime+bTargetPingTime
	if totalDelay>=2 then return 2 
	else return totalDelay
	end
end

function widget:RecvLuaMsg(msg, playerID) --each update will put message into "msgRecv"
	bufferIndex=bufferIndex+1
	msgRecv[bufferIndex]={msg=msg, playerID=playerID}
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
	playerIDlist=Spring.GetPlayerList()
	--Spring.Echo(playerIDlist)	
	
	--use playerIDlist to update checklist
	local iteration =1
	local playerID=-1
	while iteration <= #playerIDlist do --update checklist with appropriate value
		playerID=playerIDlist[iteration]
		if checklistTable[(playerID+1)]==nil then 
			checklistTable[(playerID+1)]={downloaded=false, retry=0, ignore=false} --add empty entry with new value
		else 
			checklistTable[(playerID+1)].ignore=false --reset previous ignore list
			checklistTable[(playerID+1)].retry=0 --reset retry counter
		end
		--the following add ignore flag to selective playerID
		local _,playerIsActive,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator or not playerIsActive then --ignore non-specs and inactive player(don't send hi/request file)
				checklistTable[(playerID+1)].ignore=true 
			end
		else --if I am not spectator
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator or not playerIsActive then --if player is the enemy or a spec then
				checklistTable[(playerID+1)].ignore=true --ignore enemy & spec and inactive player(don't send hi/request file)
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
	myPlayerID=Spring.GetMyPlayerID()
	local name,_,iAmSpectator,_,allyTeamID,_,_,_,_,customKeys = Spring.GetPlayerInfo(myPlayerID)
	myPlayerName =name
	myAllyTeamID=allyTeamID
	
	--get all playerID list
	playerIDlist=Spring.GetPlayerList()
	--Spring.Echo(playerIDlist)
	avatars = (VFS.FileExists(configFile) and VFS.Include(configFile)) or {}

	--use player list to build checklist
	local iteration =1
	local playerID=-1
	while iteration <= #playerIDlist do --fill checklist with initial value
		playerID=playerIDlist[iteration]
		checklistTable[(playerID+1)]={downloaded=false, retry=0, ignore=false} --fill checklist with default values (promote communication)
		--the following add ignore flag to selective playerID
		local _,_,playerIsSpectator,_,playerAllyTeamID,_,_,_,_,_ = Spring.GetPlayerInfo(playerID)
		if iAmSpectator then --if I am spectator then
			if not playerIsSpectator then --ignore non-specs (don't send hi/request file)
				checklistTable[(playerID+1)].ignore=true 
			end
		else --if I am not spectator
			if myAllyTeamID~=playerAllyTeamID or playerIsSpectator then --if player is enemy or spec then
				checklistTable[(playerID+1)].ignore=true --ignore enemy & spec (don't send hi/request file)
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
	
	--initialize locally assigned avatar if available
	if (avatars[myPlayerName]~=nil) then
		if VFS.FileExists(avatars[myPlayerName].file) then --if selected file exist then use it
			myAvatar.file=avatars[myPlayerName].file
			myAvatar.checksum=avatars[myPlayerName].checksum
		--if we don't have the selective avatar then fallback remains
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
--gui_ally_cursors.lua , author: jK
--gui_chili_crudeplayerlist.lua, author: CarRepairer, +KingRaptor
--cawidgets.lua, author: Dave Rodgers, +jk, quantum, KingRaptor
