

local socket = require("socket")
local http = require("socket.http")
local ltn12 = require 'ltn12'
local base64 = require 'base64'
local JSON = require 'cjson'
local md5 = require 'md5'
local zlib = require 'zlib'

local a = "ext-price/bjs/lax/rt/20130930/20131010/";
local b = "slf-price/bjs/sha/ow/20130930/"

a = string.sub(a, 11, -1);
b = string.sub(b, 11, -1);
print(a)
a = string.gsub(a, "/", "");
print(a)
print(b)

print(zlib.version())


-- print(arg[0])
print(arg[1])
-- print(arg[2])
function datetime (t)
	return os.date("%Y%m%d", os.time() + 24 * 60 * 60 * t)
end

--[[
-- Get the mission.(org/dst/t)
local org = string.sub(arg[1], 1, 3);
local dst = string.sub(arg[1], 5, 7);
local t = string.sub(arg[1], 9, -2);
print(org)
print(dst)
print(t)

--]]

local file = io.open("/data/rails2.3.5/biyifei/agent/config.json", "r");
local content = file:read("*all");
file:close();
local j = string.gsub(content,'\"([^\"]-)\":','%1=')
local t, c, d = string.gsub(j,'%b\[\]','')
print(t, c, d)
if c ~= 0 then
	print(content)
end

function json(json)
	local j=string.gsub(json,'\"([^\"]-)\":','%1=')
	local j=string.gsub(j,'%b\[\]','')
	local j='t='..j
	-- loadstring(j)()
	return t
end


local tmprandom1 = math.random(8001,9999);
local tmprandom2 = math.random(8001,9999);
a, b = tmprandom1, tmprandom2
print(a, b)

function perm (a)
	local n = table.getn(a)
	return coroutine.wrap(function () permgen(a, n) end)
end
--[[
function perm (a)
	local n = table.getn(a)
	local co = coroutine.create(function () permgenyeild(a, n) end)
	return function ()
		-- iterator
		local code, res = coroutine.resume(co)
		return res
	end
end
--]]
function permgenyeild (a, n)
	if n == 0 then
		coroutine.yield(a)
	else
		for i=1,n do
			-- put i-th element as the last one
			a[n], a[i] = a[i], a[n]
			-- generate all permutations of the other elements
			permgen(a, n - 1)
			-- restore i-th element
			a[n], a[i] = a[i], a[n]
		end
	end
end
function permgen (a, n)
	if n == 0 then
		printResult(a)
	else
		for i=1,n do
			-- put i-th element as the last one
			a[n], a[i] = a[i], a[n]
			-- generate all permutations of the other elements
			permgen(a, n - 1)
			-- restore i-th element
			a[n], a[i] = a[i], a[n]
		end
	end
end
function printResult (a)
	for i,v in ipairs(a) do
		io.write(v, "/")
	end
	io.write("\n")
end
permgen ({1,2,3,4}, 4)
for p in perm{"a", "b", "c"} do
	printResult(p)
end

function receive (connection)
  return connection:receive(2^10)
end
--[[
function receive (connection)
	connection:timeout(0)-- do not block
	local s, status = connection:receive(2^10)
	if status == "closed" then
		coroutine.yield(connection)
	end
	return s, status
end
--]]
host = "labs.rhomobi.com"
file = "/srcrho/data1/rholog.txt"
c = assert(socket.connect(host, 80))
print(type(c))
c:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
local s, status = receive(c)
print(s)
print(status)
c:close()

function download (host, file)
	local c = assert(socket.connect(host, 80))
	local count = 0-- counts number of bytes read
	c:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
	while true do
		local s, status = c:receive(2^10)
		count = count + string.len(status)
		if status == "closed" then
			break
		end
	end
	c:close()
	print(file, count)
end

--download(host, file)
threads = {}-- list of all live threads
function get (host, file)
	-- create coroutine
	local co = coroutine.create(function ()
		download(host, file)
	end)
	-- insert it in the list
	table.insert(threads, co)
end

function dispatcher ()
	while true do
		local n = table.getn(threads)
		if n == 0 then break end-- no more threads to run
		local connections = {}
		for i=1,n do
			local status, res = coroutine.resume(threads[i])
			if not res then-- thread finished its task?
				table.remove(threads, i)
				break
			else-- timeout
				table.insert(connections, res)
			end
		end
		if table.getn(connections) == n then
			socket.select(connections)
		end
	end
end


--[[
local http = require "socket.http"
local ltn12 = require "ltn12"
--local util = require "util"
    local reqbody = "anid=&protocol=1&guid=dfe49e55b63f2cf93eb9aabe44b6d9dc5286bbbedfcbf1c75b95f7a4f7439029&d_type=phone&os_version=6.1&ate=1&asid=079ABF64-A23A-4E3B-9000-19A4A608CCBE&affiliate=&modin=7c78d075f379db2f40c9f68df857cb87&os=ios&d_id=107b2734fdb7898251f62d229168484a9d14f7fb654d02d957b30c9f22bb094c&d_code=1E5D02FF-63F3-43A0-A2BF-80E63E00F76C&pn_device_id=&name_hint=iPhone%20Simulator&d_sig=dfe49e55b63f2cf93eb9aabe44b6d9dc5286bbbedfcbf1c75b95f7a4f7439029&hdid=62624a01f8715f2b838224a4a285746d&tracker=&appid=536381662&odin=1da61c680b672c4e114df45cd5f8f0aa9b088338&model=iPhone%20Simulator&ver=15&campaign=&imei=&store_type=apple&"
    local respbody = {} 
    local  body, code, headers, status = http.request {
        method = "POST",
        url = "https://freshdeck.idle-gaming.com/api/guest_session/",
        source = ltn12.source.string(reqbody),
        headers = 
                {
                        ["Accept"] = "*/*",
                        ["Accept-Encoding"] = "gzip, deflate",
                        ["Accept-Language"] = "en-us",
                        ["Content-Type"] = "application/x-www-form-urlencoded",
                        ["content-length"] = string.len(reqbody)
                },
        sink = ltn12.sink.table(respbody)
    }

    LOGINFO('body:' .. tostring(body))
    LOGINFO('code:' .. tostring(code))
    LOGINFO('headers:' .. util.tableToString(headers))
    LOGINFO('status:' .. tostring(status))

-- ]]