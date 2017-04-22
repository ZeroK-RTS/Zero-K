function Spring.Utilities.Traceback(condition)
	if condition then
		Spring.Echo(debug.traceback())
	end
end
