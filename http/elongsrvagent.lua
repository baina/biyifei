-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of agent for elong website : http://flight.elong.com/beijing-shanghai/cn_day19.html
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
-- pcall(require, "luarocks.require")
local redis = require 'redis'
local params = {
    host = '127.0.0.1',
    port = 6379,
}
local client = redis.connect(params)
client:select(0) -- for testing purposes
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.hdel = redis.command('hdel')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.expire = redis.command('expire')
redis.commands.lrange = redis.command('lrange')
redis.commands.blpop = redis.command('blpop')

function sleep(n)
   socket.select(nil, nil, n)
end
local function _formencodepart(s)
	if type(s) == number then
		return s
	else
		return s and (s:gsub("%W", function (c)
	 		if c ~= " " then
	 			return string.format("%%%02x", c:byte());
	 		else
	 			return "+";
	 		end
	 	end));
	end
end
-- Get the mission.(org/dst/t)
local org = string.sub(arg[1], 1, 3);
local dst = string.sub(arg[1], 5, 7);
local t = string.sub(arg[1], 9, -2);
-- end mission get.
local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
local con = assert (env:connect("biyifei_base", "bestfly", "b6x7p6", "192.168.13.2", 3306))
local sqlcmd = "";
-- local sql = "select Trim( REPLACE ( REPLACE(city_name_en ,'\'','')  ,' ','') ) city_name_en from base_flights_city where `city_code` = "
local query = [=[select Trim( REPLACE ( REPLACE(city_name_en ,'\'','')  ,' ','') ) city_name_en from base_flights_city where `city_code` = '%s']=];
sqlcmd = string.format(query, string.upper(org));
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local citydep = row.city_name_en
sqlcmd = string.format(query, string.upper(dst));
cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local cityarr = row.city_name_en
cur:close()
-- end of mysql for pinyin result.
local argdate = os.time({year=string.sub(t, 1, 4), month=tonumber(string.sub(t, 5, 6)), day=tonumber(string.sub(t, 7, 8)), hour=os.date("%H", os.time())})
local argtime = argdate - os.time();
local elotime = argtime / 86400;
if elotime % 1 ~= 0 then
	elotime = elotime - elotime % 1 + 1;
end
-- local elodate = os.date("%Y%m%d", ngx.now());
local session = md5.sumhexa(os.time() .. org .. dst .. t);
print(session)
print("---------------------------")
-- ngx.say(citydep, cityarr)
local baseurl = "http://flight.elong.com/%s-%s/cn_day%s.html"
local idxurl = "http://localhost:18081/"
local resp = {};
print(string.format(baseurl, string.lower(citydep), string.lower(cityarr), elotime));
print("---------------------------")
-- print(elotime)
-- local url = string.format(baseurl, string.lower(citydep), string.lower(cityarr), elotime);
local res, err = client:blpop("proxy:work", 0)
-- print(res)
-- print(type(res[1]), res[1], res[2])
-- print(table.getn(res))
if res ~= nil then
	local respbody = {};
	-- print(tostring(res[2]))
	-- change to insert proxy into the http.request table.
	-- http.PROXY = "http://" .. tostring(res[2]) .. "/";
	print("http://" .. tostring(res[2]))
	print("-------------Get fltno withproxy--------------")
	local body, code, headers, status = http.request {
		url = string.format(baseurl, string.lower(citydep), string.lower(cityarr), elotime),
		--- proxy = "http://127.0.0.1:8888",
		proxy = "http://" .. tostring(res[2]),
		timeout = 6000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		headers = { ["Host"] = "flight.elong.com", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
		-- body = formdata,
		-- source = ltn12.source.string(form_data);
		sink = ltn12.sink.table(respbody)
	}
	-- local body, code, headers = http.request(url)
	if code == 200 then
		local rescontent = "";
		local reslen = table.getn(respbody)
		for i = 1, reslen do
			-- print(respbody[i])
			rescontent = rescontent .. respbody[i]
		end
		for k in string.gmatch(rescontent, 'flightno="(%w+)"') do
			while k do
				local res, err = client:sadd("elong:flt:" .. session, k)
				if res then
					client:expire("elong:flt:" .. session, 60)
				end
				break
			end
		end
		local flts = client:smembers("elong:flt:" .. session)
		if flts ~= nil then
			for f = 1, table.getn(flts) do
				print("当前航班" .. f .. "/" .. table.getn(flts) .. ",正在处理" .. flts[f]);
				print("---------------------------")
				local fltmuli = "idx-elong/" .. string.lower(org) .. "/" .. string.lower(dst) .. "/" .. string.lower(flts[f]) .. "/" .. t .. "/";
				-- table.insert(reqs, { fltmuli })
				print(idxurl .. fltmuli)
				print("-------------local NO proxy--------------")
				local body, code, headers = http.request(idxurl .. fltmuli)
				if body ~= nil then
					local j = string.gsub(body,'\"([^\"]-)\":','%1=')
					local tjson, c = string.gsub(j,'%b\[\]','')
					if c ~= 0 then
					-- if code == 200 then
						local allprice = JSON.decode(body);
						if allprice then
							-- print(fltmuli, flts[f], table.getn(allprice.value[1]))
							local tmpres = {};
							local priceinfo = {};
							local salelimit = {};
							if allprice.value[1].CouponList[1] ~= nil then
								priceinfo["Price"] = allprice.value[1].SalePrice .. "(-" .. allprice.value[1].CouponList[1].SalePrice .. ")";
								salelimit["PolicyID"] = allprice.value[1].CouponList[1].Id;
							else
								priceinfo["Price"] = allprice.value[1].SalePrice;
								salelimit["PolicyID"] = allprice.value[1].FareId;
							end
							priceinfo["StandardPrice"] = allprice.value[1].OriginalSalesPrice;
							if allprice.value[1].Index == 0 then
								priceinfo["IsLowestPrice"] = true;
							else
								priceinfo["IsLowestPrice"] = false;
							end
							priceinfo["Rate"] = allprice.value[1].ClassTitle;
							priceinfo["PriceType"] = allprice.value[1].ClassTitle;
							salelimit["Remarks"] = allprice.value[1].PreSaleDate;
							local FlightTime = "";
							for a, b, c, x, y, z in string.gmatch(allprice.value[1].Rule, "(%a+)|(%d+)|(%d+)|(.*)|(%a+)|(%a+)|(%a+)|(.*)") do
								FlightTime = x;
							end
							local noteurl = "http://flight.elong.com/isajax/flightajax/GetRestrictionRuleInfo?type=Adult&arrivecity=%s&departcity=%s&daycount=%s&language=cn&viewpath=~/views/list/oneway.aspx&pagename=list&flighttype=0&seatlevel=Y&requestInfo.AirCorpCode=%s&requestInfo.FareItemID=0&requestInfo.FlightClass=%s&requestInfo.FlightTime=%s&requestInfo.IsKSeat=%s&requestInfo.IsPromotion=%s&requestInfo.IssueCityCode=%s&requestInfo.IsRTPromotion=False&requestInfo.UseType=Booking&requestInfo.OrderFromId=0&requestInfo.Language=CN&requestInfo.Category=0&requestInfo.IsSearchCache=false&requestInfo.SearchUserLevel=0&requestInfo.IsPreLoad=false";
							noteurl = string.format(noteurl, string.lower(cityarr), string.lower(citydep), elotime, string.upper(string.sub(flts[f], 1, 2)), allprice.value[1].FlightClassNumber, _formencodepart(FlightTime), tostring(allprice.value[1].IsKSeat), tostring(allprice.value[1].IsPackagePromotion), org);
							-- print(noteurl)
							sleep(3)
							-- local body, code, headers = http.request(noteurl)
							local respbody = {};
							print("-------------forign need proxy--------------")
							local body, code, headers, status = http.request {
								url = noteurl,
								--- proxy = "http://127.0.0.1:8888",
								proxy = "http://" .. tostring(res[2]),
								timeout = 5000,
								method = "GET", -- POST or GET
								-- add post content-type and cookie
								headers = { ["Host"] = "flight.elong.com", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
								-- body = formdata,
								-- source = ltn12.source.string(form_data);
								sink = ltn12.sink.table(respbody)
							}
							if code == 200 then
								local reslimit = "";
								local reslen = table.getn(respbody)
								for i = 1, reslen do
									-- print(respbody[i])
									reslimit = reslimit .. respbody[i]
								end
								--[[
								-- check json by "c" is NOT comfortable.
								local j = string.gsub(reslimit,'\"([^\"]-)\":','%1=')
								local tjson, c = string.gsub(j,'%b\[\]','')
								print(tjson, c);
								--]]
								local allrules = JSON.decode(reslimit);
								if allrules then
									salelimit["Notes"] = allrules.value;
								else
									salelimit["Notes"] = JSON.null;
									print(code, reslimit)
								end
							else
								salelimit["Notes"] = JSON.null;
								print(code, body)
							end
							tmpres["priceinfo"] = priceinfo;
							tmpres["salelimit"] = salelimit;
							-- resp[flts[f]] = tmpres;
							-- print(JSON.encode(tmpres))
							-- print(JSON.encode(resp));
							-- elong:cgq/hgh/{success=true,value=}/
							print('elong:' .. string.lower(org) .. '/' .. string.lower(dst) .. '/' .. t .. '/');
							client:hdel('elong:' .. string.lower(org) .. '/' .. string.lower(dst) .. '/' .. t .. '/', flts[f]);
							local ok, err = client:hset('elong:' .. string.lower(org) .. '/' .. string.lower(dst) .. '/' .. t .. '/', flts[f], JSON.encode(tmpres))
							if ok then
								print("------------ok---------------")
							else
								print(flts[f], err)
							end
						else
							print(body)
						end
					else
						print(code, body)
					end
				end
				sleep(7)
			end
		else
			print("------------no flight-------------")
		end
	else
		print(code, body)
		print("-----------result is null-------------")
	end
end
