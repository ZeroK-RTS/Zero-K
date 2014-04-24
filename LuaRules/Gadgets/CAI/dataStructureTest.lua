
local returnedStructure = {
	aVariable = 3,
}

function returnedStructure.CreateImportantObject(count)

	local listOfThings = {}
	for i = 1, count do
		listOfThings[i] = i
	end
	
	local multiplyNumber = 2
	
	function SetMultiply(n)
		multiplyNumber = n
	end
	
	function DoMultiply()
		for i = 1, count do
			listOfThings[i] = multiplyNumber*listOfThings[i]
		end
	end
	
	function GetSum()
		local sum = 0
		for i = 1, count do
			sum = sum + listOfThings[i]
		end
		return sum
	end
	

	local importantObject = {
		listOfThings = listOfThings,
		SetMultiply = SetMultiply,
		DoMultiply = DoMultiply,
		GetSum = GetSum,
	}
	
	return importantObject
end

return returnedStructure