--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Load CA's effects from ./effects and not ./gamedata/explosions
--

local luaFiles = VFS.DirList('effects', '*.lua', '*.tdf')
--couldn't be arsed to convert to lua since there is no real benefit for CEG's -Zement/DOT

for _, filename in ipairs(luaFiles) do
  local edEnv = {}
  edEnv._G = edEnv
  edEnv.Shared = Shared
  edEnv.GetFilename = function() return filename end
  setmetatable(edEnv, { __index = system })
  local success, eds = pcall(VFS.Include, filename, edEnv)
  if (not success) then
    Spring.Log("explosions_post.lua", "error", 'Error parsing ' .. filename .. ': ' .. eds)
  elseif (eds == nil) then
    Spring.Log("explosions_post.lua", "error", 'Missing return table from: ' .. filename)
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
