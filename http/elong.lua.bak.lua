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
	--[[
	print("\n--------------------\n");

	for k, t, v in string.gmatch(body, 'price="(%w)"(.*)flightno="(%w+)"') do
		print(k, v)
	end
	--]]
	-- print(tmpbody);
end
--else print(error) end


local formdata = {};
formdata["flightNumber"] = "CZ3907";
formdata["flightClassType"] = 260;
formdata["fareId"] = 0;
formdata["channel"] = "BSP";
formdata["uniquekey"] = "CZ3907Q078311BSP";
formdata["arrivecity"] = "shanghai";
formdata["departcity"] = "beijing";
formdata["daycount"] = 1;
formdata["language"] = "cn";
formdata["viewpath"] = "~/views/list/oneway.aspx";
formdata["pagename"] = "list";
formdata["flighttype"] = 0;
formdata["seatlevel"] = "Y";
formdata["request.PageName"] = "list";
formdata["request.FlightType"] = "OneWay";
formdata["request.DepartCity"] = "BJS";
formdata["request.DepartCityName"] = "北京";
formdata["request.DepartCityNameEn"] = "Beijing";
formdata["request.ArriveCity"] = "SHA";
formdata["request.ArriveCityName"] = "上海";
formdata["request.First_DepartDate"] = "2013/8/3 0:00";
formdata["request.Second_DepartCity"] = "SHA";
formdata["request.Second_DepartCityName"] = "上海";
formdata["request.Second_ArriveCity"] = "BJS";
formdata["request.Second_ArriveCityName"] = "北京";

formdata["request.Second_DepartDate"] = "2013/8/6 0:00";
formdata["request.IssueCity"] = "BJS";
formdata["request.Square"] = 0;
formdata["request.CanOrder"] = 1;
formdata["request.OrderBy"] = "Price";
formdata["request.OrderFromId"] = 50;


formdata["request.ProxyId"] = "ZD";
formdata["request.AirCorp"] = 0;
formdata["request.ElongMemberLevel"] = "Common";
formdata["request.language"] = "cn";
formdata["request.viewpath"] = "~/views/list/oneway.aspx";

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

function formencode(form)
	local result = {};
 	if form[1] then -- Array of ordered { name, value }
 		for _, field in ipairs(form) do
 			-- t_insert(result, _formencodepart(field.name).."=".._formencodepart(field.value));
			table.insert(result, field.name .. "=" .. tostring(field.value));
 		end
 	else -- Unordered map of name -> value
 		for name, value in pairs(form) do
 			-- table.insert(result, _formencodepart(name).."=".._formencodepart(value));
			table.insert(result, name .. "=" .. tostring(value));
 		end
 	end
 	return table.concat(result, "&");
end

function formdecode(s)
 	if not s:match("=") then return urldecode(s); end
 	local r = {};
 	for k, v in s:gmatch("([^=&]*)=([^&]*)") do
 		k, v = k:gsub("%+", "%%20"), v:gsub("%+", "%%20");
 		k, v = urldecode(k), urldecode(v);
 		t_insert(r, { name = k, value = v });
 		r[k] = v;
 	end
 	return r;
end

local form_data = formencode(formdata);
-- local form_data = "flightNumber=CZ3907&flightClassType=260&fareId=0&channel=BSP&uniquekey=CZ3907Q078311BSP&arrivecity=shanghai&departcity=beijing&daycount=1&language=cn&viewpath=~/views/list/oneway.aspx&pagename=list&flighttype=0&seatlevel=Y&request.PageName=list&request.FlightType=OneWay&request.DepartCity=BJS&request.DepartCityName=北京&request.DepartCityNameEn=Beijing&request.ArriveCity=SHA&request.ArriveCityName=上海&request.ArriveCityNameEn=Shanghai&request.DepartDate=2013/7/18 0:00&request.BackDate=2013/7/20 0:00&request.DayCount=1&request.BackDayCount=0&request.SeatLevel=Y&request.First_DepartCity=BJS&request.First_DepartCityName=北京&request.First_ArriveCity=SHA&request.First_ArriveCityName=上海&request.First_DepartDate=2013/7/18 0:00&request.Second_DepartCity=SHA&request.Second_DepartCityName=上海&request.Second_ArriveCity=BJS&request.Second_ArriveCityName=北京&request.Second_DepartDate=2013/7/20 0:00&request.IssueCity=BJS&request.Square=0&request.CanOrder=1&request.OrderBy=Price&request.OrderFromId=50&request.ProxyId=ZD&request.AirCorp=0&request.ElongMemberLevel=Common&request.language=cn&request.viewpath=~/views/list/oneway.aspx";
print(form_data)
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
print(respbody[1])
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