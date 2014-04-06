local tbl = {
  corbtrans = {
    {class='AirJet', options={color={0.2,0.4,0.8}, width=8, length=35, piece="engineEmit", onActive=true}},
  },
  corape = {
    {class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=22, piece="thrust1", onActive=true}},
    {class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=22, piece="thrust2", onActive=true}},
  },
  fighter = {
    --{class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=55, piece="nozzle1", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true}},
    --{class='AirJet', options={color={0.6,0.1,0.0}, width=3.5, length=55, piece="nozzle2", texture2=":c:bitmaps/gpl/lups/jet2.bmp", onActive=true}},
  },
}
local tbl2 = {}

for unitName, data in pairs(tbl) do
  local unitDef = UnitDefNames[unitName] or {}
  data.baseSpeed = data.baseSpeed or (unitDef and unitDef.speed/30)
  data.maxDeltaSpeed = data.maxDeltaSpeed or 3
  data.accelMod = data.accelMod or 1
  data.minSpeed = data.minSpeed or 1
  for index, fx in ipairs(data) do
    local opts = fx.options
    if opts.length then
      opts.baseLength = opts.length
    end
    if opts.size then
      opts.baseSize = opts.size
    end
  end
  
  local unitDefID = unitDef.id
  if unitDefID then
    tbl2[unitDefID] = data
  end
end

return tbl2