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
local socket = require 'socket'

-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from elong is no response"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
function sleep(n)
   socket.select(nil, nil, n)
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

local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
local sqlcmd = "";
-- local sql = "select Trim( REPLACE ( REPLACE(city_name_en ,'\'','')  ,' ','') ) city_name_en from base_flights_city where `city_code` = "
local query = [=[select Trim( REPLACE ( REPLACE(city_name_en ,'\'','')  ,' ','') ) city_name_en from base_flights_city where `city_code` = '%s']=];
sqlcmd = string.format(query, string.upper(ngx.var.org));
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local citydep = row.city_name_en
sqlcmd = string.format(query, string.upper(ngx.var.dst));
cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local cityarr = row.city_name_en
cur:close()
-- end of mysql for pinyin result.
local argdate = os.time({year=string.sub(ngx.var.date, 1, 4), month=tonumber(string.sub(ngx.var.date, 5, 6)), day=tonumber(string.sub(ngx.var.date, 7, 8)), hour=os.date("%H", ngx.now())})
local argtime = argdate - ngx.now();
local elotime = argtime / 86400;
if elotime % 1 ~= 0 then
	elotime = elotime - elotime % 1 + 1;
end
-- local elodate = os.date("%Y%m%d", ngx.now());
if ngx.var.request_method == "GET" then
	-- ngx.say(ngx.var.uri)
	local session = ngx.md5(ngx.now() .. ngx.var.uri);
	-- ngx.say(citydep, cityarr)
	local baseurl = "http://flight.elong.com/%s-%s/cn_day%s.html"
	ngx.say(string.format(baseurl, string.lower(citydep), string.lower(cityarr), elotime))
	-- ngx.say(elotime)
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = string.format(baseurl, string.lower(citydep), string.lower(cityarr), elotime);
		--- proxy = "http://127.0.0.1:8888",
		timeout = 3000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		-- headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
		-- body = APPTOKEN,
	}
	if code == 200 then
		-- ngx.print(body);
		for k in string.gmatch(body, 'flightno="(%w+)"') do
			-- client:sadd("elong:line:flt:tmp", k)
			local res, err = red:sadd("elong:flt:" .. session, k)
			if not res then
				ngx.say(error003("failed to set the elong:flt:" .. session, err));
				return
			else
				red:expire("elong:flt:" .. session, 60)
			end
			-- ngx.say(k)
		end
		-- ngx.say(elodate);
		-- /idx-elong/can/bjs/hu7806/20130730/
		local fltmuli = "";
		local reqs = {};		
		local flts = red:smembers("elong:flt:" .. session);
		for f = 1, table.getn(flts) do
			fltmuli = "/idx-elong/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. string.lower(flts[f]) .. "/" .. ngx.var.date .. "/";
			-- table.insert(reqs, { fltmuli })
			local res = ngx.location.capture(fltmuli);
			ngx.say(res.status);
			ngx.say(res.body);
			sleep(30)
		end
		--[[
		-- multi is limitted by elong.
		-- issue all the requests at once and wait until they all return
		local resps = { ngx.location.capture_multi(reqs) }
		-- loop over the responses table
		for i, resp in ipairs(resps) do
			-- process the response table "resp"
			-- ngx.say(resp.status)
			if resp.status == 200 then
				-- ngx.say(resp.body);
				local allprice = JSON.decode(resp.body);
				if allprice then
					ngx.say(reqs, allprice.value[1])
				end
			end
		end
		--]]		
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