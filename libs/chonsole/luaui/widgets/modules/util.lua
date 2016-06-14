function string.trimLeft(str)
	return str:gsub("^%s*(.-)", "%1")
end

function string.trim(str)
	return str:gsub("^%s*(.-)%s*$", "%1")
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function ExtractDir(filepath)
	filepath = filepath:gsub("\\", "/")
	local lastChar = filepath:sub(-1)
	if (lastChar == "/") then
		filepath = filepath:sub(1,-2)
	end
	local pos,b,e,match,init,n = 1,1,1,1,0,0
	repeat
		pos,init,n = b,init+1,n+1
		b,init,match = filepath:find("/",init,true)
	until (not b)
	if (n==1) then
		return filepath
	else
		return filepath:sub(1,pos)
	end
end

function ExtractFileName(filepath)
	filepath = filepath:gsub("\\", "/")
	local lastChar = filepath:sub(-1)
	if (lastChar == "/") then
		filepath = filepath:sub(1,-2)
	end
	local pos,b,e,match,init,n = 1,1,1,1,0,0
	repeat
		pos,init,n = b,init+1,n+1
		b,init,match = filepath:find("/",init,true)
	until (not b)
	if (n==1) then
		return filepath
	else
		return filepath:sub(pos+1)
	end
end

function explode(div,str)
	if (div=='') then return 
		false 
	end
	local pos,arr = 0,{}
	-- for each divider found
	for st,sp in function() return string.find(str,div,pos,true) end do
		table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
	return arr
end
