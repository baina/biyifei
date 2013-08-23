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
local baseurl = "http://bestfly:9090/"
while true do
	local arg, err = client:blpop("price:comb", 1)
	if not arg or arg == nil then
		print("wait for 5 second.")
		sleep(5)
	else
		arg = arg[2];
		if arg == nil or arg == "" then print("wait for 3 second.") sleep(3) else
		print(arg);
		print("---------------");
		local carg = string.sub(arg, 11, -1);
		local capi = baseurl .. "capi/" .. string.gsub(carg, "/", "") .. "/";
		local api = baseurl .. arg;
		print(capi);
		print("------------start to capi------------")
		local body, code, headers = http.request(capi)
		if code == 200 then
			print(code, body);
			print("------------capi sucess------------")
			print(api);
			print("------------start to combinate----------")
			
			local respbody = {};
			local body, code, headers, status = http.request {
				url = api,
				--- proxy = "http://127.0.0.1:8888",
				--- proxy = "http://" .. tostring(res[2]),
				timeout = 10000,
				method = "GET", -- POST or GET
				-- add post content-type and cookie
				-- headers = { ["Host"] = "flight.elong.com", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6" },
				-- body = formdata,
				-- source = ltn12.source.string(form_data);
				sink = ltn12.sink.table(respbody)
			}
			
			-- local body, code, headers = http.request(api)
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
		end end
	end
end
