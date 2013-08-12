local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'

local JSON = require 'cjson'
local md5 = require 'md5'
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
redis.commands.hdel = redis.command('hdel')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.expire = redis.command('expire')
redis.commands.lrange = redis.command('lrange')


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
--[[
local res, err = client:lrange("proxy:work", 0, 0)
if table.getn(res) == 1 then
	local index = string.find(res[1], ":")
	print(string.sub(res[1], 1, index-1))
	print(string.sub(res[1], index+1, -1))
	http.PROXY = "http://" .. tostring(res[1]);
	print(http.PROXY)
	local respbody = {};
	local body, code, headers, status = http.request {
		url = "http://flight.elong.com/beijing-shenzhen/cn_day2.html",
		-- url = "http://agent.cloudavh.com:18081",
		-- url = "http://rhomobi.com",
		--- proxy = "http://127.0.0.1:8888",
		-- proxy = "http://" .. string.sub(res[1], 1, index-1) .. ":" .. string.sub(res[1], index+1, -1) .. "/",
		--- timeout = 3000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		headers = { ["Host"] = "flight.elong.com", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
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
end
--]]
function domaincall (file)

	local handle = io.popen("/usr/local/bin/lua /data/rails2.3.5/biyifei/http/hello-2.lua");
	local resw = handle:read("*a");
	if resw then
		local wname = file
		local wfile = io.open(wname, "w+");
		wfile:write(os.date());
		wfile:write("\r\n---------------------\r\n");
		wfile:write(resw);
		wfile:write("\r\n---------------------\r\n");
		io.close(wfile);
	end
	handle:close();
	
end