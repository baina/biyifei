local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'
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

local bakdate = os.date("%Y/%m/%d %X", os.time());
print(bakdate);
print(os.date(os.time()))

local tmp = "CZ|0|340|2013/8/1 17:00:00|CAN|False|False|false"

for a, b, c, x, y, z in string.gmatch(tmp, "(%a+)|(%d+)|(%d+)|(.*)|(%a+)|(%a+)|(%a+)|(.*)") do
	print(_formencodepart(x))
end



local respbody = {};
local body, code, headers, status = http.request {
	url = "http://www.elong.com/",
	--- proxy = "http://127.0.0.1:8888",
	--- timeout = 3000,
	method = "GET", -- POST or GET
	-- add post content-type and cookie
	headers = { ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
	-- body = formdata,
	-- source = ltn12.source.string(form_data);
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
