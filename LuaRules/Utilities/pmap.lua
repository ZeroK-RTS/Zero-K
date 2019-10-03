--[[
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]--

--[[
        This is a piece of code trying to mimic standard priority queue (pqueue) interface.
        Since it has quite different implementation to usual pqueue ones (binary heap, fibonacci heap) it's called pmap,
        which stands for Priority Map. pmap has following properties:
                0. It's a (key, value) storage, capable of sorting pairs based on key
                0a. Map is online-sorted. One can supply own comparison function in the class constructor
				0b. Keys must be unique. Attempts to Insert() duplicate key will be asserted. To update the existing key use Upsert()
                1. Insert() is a slow operation worst case. It may require up-to n comparison and swaps.
                1a. Insert() is fast if inserting value's place is nearby the end of Map.
                        For instance for ascending sort order, inserting value bigger than currently present in the pmap is very fast (one comparison needed and no swaps)
				2. Upsert() either Insert() k,v pair if key is new or update "k" with new "v". This function should never fail or throw assertion failure
                3. Get() is as fast as three hash lookups. It should be quite fast practically.
                4. FrontTrim() - removing the first element from map (either min or max, depending on the sort order) is ultra fast. It's as fast as incrementing the counter and setting one hash value to nil
                5. Iteration could  be done via ipairs() or via GetIdxs/GetKV.
        Key differences from heap-based implementation are:
                1. Insert could be slower, but if inserting value is "almost sorted" it should be faster
                2. Get() and FrontTrim() are faster, because map is stored in sorted form and there is no need to rebalance trees.
                3. Iteration is fast, while heap-based implementation often doesn't have iteration at all
        Use case for this class would be:
                1. Relative small amount of insertions compared to iterations/value retrievals
                2. Insertions come in almost sorted order.
                3. There is a need for frequent & cheap iteration
                4. Elements get removed one by one and from front of the map only

                Should be ideal for sliding window-like application, when next elements though come slightly out of order

        //Author: ivand (lhog)
]]--

local function f_min(a,b) return a < b end

local function new(class, comp)
  return setmetatable(
  {
        comp = comp or f_min,
        kv={},
        kvEnd=0,
        kvStart=1,
        invKey={}
  }, class)
end

local pmap = setmetatable({}, {__call = function(self,...) return new(self,...) end})
pmap.__index = pmap

--- Main Functions ---
function pmap:Insert(k,v)
        assert(self.invKey[k]==nil)
        self.kvEnd=self.kvEnd+1
        self.kv[self.kvEnd]={k, v}
        self.invKey[k]=self.kvEnd
        local comp=self.comp
        for i=self.kvEnd, 1+self.kvStart, -1 do
                if comp(self.kv[i][1], self.kv[i-1][1]) then
                        --make swap for kv[]
                        local tmp=self.kv[i]
                        self.kv[i]=self.kv[i-1]
                        self.kv[i-1]=tmp
                        self.invKey[self.kv[i][1]]=i
                        self.invKey[self.kv[i-1][1]]=i-1
                else
                        break
                end
        end
end

function pmap:Upsert(k, v) --insert or update key with value
        local idx=self.invKey[k]
        if idx then
                self.kv[idx]={k, v}
                return
        end
        return self:Insert(k,v)
end

function pmap:Get(k)
        local idx=self.invKey[k]
                if idx~=nil then
                        return self.kv[idx][2]
                else
                        return nil

                end
end

function pmap:GetKV(idx)
        if (self.kvStart<=idx) and (idx<=self.kvEnd) then
                return self.kv[idx]
        else
                return nil
        end
end

function pmap:FrontTrim()
        local idx=self.kvStart
        local k=self.kv[idx][1]
        self.kv[idx]=nil
        self.invKey[k]=nil
        self.kvStart=self.kvStart+1
        --just shift starting array index
end

pmap.TrimFront=pmap.FrontTrim

--- /Main Functions ---


--- Iteration ---

local function iter (t, i)
        i = i + 1
        local v = t[i]
        if v then
                return i, v
        end
end

function pmap:ipairs()
        return iter, self.kv, self.kvStart-1
end

function pmap:GetIdxs()
        return self.kvStart, self.kvEnd
end

function pmap:First()
	return self.kv[self.kvStart]
end

function pmap:Last()
	return self.kv[self.kvEnd]
end

--- /Iteration ---

--------------
return pmap
--------------


-- test and use examples
--[[
pmap=require "pmap"
pa=pmap()
pa:Insert(10,"10")
pa:Insert(15,"15")
pa:Insert(5,"5")
pa:Insert(20,"20")
pa:Insert(30,"30")
for k,v in pairs(pa.kv) do print (k,unpack(v)) end
for k,v in pairs(pa.invKey) do print (k,v) end
pa:FrontTrim()
for k,v in pairs(pa.kv) do print (k,unpack(v)) end
for k,v in pairs(pa.invKey) do print (k,v) end
pa:Insert(5,"5")
for k,v in pairs(pa.kv) do print (k,unpack(v)) end
for k,v in pairs(pa.invKey) do print (k,v) end
pa:Upsert(5,"25")
print(pa:Get(5))


for i, kv in pa:ipairs() do
        print(unpack(kv))
end

s,e=pa:GetIdxs()
for i=s,e do
    print(unpack(pa:GetKV(i)))
end
]]--
