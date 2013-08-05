local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'

local JSON = require 'cjson'
local md5 = require 'md5'

-- print(arg[0])
print(arg[1])
-- print(arg[2])
function datetime (t)
	return os.date("%Y%m%d", os.time() + 24 * 60 * 60 * t)
end

--[[
-- Get the mission.(org/dst/t)
local org = string.sub(arg[1], 1, 3);
local dst = string.sub(arg[1], 5, 7);
local t = string.sub(arg[1], 9, -2);
print(org)
print(dst)
print(t)

--]]

local file = io.open("/data/rails2.3.5/biyifei/agent/config.json", "r");
local content = file:read("*all");
file:close();
local j = string.gsub(content,'\"([^\"]-)\":','%1=')
local t, c, d = string.gsub(j,'%b\[\]','')
print(t, c, d)
if c ~= 0 then
	print(content)
end

function json(json)
	local j=string.gsub(json,'\"([^\"]-)\":','%1=')
	local j=string.gsub(j,'%b\[\]','')
	local j='t='..j
	-- loadstring(j)()
	return t
end


local tmprandom = math.random(8001,9999);
print(tmprandom)
