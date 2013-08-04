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
redis.commands.rpush = redis.command('rpush')
redis.commands.llen = redis.command('llen')

function sleep(n)
   socket.select(nil, nil, n)
end
local url = "http://api.bestfly.cn/task-queues/1/";
while url do
	local len, err = client:llen("proxy:work")
	print(tonumber(len))
	while tonumber(len) < 3 do
		-- local body, code, headers = http.request("http://192.168.10.93:8080/mainproxy/FlightSearch/getProxy")
		local body, code, headers = http.request("http://www.dailiaaa.com/?ddh=394605632872055&dq=&sl=1&issj=0&xl=3&tj=fff&api=14&cf=4&yl=1")
		if code == 200 then
			local index = string.find(body, ":");
			local proxy = string.sub(body, 1, index-1) .. ":" .. string.sub(body, index+1, -3)
			print(proxy)
			client:rpush("proxy:work", proxy)
		end
		len = client:llen("proxy:work")
	end
	--[[
	local body, code, headers = http.request(url)
	if code == 200 then
		-- print(JSON.decode(body).taskQueues[1]);
		local arg = JSON.decode(body).taskQueues[1];
		local capi = "http://api.bestfly.cn/capi/ext-price/" .. string.sub(arg, 1, 8) .. "ow/" .. string.sub(arg, -9, -1);
		local api = "http://api.bestfly.cn/ext-price/" .. string.sub(arg, 1, 8) .. "ow/" .. string.sub(arg, -9, -1);
		local elongcmd = "/usr/local/bin/lua /usr/local/webserver/lua/elongsrvagent.lua " .. arg;
		os.execute(elongcmd);
		while true do
			local body, code, headers = http.request(capi)
			if code == 200 then
				http.request(api)
				break;
			else
				print(code)
				print("------------capi error--------------")
			end
		end
	else
		print(code)
		print("---------------------------")
		print(body)
	end
	--]]
	sleep(0.1);
end
