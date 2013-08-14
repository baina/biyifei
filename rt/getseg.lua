-- buyhome <huangqi@rhomobi.com> 20130811 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service ifl's rt type.
-- load library
local JSON = require("cjson");
-- local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted fltID"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Segments from data-seg is no response"});
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
local ok, err = red:connect("192.168.13.2", 6389)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.

if ngx.var.request_method == "GET" then
	local FlightLineID = ngx.var.fltid;
	local getfidres, getfiderr = red:get("flt:" .. FlightLineID .. ":id")
	if not getfidres then
		ngx.print(error003("failed to get the flt:" .. FlightLineID .. ":id: ", getfiderr))
		return
	end
	-- ngx.print(getfidres);
	-- ngx.print("\r\n---------------------\r\n");
	-- local fltid = tonumber(getfidres)
	if tonumber(getfidres) == nil then
		ngx.print(error002);
	else
		local fltid = tonumber(getfidres)
		local res, err = red:get("seg:" .. fltid)
		if not res then
			ngx.print(error003("failed to GET checksum_seg info: " .. fltid, err));
			return
		else
			ngx.print(res);
		end
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
-- put it into the connection pool of size 512,
-- with 0 idle timeout
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive redis: ", err)
	return
end