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
	sleep(1);
end