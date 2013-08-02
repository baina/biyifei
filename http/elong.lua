local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
-- pcall(require, "luarocks.require")

local redis = require 'redis'

local params = {
    host = '127.0.0.1',
    port = 6389,
}

local client = redis.connect(params)
client:select(0) -- for testing purposes

-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.sadd = redis.command('sadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')

function sleep(n)
   socket.select(nil, nil, n)
end

local url = "http://flight.elong.com/beijing-shanghai/cn_day19.html"

local body, code, headers = http.request(url)
if code == 200 then

	for k in string.gmatch(body, 'flightno="(%w+)"') do
		client:sadd("elong:line:flt:tmp", k)
		print(k)
	end
	
	local data = client:smembers("elong:line:flt:tmp")
	print(table.getn(data))
	
	print("\n--------------------\n");

	for k, t, v in string.gmatch(body, 'price="(%w)"(.*)flightno="(%w+)"') do
		print(k, v)
	end
	
	-- print(tmpbody);
end
--else print(error) end


local fltno = "MU5183";
local unikey = "MU5183Q078311BSP";
local formdata = {};

table.insert(formdata, "flightNumber=" .. fltno);
table.insert(formdata, "flightClassType=260");
table.insert(formdata, "fareId=0");
table.insert(formdata, "channel=BSP");
table.insert(formdata, "uniquekey=" .. unikey);
table.insert(formdata, "arrivecity=shanghai");
table.insert(formdata, "departcity=beijing");
table.insert(formdata, "daycount=1");
table.insert(formdata, "language=cn");
table.insert(formdata, "viewpath=~/views/list/oneway.aspx");
table.insert(formdata, "pagename=list");
table.insert(formdata, "flighttype=0");
table.insert(formdata, "seatlevel=Y");
table.insert(formdata, "request.PageName=list");
table.insert(formdata, "request.FlightType=OneWay");
table.insert(formdata, "request.DepartCity=BJS");
table.insert(formdata, "request.DepartCityName=北京");
table.insert(formdata, "request.DepartCityNameEn=Beijing");
table.insert(formdata, "request.ArriveCity=SHA");
table.insert(formdata, "request.ArriveCityName=上海");
table.insert(formdata, "request.ArriveCityNameEn=Shanghai");
table.insert(formdata, "request.DepartDate=2013/8/3 0:00");
table.insert(formdata, "request.BackDate=2013/8/6 0:00");

table.insert(formdata, "request.DayCount=1");
table.insert(formdata, "request.BackDayCount=0");
table.insert(formdata, "request.SeatLevel=Y");

table.insert(formdata, "request.First_DepartCity=BJS");
table.insert(formdata, "request.First_DepartCityName=北京");
table.insert(formdata, "request.First_ArriveCity=SHA");
table.insert(formdata, "request.First_ArriveCityName=上海");

table.insert(formdata, "request.First_DepartDate=2013/8/3 0:00");
table.insert(formdata, "request.Second_DepartCity=SHA");
table.insert(formdata, "request.Second_DepartCityName=上海");
table.insert(formdata, "request.Second_ArriveCity=BJS");
table.insert(formdata, "request.Second_ArriveCityName=北京");
table.insert(formdata, "request.Second_DepartDate=2013/8/6 0:00");
table.insert(formdata, "request.IssueCity=BJS");
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
local respbody = {};
-- local hc = http:new()
local body, code, headers, status = http.request {
-- local ok, code, headers, status, body = http.request {
	url = "http://flight.elong.com/isajax/OneWay/GetMorePrices",
	--- proxy = "http://127.0.0.1:8888",
	--- timeout = 3000,
	method = "POST", -- POST or GET
	-- add post content-type and cookie
	headers = { ["Content-Type"] = "application/x-www-form-urlencoded", ["Content-Length"] = string.len(form_data) },
	-- body = formdata,
	source = ltn12.source.string(form_data);
	sink = ltn12.sink.table(respbody)
}
print(code)
for k, v in pairs(headers) do
	print(k, v);
end
print(status)
print(body)
print(table.getn(respbody))
local reslen = table.getn(respbody)
for i = 1, reslen do
	print(respbody[i])
end
--[[
if code == 200 then
	local resbody = JSON.decode(body);
	local ok, err = memc:set(id, resbody.token, 18000)
	return resbody.resultCode, resbody.token
	-- return resbody.resultCode, body
else
	return errorcodeNo, status
end
--]]