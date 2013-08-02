-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for elong website : http://flight.elong.com/beijing-shanghai/cn_day19.html
-- load library
local JSON = require("cjson");
local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- local ltn12 = require "ltn12"

-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get task from Queues is no result"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end

-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- nosql connect
local ok, err = red:connect("127.0.0.1", 6388)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.
if ngx.var.request_method == "GET" then
	local task = {};
	local check = false;
	local resnum = 0;
	for n = 1, ngx.var.num do
		local res, err = red:blpop("loc:queues", 0)
		if res then
			task[n] = res[2]
			check = true;
			resnum = resnum + 1;
		else
			task[n] = JSON.null
			break;
		end
	end
	if check == true then
		local result = {};
		result["resultCode"] = 0;
		result["tasknumber"] = resnum;
		result["taskQueues"] = task;
		ngx.print(JSON.encode(result))
	else
		ngx.print(error002)
	end
	--[[
	-- blpop one.
	local res, err = red:blpop("Queues", 0)
	if not res then
		ngx.print(error002)
	else
		ngx.print(res[2])
	end
	--]]
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
--[[	-- put it into the connection pool of size 512,
	-- with 0 idle timeout
	local ok, err = red:set_keepalive(0, 512)
	if not ok then
		ngx.say("failed to set keepalive redis: ", err)
		return
	end
--]]