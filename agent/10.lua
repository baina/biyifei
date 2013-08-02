-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library
local socket = require 'socket'
local http = require 'socket.http'
local JSON = require 'cjson'
local md5 = require 'md5'
package.path = "/usr/local/webserver/lua/lib/?.lua;";
local redis = require 'redis'

function sleep(n)
   socket.select(nil, nil, n)
end

local file = io.open("/data/rails2.3.5/biyifei/agent/config.json", "r");
local content = JSON.decode(file:read("*all"));
file:close();

local params = {
    host = content.host,
    port = content.port,
}

local client = redis.connect(params)
client:select(0) -- for testing purposes
-- commands defined in the redis.commands table are available at module
-- level and are used to populate each new client instance.
redis.commands.hset = redis.command('hset')
redis.commands.sadd = redis.command('sadd')
redis.commands.zadd = redis.command('zadd')
redis.commands.smembers = redis.command('smembers')
redis.commands.keys = redis.command('keys')
redis.commands.sdiff = redis.command('sdiff')
redis.commands.zrange = redis.command('zrange')
redis.commands.expire = redis.command('expire')
redis.commands.zrank = redis.command('zrank')
redis.commands.zcard = redis.command('zcard')
redis.commands.zrangebyscore = redis.command('zrangebyscore')
redis.commands.rpush = redis.command('rpush')
redis.commands.lrange = redis.command('lrange')
-- start job.
while client do
	-- local tmpdata = {};
	local argscore = client:zrange("task:sort", 0, 0, "withscores")
	local args = client:zrangebyscore("task:sort", "-inf", argscore[1][2])
	local argidx = client:zrank("task:sort", args[table.getn(args)]) + 1
	for k, v in pairs(args) do
		print(v)
		-- table.insert(tmpdata, v)
		client:rpush("loc:queues", v)
		-- print(argscore[1][2])
		client:zadd("task:sort", argscore[1][2] * 2, v)
	end
	--[[
	--giveup activemq.
	print(JSON.encode(tmpdata))
	local command = "curl -u admin:admin -d 'body=%s' 'http://localhost:8161/demo/message/test?typntId=consumerA'"
	print(string.format(command, '"' .. JSON.encode(tmpdata) .. '"'))
	os.execute(string.format(command, '"' .. JSON.encode(tmpdata) .. '"'))
	--]]
	-- use redis list.
	-- cancel json format to org/dst/date/
	-- client:rpush("loc:queues", JSON.encode(tmpdata))
	-- print(args[table.getn(args)])
	print(argidx)
	local nextargscore = client:zrange("task:sort", argidx, argidx, "withscores")
	local interval = nextargscore[1][2] - argscore[1][2]
	print(interval)
	print("\r\n---------------------\r\n");
	sleep(interval)
end