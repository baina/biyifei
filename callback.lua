-- priceupdate
-- buyhome <huangqi@rhomobi.com> 20130821 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- main Call back
-- load library
local JSON = require("cjson");
local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- local ltn12 = require "ltn12"

-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "no Prices from ctrip, the process of combination is waiting..."});
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
if ngx.var.request_method == "POST" then
	local args = "";
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	if pcontent ~= nil and pcontent ~= JSON.null then
		-- ngx.say(pcontent);
		local tbody = JSON.decode(pcontent)
		if tbody.TYPE == "ow" then
			if tbody.CATEGORY == "dom" then
				-- /slf-price/hrb/bos/ow/20130823/
				args = "slf-price/" .. string.sub(tbody.ARG, 1, 8) .. "ow/" .. string.sub(tbody.ARG, -9, -1);
			else
				-- /ext-price/bjs/lax/ow/20130823/
				args = "ext-price/" .. string.sub(tbody.ARG, 1, 8) .. "ow/" .. string.sub(tbody.ARG, -9, -1);
			end
		end
		if tbody.TYPE == "rt" then
			-- /ext-price/hrb/bos/rt/20130823/20130901/
			args = "ext-price/" .. string.sub(tbody.ARG, 1, 8) .. "rt/" .. string.sub(tbody.ARG, -18, -1);
		end
		-- ngx.say(args)
		if args ~= "" and args ~= nil and args ~= JSON.null then
			local lres, lerr = red:linsert("price:comb", "before", args, args)
			if lres == -1 then
				if tbody.LEVEL == 0 then
					-- ngx.say("rpush")
					local res, err = red:rpush("price:comb", args)
					if not res then
						ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					else
						ngx.exit(ngx.HTTP_OK);
					end
				end
				if tbody.LEVEL == 1 then
					-- ngx.say("lpush")
					local res, err = red:lpush("price:comb", args)
					if not res then
						ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					else
						ngx.exit(ngx.HTTP_OK);
					end
				end
			else
				if tbody.LEVEL == 0 then
					-- ngx.say("rpush")
					local res, err = red:lrem("price:comb", 1, args)
					if not res then
						ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					else
						ngx.exit(ngx.HTTP_OK);
					end
				end
				if tbody.LEVEL == 1 then
					-- ngx.say("lpush")
					local res, err = red:lrem("price:comb", 0, args)
					if not res then
						ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
					else
						local res, err = red:lpush("price:comb", args)
						if not res then
							ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE);
						else
							ngx.exit(ngx.HTTP_OK);
						end
					end
				end
			end
		else
			ngx.exit(ngx.HTTP_BAD_REQUEST);
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