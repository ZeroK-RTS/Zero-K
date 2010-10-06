-- $Id: cob_buttons.lua 4020 2009-03-05 02:11:33Z licho $
return {
  armmav = {
    {cob = "BeginJump"},
    {cob = "EndJump"},
  },
  -- core_slicer = {
    -- {
      -- name     = "Sprint",
      -- tooltip  = "Charge!",
      -- cob      = "StartSprint",  -- only this is required
      -- endcob   = "StopSprint",  -- called at the end of duration
      -- reload   = 20,   -- button is disabled until the reload time has passed
      -- duration = 5,
      -- position = 500,              
    -- },
  -- },
  armfast = {
	{
	  name     = "Sprint",
	  tooltip  = "Sprint",
	  cob      = "StartSprint",
	  endcob   = "StopSprint",
	  reload   = 50,
	  duration = 16,
	  position = 500,
	},
  },
}