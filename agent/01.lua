-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
--[[
require 'socket.http'
    location /test
    {
      default_type text/plain;
      #set $digest "ViEfw0uXSr";
      #set $raw "123";
      #set_sha1 $digest $raw;
      #echo $digest;
	  content_by_lua_file /data/rails2.3.5/biyifei/agent/01.lua;
    }
/usr/include/apr-1/apr.h
/usr/local/Cellar/apr/1.4.6/include/apr-1/apr.h
--]]
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library

local strlen =  string.len
local JSON = require 'cjson'

function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
-- lua-resty-rabbitmqstomp: Opinionated RabbitMQ (STOMP) client lib
-- Copyright (C) 2013 Rohit 'bhaisaab' Yadav, Wingify
-- Opensourced at Wingify in New Delhi under the MIT License
local socket = require 'socket'
-- local http = require 'socket.http'
-- local tcp = ngx.socket.tcp
local tcp = socket.tcp


package.path = "/data/rails2.3.5/biyifei/agent/?.lua;";
local rabbitmq = require 'resty.rabbitmqstomp'
local mq, err = rabbitmq:new()
if not mq then
	return
else
	print(type(mq))
	for k, v in pairs(mq) do
		print(k, v)
	end
end

mq:set_timeout(1000)

local conok, conerr = mq:connect { host="172.16.30.1", port=61613, username="guest", password="guest", vhost="/test" }

-- local conok, conerr = mq:connect {};

if not conok then
	print(conerr)
	return
else
	print(conok)
end
--[[
local msg = {key="value1", key2="value2"}
local headers = {}
headers["destination"] = "/queue/test"
headers["receipt"] = "msg#1"
headers["app-id"] = "luaresty"
headers["persistent"] = "true"
headers["content-type"] = "application/json"

local ok, err = mq:send(JSON.encode(msg), headers)
if not ok then
    return
end
ngx.log(ngx.INFO, "Published: " .. msg)

local headers = {}
headers["destination"] = "/amq/queue/queuename"
headers["persistent"] = "true"
headers["id"] = "123"

local ok, err = mq:subscribe(headers)
if not ok then
    return
end

local data, err = mq:receive()
if not ok then
    return
end
ngx.log(ngx.INFO, "Consumed: " .. data)

local headers = {}
headers["persistent"] = "true"
headers["id"] = "123"

local ok, err = mq:unsubscribe(headers)
--]]

local ok, err = mq:set_keepalive(0, 512)
if not ok then
	print(error003("failed to set keepalive mq: ", err))
    return
end