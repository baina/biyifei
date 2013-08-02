-- priceupdate
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
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from elong is no response"});
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
local ok, err = red:connect("127.0.0.1", 6389)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	if pcontent then
		--[[
		set $source $1;
		set $org $2;
		set $dst $3;
		set $fltno $4;
		set $date $5;
		--]]
		local ok, err = red:hset(string.lower(ngx.var.source) .. ':' .. string.lower(ngx.var.org) .. '/' .. string.lower(ngx.var.dst) .. '/' .. ngx.var.date .. '/', string.upper(ngx.var.fltno), pcontent)
		if ok then
			local result = {};
			result["resultCode"] = 0;
			result["priceSource"] = string.lower(ngx.var.source);
			result[string.lower(ngx.var.source)] = JSON.decode(pcontent);
			ngx.print(JSON.encode(result))
			-- print("------------ok---------------")
		else
			print(error003(err))
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