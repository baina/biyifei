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
--]]
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- load library

local strlen =  string.len
local JSON = require 'cjson'
local socket = require 'socket'
-- local http = require 'socket.http'
-- local tcp = ngx.socket.tcp
local tcp = socket.tcp
local byte = string.byte
local concat = table.concat
local error = error
local find = string.find
local gsub = string.gsub
local insert = table.insert
local len = string.len
local pairs = pairs
local setmetatable = setmetatable
local sub = string.sub

module(...)

_VERSION = "0.1"

local mt = { __index = _M }

local EOL = "\x0d\x0a"
local NULL_BYTE = "\x00"
local STATE_CONNECTED = 1
local STATE_COMMAND_SENT = 2


function new(self)
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock }, mt)
end


function set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end


function _build_frame(self, command, headers, body)
    local frame = {command, EOL}

    if body then
        headers["content-length"] = len(body) + 4
    end

    for key, value in pairs(headers) do
        insert(frame, key)
        insert(frame, ":")
        insert(frame, value)
        insert(frame, EOL)
    end

    insert(frame, EOL)

    if body then
        insert(frame, body)
        insert(frame, EOL)
        insert(frame, EOL)
    end

    insert(frame, NULL_BYTE)
    insert(frame, EOL)
    return concat(frame, "")
end


function _send_frame(self, frame)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    return sock:send(frame)
end

--[[
function _receive_frame(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    local resp = sock:receiveuntil(NULL_BYTE, {inclusive = true})
    local data, err, partial = resp()
    return data, err
end
--]]

function _login(self, user, passwd, vhost)
    local headers = {}
    headers["accept-version"] = "1.2"
    headers["login"] = user
    headers["passcode"] = passwd
    headers["host"] = vhost

    local ok, err = _send_frame(self, _build_frame(self, "CONNECT", headers, nil))
    if not ok then
        return nil, err
    end

    self.state = STATE_CONNECTED
    return _receive_frame(self)
end


function _logout(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    self.state = nil
    if self.state == STATE_CONNECTED then
        -- Graceful shutdown
        local headers = {}
        headers["receipt"] = "disconnect"
        sock:send(_build_frame(self, "DISCONNECT", headers, nil))
        sock:receive("*a")
    end
    return sock:close()
end


function connect(self, opts)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    local host = opts.host
    if not host then
        host = "127.0.0.1"
    end

    local port = opts.port
    if not port then
        port = 61613  -- stomp port
    end

    local username = opts.username
    if not username then
        username = "guest"
    end

    local password = opts.password
    if not password then
        password = "guest"
    end

    local vhost = opts.vhost
    if not vhost then
        vhost = "/"
    end

    local pool = opts.pool
    if not pool then
        pool = concat({username, vhost, host, port}, ":")
    end

    local ok, err = sock:connect(host, port, { pool = pool })
    if not ok then
        return nil, "failed to connect: " .. err
    end

    --[[
	local reused = sock:getreusedtimes()
    if reused and reused > 0 then
        self.state = STATE_CONNECTED
        return 1
    end
	--]]

    return _login(self, username, password, vhost)
end

function send(self, msg, headers)
    local ok, err = _send_frame(self, _build_frame(self, "SEND", headers, msg))
    if not ok then
        return nil, err
    end

    if headers["receipt"] ~= nil then
        return _receive_frame(self)
    end
    return ok, err
end

function subscribe(self, headers)
    return _send_frame(self, _build_frame(self, "SUBSCRIBE", headers))
end


function unsubscribe(self, headers)
    return _send_frame(self, _build_frame(self, "UNSUBSCRIBE", headers))
end


function receive(self)
    local data, err = _receive_frame(self)
    if not data then
        return nil, err
    end
    data = gsub(data, EOL..EOL, "")
    local idx = find(data, "\n\n", 1)
    return sub(data, idx + 2)
end


function set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    if self.state ~= STATE_CONNECTED then
        return nil, "cannot be reused in the current connection state: "
                    .. (self.state or "nil")
    end

    self.state = nil
    return sock:setkeepalive(...)
end


function get_reused_times(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end


function close(self)
    return _logout(self)
end


local class_mt = {
    -- to prevent use of casual module global variables
    __newindex = function (table, key, val)
        error('attempt to write to undeclared variable "' .. key .. '"')
    end
}

setmetatable(_M, class_mt)