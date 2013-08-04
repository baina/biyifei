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
	local body, code, headers = http.request(url)
	if code == 200 then
		-- print(JSON.decode(body).taskQueues[1]);
		local arg = JSON.decode(body).taskQueues[1];
		local capi = "http://api.bestfly.cn/capi/ext-price/" .. string.sub(arg, 1, 8) .. "ow/" .. string.sub(arg, -9, -1);
		local api = "http://api.bestfly.cn/ext-price/" .. string.sub(arg, 1, 8) .. "ow/" .. string.sub(arg, -9, -1);
		local elongcmd = "/usr/local/bin/lua /data/rails2.3.5/biyifei/http/elongsrvagent.lua " .. arg;
		-- local elongcmd = "/usr/local/bin/lua /data/rails2.3.5/biyifei/http/elongsrvagent.lua cgq/hgh/20130807/";
		os.execute(elongcmd);
		while true do
			local body, code, headers = http.request(capi)
			if code == 200 then
				print(code, body);
				print("------------capi sucess------------")
				local body, code, headers = http.request(api)
				if code == 200 then
					print(code);
					print("------------combinate price sucess------------")
					for k, v in pairs(headers) do
						print(k, v);
					end
					print("---------------------------")
				end
				break;
			else
				print(code)
				print("------------capi error--------------")
			end
		end
	else
		-- if get no mission sleep 10;
		print("------------NO mission left-----------")
		sleep(10)
	end
	sleep(0.1)
end