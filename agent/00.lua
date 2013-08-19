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
-- caculate expiretime by t
function timet (t)
	local argdate = os.time({year=string.sub(t, 1, 4), month=tonumber(string.sub(t, 5, 6)), day=tonumber(string.sub(t, 7, 8)), hour=os.date("%H", os.time())})
	local argtime = argdate - os.time();
	local elotime = argtime / 86400;
	if elotime % 1 ~= 0 then
		elotime = elotime - elotime % 1 + 1;
	end
	local data = content.cachetime;
	local idxs = table.getn(data);
	for idxi = 1, idxs do
		if elotime > content.maxtime then
			return JSON.null
		end
		if tonumber(data[idxi].range[1]) <= elotime and elotime <= tonumber(data[idxi].range[2]) then
			return data[idxi].expire
		end
	end
end

function datetime (t)
	return os.date("%Y%m%d", os.time() + 24 * 60 * 60 * t)
end
-- print(datetime(1))
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

local city = {};
local linedata = client:zrange("city:loc", 0, -1, "withscores")
local total = 0;
local idxs = table.getn(linedata)
for idxi = 1, idxs do
	total = total + linedata[idxi][2];
	table.insert(city, linedata[idxi][1])
end
-- caculate expiretime by city
function linet (c)
	local score = client:zscore("city:loc", c)
	local index = client:zrank("city:loc", c)
	local res = (score / total) * (index / idxs)
	return res
end

function expiretime (t, c)
	if timet(t) == JSON.null then
		return nil
	else
		return timet(t) * (1 - 100 * linet(c))
	end
end
-- print(timet(20130820))
--[[
for i = 1, table.getn(city) do
	for j = 1, tonumber(content.maxtime) do
		local date = datetime(j)
		client:zadd("task:sort", expiretime(date, city[i]), city[i] .. "/" .. date .. "/")
		-- print(expiretime(datetime(j), city[i]))
	end
end
--]]