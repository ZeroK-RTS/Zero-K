--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
 
function widget:GetInfo()
  return {
    name      = "Avatars (unstable)",
    desc      = "An API for a per-user avatar-icon system.",
    author    = "jK",
    date      = "2009",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    api       = false,
    enabled   = false
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local avatars = {}

local MsgID       = "%"
local ChecksumMsg = MsgID .. "1"
local RequestMsg  = MsgID .. "2"
local DataMsg     = MsgID .. "3"

local maxFileSize = 10 --in kB

local alreadySent = false

local configFile = "LuaUI/Configs/avatars.lua"
local avatarsDir = "LuaUI/Configs/Avatars/"
local avatar_fallback = avatarsDir .. "Crystal_personal.png"

local myPlayerName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CalcChecksum(data)
	local bytes = VFS.UnpackU32(data,nil,data:len()/4)
	local checksum = math.bit_xor(0,unpack(bytes))
	return checksum
end


local function SaveToFile(filename, data, hash)
	local file = avatarsDir .. hash .. '_' .. filename

	Spring.CreateDir(avatarsDir)
	local out = assert(io.open(file, "wb"))
	out:write(data)
	assert(out:close())

	return file
end


local function SearchFileByChecksum(checksum)
	local files = VFS.DirList(avatarsDir)
	for i=1,#files do
		local file = files[i]
		  local data = VFS.LoadFile(file)
		if (data:len()/1024 < maxFileSize) then  
      local file_checksum = CalcChecksum(data)

        if (file_checksum == checksum) then
           return file
        end
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
	return (avInfo and avInfo.file) or avatar_fallback
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
		return
	end

	local data = VFS.LoadFile(filename)

	if (data:len()/1024 > maxFileSize) then
		error('Avatar: selected image file is too large (sizelimit is' .. maxFileSize .. 'kB)')
		return
	end

	local checksum = CalcChecksum(data)
	SetAvatar(myPlayerName,filename,checksum)
	Spring.SendLuaUIMsg(ChecksumMsg .. checksum)
	alreadySent = false
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

	Chili.Button:New{
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
--global variable. Store receive list and clearing time
local spGetGameSeconds = Spring.GetGameSeconds
local receiveList = {}
local lastClearingTime = -100

function widget:RecvLuaMsg(msg, playerID)
	if (msg:sub(1,1) ~= MsgID) then
		return;
	end

	if (playerID == Spring.GetMyPlayerID()) then
		return;
	end
   
  --empty receive list every 1 second. Allow sender to re-send request if previous respond fail  
  local now = spGetGameSeconds()
  if now >= 1 +lastClearingTime then
    receiveList[playerID]=-100
    lastClearingTime=now
  end

  --check msg with receive list. Allow the whole function to skip if it receive duplicate content    
  if receiveList[playerID]~=msg then
    receiveList[playerID]=msg
  else return; end

	if (msg:sub(1,2) == ChecksumMsg) then
		--// check other's checksums
		--// if we don't have an icon or if it got changed send a request
		local checksum = tonumber(msg:sub(3))
		local playerName = Spring.GetPlayerInfo(playerID)

		local avatarInfo = avatars[playerName]

		if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
			local file = SearchFileByChecksum(checksum)

			if (file) then
				--// already downloaded it once, reuse it
				SetAvatar(playerName,file,checksum)
			else
				Spring.SendLuaUIMsg(RequestMsg .. playerID)
			end
		end
	elseif (msg:sub(1,2) == RequestMsg) then
		--// somone doesn't have our icon, so compress and send it
		--if (not alreadySent) then
			local myAvatar = avatars[myPlayerName]
			if (myAvatar) then
				local cdata = VFS.ZlibCompress(VFS.LoadFile(myAvatar.file))
				local filename = ExtractFileName(myAvatar.file)

				Spring.SendLuaUIMsg(DataMsg .. filename .. '$' .. cdata)
				--alreadySent = true
			end
		--end
	elseif (msg:sub(1,2) == DataMsg) then
		--// received an icon, save it to disk
		msg = msg:sub(3)
		local endOfFilename = msg:find('$',1,true)
		local filename = msg:sub(1,endOfFilename-1)
		local cdata    = msg:sub(endOfFilename+1)

		local image      = VFS.ZlibDecompress(cdata)
		local checksum   = CalcChecksum(image)

		local playerName = Spring.GetPlayerInfo(playerID)
		local avatarInfo = avatars[playerName]

		if (not avatarInfo)or(avatarInfo.checksum ~= checksum) then
			local filename = SaveToFile(filename, image, checksum)
			SetAvatar(playerName,filename,checksum)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	avatars = (VFS.FileExists(configFile) and VFS.Include(configFile)) or {}

	--// remove broken entries
	for playerName,avInfo in pairs(avatars) do
		if (not VFS.FileExists(avInfo.file)) then
			avatars[playerName] = nil
		end
	end

	
	--// send my avatar checksum to all players (so they can request a download if needed)
	local myAvatar = avatars[myPlayerName]

	local name,active,spectator,_,allyTeamID,pingTime,cpuUsage,country,rank, customKeys = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	
	if (customKeys ~= nil and customKeys.avatar~=nil) then 
		myAvatar = { file = "LuaUI/Configs/Avatars/" .. customKeys.avatar .. ".png"}
		
	end 

	
	if (myAvatar) then
		myAvatar.checksum = CalcChecksum(VFS.LoadFile(myAvatar.file))
		Spring.SendLuaUIMsg(ChecksumMsg .. myAvatar.checksum)
		SetAvatar(name, myAvatar.file, myAvatar.checksum)
	end

	WG.Avatar = {
		GetAvatar   = GetAvatar;
		SetMyAvatar = SetMyAvatar;
	}

	widgetHandler:AddAction("setavatar", SetAvatarGUI, nil, "t");
end

function widget:Shutdown()
	table.save(avatars, configFile)

	WG.Avatar = nil
	widgetHandler:RemoveAction("setavatar");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
