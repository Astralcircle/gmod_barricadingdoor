local paths = {}

local _, folders = file.Find("bar_door/*","LUA")
table.sort(folders, function(a,b) return tonumber(a) < tonumber(b) end)
for k,v in ipairs(folders) do
	paths[#paths+1] = "bar_door/"..v.."/"
end
paths[#paths+1] = "bar_door/"

for k,v in ipairs(paths) do
	for k2,v2 in ipairs(file.Find(v.."*","LUA")) do
		AddCSLuaFile(v..v2)
		include(v..v2)
	end
end
