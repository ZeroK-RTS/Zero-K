function widget:GetInfo()
    return {
      name      = "In-game Ignore",
      desc      = "Adds ignore/unignore commands.",
      author    = "_Shaman",
      date      = "8-1-2016",
      license   = "Apply as needed v9",
      layer     = 0,
      enabled   = true,
    }
end

local function ProcessString(str)
  local strtbl = {}
  for w in string.gmatch(str, "%S+") do
	strtbl[#strtbl+1] = w
  end
  return strtbl
end

if VFS.FileExists("ignorelist.lua") then
  WG.IgnoreList = VFS.Include("ignorelist.lua")
else
  WG.IgnoreList = {}
end

if VFS.FileExists("ZeroKLobbyConfig.xml") then -- load ignore list from ZKL config
  Spring.Echo("Ignorelist: Found ZKL Config. Loading ZKL ignore list.")
  local file = VFS.LoadFile("ZeroKLobbyConfig.xml")
  local beginof = string.find(file,"<IgnoredUsers>") + 15
  local endof = string.find(file,"</IgnoredUsers>") -1
  local ignorelist = string.sub(file,beginof,endof)
  ignorelist = string.gsub(ignorelist,"\n","~")
  ignorelist = string.gsub(ignorelist,"%s","")
  ignorelist = string.gsub(ignorelist,"string>","")
  ignorelist = string.gsub(ignorelist,"<","")
  ignroelist = string.gsub(ignorelist,"/","")
  ignorelist = string.gsub(ignorelist,"~"," ")
  --Spring.Echo("Ignore: " .. ignorelist)
  local names = ProcessString(ignorelist)
  for i=1,#names do
    --Spring.Echo("Ignore: found " .. names[i])
    WG.IgnoreList[names[i]] = true
  end
  file,beginof,endof,ignorelist,names = nil
end

function widget:Initialize()
  for name,_ in pairs(WG.IgnoreList) do
    widgetHandler:Ignore(name)
  end
end

function widget:TextCommand(command)
  local prcmd = ProcessString(command)
  if string.lower(prcmd[1]) == "ignore" then
    if prcmd[2] then
      Spring.Echo("game_message: Ignoring " .. prcmd[2])
      widgetHandler:Ignore(prcmd[2])
    end
  end
  if string.lower(prcmd[1]) == "ignorelist" then
    ignorestring = "game_message: You are ignoring the following users:"
    for name,_ in pairs(WG.IgnoreList) do
      ignorestring = ignorestring .. "\n-" .. name
    end
    Spring.Echo(ignorestring)
  end
  if string.lower(prcmd[1]) == "unignore" then
    if prcmd[2] and WG.IgnoreList[prcmd[2]] then
      Spring.Echo("game_message: Unignoring " .. prcmd[2])
      widgetHandler:Unignore(prcmd[2])
      WG.IgnoreList[prcmd[2]] = nil
    end
  end
end

function widget:Shutdown()
  if WG.IgnoreList then
    table.save(WG.IgnoreList,"ignorelist.lua")
  end
end
