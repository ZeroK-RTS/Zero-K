--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Load all models",
    desc      = "Loads all models",
    author    = "GoogleFrog",
    date      = "28 November 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--for i = 1, #UnitDefs do
--	local ud = UnitDefs[i]
--	local radius = ud.radius
--	local height = ud.height
--	Spring.Echo("load all models", i, radius, height)
--end
