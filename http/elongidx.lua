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

-- city_name & city_name_cn
local luasql = require "luasql.mysql"
local env = assert(luasql.mysql())
local con = assert (env:connect("biyifei_base", "rhomobi_dev", "b6x7p6b6x7p6", "localhost", 3306))
con:execute("SET NAMES 'utf8';");
local sqlcmd = "";
local query = [=[select city_name, Trim( REPLACE ( REPLACE(city_name_en ,'\'','')  ,' ','') ) city_name_en from base_flights_city where `city_code` = '%s']=];
sqlcmd = string.format(query, string.upper(ngx.var.org));
local cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local citydep = row.city_name_en
local citydepname = row.city_name
sqlcmd = string.format(query, string.upper(ngx.var.dst));
cur = assert (con:execute(sqlcmd))
local row = cur:fetch ({}, "a")
local cityarr = row.city_name_en
local cityarrname = row.city_name
cur:close()
-- end of mysql.

local fltno = string.upper(ngx.var.fltno);
local unikey = fltno .. "Q078311BSP";

local depdate = string.sub(ngx.var.date, 1, 4) .. "/" .. tonumber(string.sub(ngx.var.date, 5, 6)) .. "/" .. tonumber(string.sub(ngx.var.date, 7, 8)) .. " 0:00";
local argdate = os.time({year=string.sub(ngx.var.date, 1, 4), month=tonumber(string.sub(ngx.var.date, 5, 6)), day=tonumber(string.sub(ngx.var.date, 7, 8)), hour=0});
argdate = argdate + 259200;
local bakdate = os.date("%Y/%m/%d 0:00", argdate);
local formdata = {};

table.insert(formdata, "flightNumber=" .. fltno);
table.insert(formdata, "flightClassType=260");
table.insert(formdata, "fareId=0");
table.insert(formdata, "channel=BSP");
table.insert(formdata, "uniquekey=" .. unikey);
table.insert(formdata, "arrivecity=" .. cityarr);
table.insert(formdata, "departcity=" .. citydep);
table.insert(formdata, "daycount=1");
table.insert(formdata, "language=cn");
table.insert(formdata, "viewpath=~/views/list/oneway.aspx");
table.insert(formdata, "pagename=list");
table.insert(formdata, "flighttype=0");
table.insert(formdata, "seatlevel=Y");
table.insert(formdata, "request.PageName=list");
table.insert(formdata, "request.FlightType=OneWay");
table.insert(formdata, "request.DepartCity=" .. string.upper(ngx.var.org));
table.insert(formdata, "request.DepartCityName=" .. citydepname);
table.insert(formdata, "request.DepartCityNameEn=" .. citydep);
table.insert(formdata, "request.ArriveCity=" .. string.upper(ngx.var.dst));
table.insert(formdata, "request.ArriveCityName=" .. cityarrname);
table.insert(formdata, "request.ArriveCityNameEn=" .. cityarr);

table.insert(formdata, "request.DepartDate=" .. depdate);
table.insert(formdata, "request.BackDate=" .. bakdate);

table.insert(formdata, "request.DayCount=1");
table.insert(formdata, "request.BackDayCount=0");
table.insert(formdata, "request.SeatLevel=Y");

table.insert(formdata, "request.First_DepartCity=" .. string.upper(ngx.var.org));
table.insert(formdata, "request.First_DepartCityName=" .. citydepname);
table.insert(formdata, "request.First_ArriveCity=" .. string.upper(ngx.var.dst));
table.insert(formdata, "request.First_ArriveCityName=" .. cityarrname);

table.insert(formdata, "request.First_DepartDate=" .. depdate);

table.insert(formdata, "request.Second_DepartCity=" .. string.upper(ngx.var.dst));
table.insert(formdata, "request.Second_DepartCityName=" .. cityarrname);
table.insert(formdata, "request.Second_ArriveCity=" .. string.upper(ngx.var.org));
table.insert(formdata, "request.Second_ArriveCityName=" .. citydepname);

table.insert(formdata, "request.Second_DepartDate=" .. bakdate);

table.insert(formdata, "request.IssueCity=" .. string.upper(ngx.var.org));
table.insert(formdata, "request.Square=0");
table.insert(formdata, "request.CanOrder=1");
table.insert(formdata, "request.OrderBy=Price");
table.insert(formdata, "request.OrderFromId=50");
table.insert(formdata, "request.ProxyId=ZD");
table.insert(formdata, "request.AirCorp=0");
table.insert(formdata, "request.ElongMemberLevel=Common");
table.insert(formdata, "request.language=cn");
table.insert(formdata, "request.viewpath=~/views/list/oneway.aspx");

local form_data = table.concat(formdata, "&");
-- form_data = "flightNumber=CZ3907&flightClassType=260&fareId=0&channel=BSP&uniquekey=CZ3907Q078311BSP&arrivecity=shanghai&departcity=beijing&daycount=1&language=cn&viewpath=~/views/list/oneway.aspx&pagename=list&flighttype=0&seatlevel=Y&request.PageName=list&request.FlightType=OneWay&request.DepartCity=BJS&request.DepartCityName=北京&request.DepartCityNameEn=Beijing&request.ArriveCity=SHA&request.ArriveCityName=上海&request.ArriveCityNameEn=Shanghai&request.DepartDate=2013/8/3 0:00&request.BackDate=2013/8/6 0:00&request.DayCount=1&request.BackDayCount=0&request.SeatLevel=Y&request.First_DepartCity=BJS&request.First_DepartCityName=北京&request.First_ArriveCity=SHA&request.First_ArriveCityName=上海&request.First_DepartDate=2013/8/3 0:00&request.Second_DepartCity=SHA&request.Second_DepartCityName=上海&request.Second_ArriveCity=BJS&request.Second_ArriveCityName=北京&request.Second_DepartDate=2013/8/6 0:00&request.IssueCity=BJS&request.Square=0&request.CanOrder=1&request.OrderBy=Price&request.OrderFromId=50&request.ProxyId=ZD&request.AirCorp=0&request.ElongMemberLevel=Common&request.language=cn&request.viewpath=~/views/list/oneway.aspx";
-- print(formdata);

if ngx.var.request_method == "GET" then
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = "http://flight.elong.com/isajax/OneWay/GetMorePrices",
		--- proxy = "http://127.0.0.1:8888",
		-- timeout = 3000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data), ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6"},
		-- body = ltn12.source.string(form_data),
		body = form_data,
	}
	--[[
	ngx.say(ok)
	ngx.say(code)
	for k, v in pairs(headers) do
		ngx.say(k, v);
	end
	ngx.say(status)
	ngx.say(body)
	--]]
	if code == 200 then
		ngx.print(body);
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