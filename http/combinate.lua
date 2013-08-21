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
redis.commands.exists = redis.command('exists')

function sleep(n)
   socket.select(nil, nil, n)
end
local client = redis.connect(params)
-- client:select(0) -- for testing purposes
-- client:exists("price:comb")
local baseurl = "http://api.bestfly.cn/"
while true do
	local arg, err = client:blpop("price:comb", 1)
	if not arg then
		print("wait for 5 second.")
		sleep(5)
	else
		arg = arg[2];
		local carg = string.sub(arg, 11, -1);
		local capi = "http://api.bestfly.cn/capi/" .. string.gsub(carg, "/", "") .. "/";
		local api = baseurl .. arg;
		print(capi);
		print("------------start to capi------------")
		local body, code, headers = http.request(capi)
		if code == 200 then
			print(code, body);
			print("------------capi sucess------------")
			print(api);
			print("------------start to combinate----------")
			local body, code, headers = http.request(api)
			if code == 200 then
				print(code);
				print("------------combinate price sucess------------")
				for k, v in pairs(headers) do
					print(k, v);
				end
				print("---------------------------")
			end
			-- break;
		else
			print(code)
			print("------------capi error--------------")
		end
	end
end