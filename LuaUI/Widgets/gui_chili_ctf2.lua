--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local version = "0.1.2" -- you may find changelog in capture_the_flag.lua gadget

function widget:GetInfo()
  return {
    name      = "Chili CTF GUI (part 2)",
    desc      = "GUI for Capture The Flag game mode. Version: "..version,
    author    = "Tom Fyuri",
    date      = "Feb 2014",
    license   = "GPL v2 or later",
    layer     = -1, 
    handler   = true, -- for adding customCommand into UI
    enabled   = true  -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_DROP_FLAG = 35300

local cmdDropflag = {
  id      = CMD_DROP_FLAG,
  type    = CMDTYPE.ICON,
  tooltip = 'Drop flag on the ground.',
  cursor  = 'Attack',
  action  = 'dropflag',
  params  = { }, 
  texture = 'LuaUI/Images/commands/Bold/drop_flag.png',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandsChanged()
  local selectedUnits = Spring.GetSelectedUnits()
  local customCommands = widgetHandler.customCommands
--   for _, unitID in ipairs(selectedUnits) do
  local unitID = Spring.GetSelectedUnits()[1]
    if (unitID) then
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if ud and ud.canMove and not(ud.canFly) then --Note: canMove include factory
      table.insert(customCommands, cmdDropflag)
      return
    end
  end 
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  local ctf = (Spring.GetModOptions().zkmode) == "ctf"
  
  if (ctf == false) then
    widgetHandler:RemoveWidget()
    return
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------