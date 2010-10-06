--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Load CA's effects from ./effects and not ./gamedata/explosions
--

local luaFiles = VFS.DirList('effects', '*.lua')

for _, filename in ipairs(luaFiles) do
  local edEnv = {}
  edEnv._G = edEnv
  edEnv.Shared = Shared
  edEnv.GetFilename = function() return filename end
  setmetatable(edEnv, { __index = system })
  local success, eds = pcall(VFS.Include, filename, edEnv)
  if (not success) then
    Spring.Echo('Error parsing ' .. filename .. ': ' .. eds)
  elseif (eds == nil) then
    Spring.Echo('Missing return table from: ' .. filename)
  else
    for edName, ed in pairs(eds) do
      if ((type(edName) == 'string') and (type(ed) == 'table')) then
        ed.filename = filename
        ExplosionDefs[edName] = ed
      end
    end
  end  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
