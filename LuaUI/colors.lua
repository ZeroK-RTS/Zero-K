--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    colors.lua
--  brief:   color strings (Spring format) and color arrays
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

ResetColorStr = "\008"
WhiteStr      = "\255\255\255\255";    function GetWhiteStr   (str) return WhiteStr   .. str .. ResetColorStr end
BlackStr      = "\255\001\001\001";    function GetBlackStr   (str) return BlackStr   .. str .. ResetColorStr end
GreyStr       = "\255\128\128\128";    function GetGreyStr    (str) return GreyStr    .. str .. ResetColorStr end
RedStr        = "\255\255\001\001";    function GetRedStr     (str) return RedStr     .. str .. ResetColorStr end
PinkStr       = "\255\255\123\128";    function GetPinkStr    (str) return PinkStr    .. str .. ResetColorStr end
GreenStr      = "\255\001\255\001";    function GetGreenStr   (str) return GreenStr   .. str .. ResetColorStr end
BlueStr       = "\255\001\001\255";    function GetBlueStr    (str) return BlueStr    .. str .. ResetColorStr end
CyanStr       = "\255\001\255\255";    function GetCyanStr    (str) return CyanStr    .. str .. ResetColorStr end
YellowStr     = "\255\255\255\001";    function GetYellowStr  (str) return YellowStr  .. str .. ResetColorStr end
MagentaStr    = "\255\255\001\255";    function GetMagentaStr (str) return MagentaStr .. str .. ResetColorStr end

Colors = {}
Colors.white   = { 1.0, 1.0, 1.0, 1.0 }
Colors.black   = { 0.0, 0.0, 0.0, 1.0 }
Colors.grey    = { 0.5, 0.5, 0.5, 1.0 }
Colors.red     = { 1.0, 0.0, 0.0, 1.0 }
Colors.green   = { 0.0, 1.0, 0.0, 1.0 }
Colors.blue    = { 0.0, 0.0, 1.0, 1.0 }
Colors.yellow  = { 1.0, 1.0, 0.0, 1.0 }
Colors.cyan    = { 0.0, 1.0, 1.0, 1.0 }
Colors.magenta = { 1.0, 0.0, 1.0, 1.0 }
