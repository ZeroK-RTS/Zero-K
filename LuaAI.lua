-- $Id: LuaAI.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  LuaAI.lua
--
--    List of LuaAIs supported by the mod.
--
--

return {
  {
	-- to be recognised as a CAI there must be an entry with this name in
	-- LuaRules\Configs\cai\configCoordinator.lua
    name = 'CAI',
    desc = 'AI that plays regular Zero-K'
  },
  --{
  --  name = 'CAI2',
  --  desc = 'Another AI that plays regular Zero-K'
  --},
  {
    name = 'Chicken: Beginner',
    desc = 'For PvE in PvP games'
  },
  {
    name = 'Chicken: Very Easy',
    desc = 'For PvE in PvP games'
  },
  {
    name = 'Chicken: Easy',
    desc = 'Ice cold'
  },
  {
    name = 'Chicken: Normal',
    desc = 'Lukewarm'
  },
  {
    name = 'Chicken: Hard',
    desc = 'Will burn your ass'
  },
  {
    name = 'Chicken: Suicidal',
    desc = 'Flaming hell!'
  },
  {
    name = 'Chicken: Custom',
    desc = 'A chicken experience customizable using modoptions'
  },
  {
	name ='Null AI',
	desc = 'Empty AI for testing purposes'
  }
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
