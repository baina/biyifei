-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
--[[
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
local p = "/usr/local/webserver/lua/lib/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s",
    p, p, m_package_path)
local redis = require "redis"

-- create client:
-- coroutine.yield()
local wssocket = require 'websocket'
local wsclient = wssocket.client.copas({timeout=2})

-- connect to the server:
local ok,err = wsclient:connect('ws://localhost:61614', 'stomp')
if not ok then
   print('could not connect',err)
end

-- send data:

local ok = wsclient:send('hello')
if ok then
   print('msg sent')
else
   print('connection closed')
end

-- receive data:

local message,opcode = wsclient:receive()
if message then
   print('msg',message,opcode)
else
   print('connection closed')
end

-- close connection:

local close_was_clean,close_code,close_reason = wsclient:close(4001,'lost interest')