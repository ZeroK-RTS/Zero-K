Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.GetEngineVersion()
	return (Game and Game.version) or (Engine and Engine.version) or "Engine version error"
end

function Spring.Utilities.IsCurrentVersionNewerThan(rel, dev)
	Spring.Echo("`Spring.Utilities.IsCurrentVersionNewerThan()` is deprecated, please use `Script.IsEngineMinVersion()` instead. Note that for 105-bla and earlier, the minor is always 0, i.e. `IsCurrentVersionNewerThan(105, 1234)` translates to `IsEngineMinVersion(105, 0, 1234)`")
	return true
end
