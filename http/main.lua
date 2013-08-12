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
redis.commands.rpush = redis.command('rpush')
redis.commands.llen = redis.command('llen')

function sleep(n)
   socket.select(nil, nil, n)
end

function docall ()
	--[[
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
	--]]
	os.execute("/usr/local/bin/lua /usr/local/webserver/lua/agent/maincall.lua");
end
threads = {}-- list of all live threads
function maincall ()
	-- create coroutine
	local co = coroutine.create(function ()
		docall()
	end)
	-- insert it in the list
	table.insert(threads, co)
end

local n = table.getn(threads)
local len, err = client:llen("proxy:work")
while n < tonumber(len) / 2 do
	maincall("/usr/local/webserver/lua/agent/thread/lualog" .. n)
	print("--------init New thread:" .. n)
	n = n + 1;
end
for i=1,n do
	local status, res = coroutine.resume(threads[i])
	if not res then-- thread finished its task?
		print("---------thread finished its task?----------")
		table.remove(threads, i)
	else
		print("--------Start New thread:" .. i .. "/" .. n)
		sleep(5)
	end
end