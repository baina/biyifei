-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service
-- load library
local JSON = require("cjson");
local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted airports"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from extension is no response"});
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
local ok, err = red:connect("192.168.13.2", 6388)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.
-- init the DICT.
local byfs = ngx.shared.biyifei;
local port = ngx.shared.airport;
local porg = port:get(string.upper(ngx.var.org));
local pdst = port:get(string.upper(ngx.var.dst));
local city = ngx.shared.citycod;
local torg = city:get(string.upper(ngx.var.org));
local tdst = city:get(string.upper(ngx.var.dst));
if ngx.var.request_method == "GET" then
	if porg or pdst then
		ngx.print(error001);
	else
		-- ngx.print(torg, tdst);
		-- ngx.print("\r\n---------------------\r\n");
		-- location ~ '^/extctrip/FlightSearch/([a-zA-Z]{3,4})/([A-Za-z0-9]{3})/([A-Za-z0-9]{3})/([a-zA-Z]{2})/([0-9]{8})$'
		-- nginx location for ctirp extension.
		if torg and tdst then
			ngx.exit(ngx.HTTP_NOT_ALLOWED);
		else
			local res = ngx.location.capture("/data-ifl/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.gdate .. "/" .. ngx.var.bdate .. "/");
			if res.status == 200 then
				-- ngx.print(res.body);
				local tbody = JSON.decode(res.body);
				if tbody.resultCode == 2 then
					local res, err = red:lpush("loc:queues", ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.gdate .. "/");
					if not res then
						ngx.exit(ngx.HTTP_BAD_REQUEST);
					else
						ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					end
					-- ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
				else
					ngx.print(res.body);
				end
			else
				ngx.print(error002);
			end
		end
	end
	-- put it into the connection pool of size 512,
	-- with 0 idle timeout
	local ok, err = red:set_keepalive(0, 512)
	if not ok then
		ngx.say("failed to set keepalive redis: ", err)
		return
	end
	-- or just close the connection right away:
	-- local ok, err = red:close()
	-- if not ok then
		-- ngx.say("failed to close: ", err)
		-- return
	-- end
end
if ngx.var.request_method == "POST" then
	if porg or pdst then
		ngx.print(error001);
	else
		ngx.req.read_body();
		local pcontent = ngx.req.get_body_data();
		-- local puri = ngx.var.URI;
		-- local args = ngx.req.get_headers();
		if pcontent then
			ngx.print(pcontent);
		end
	end
end
