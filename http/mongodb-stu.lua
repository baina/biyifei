-- local p = "/usr/local/openresty/lualib/"
local p = "/usr/local/webserver/lua/lib/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s",
    p, p, m_package_path)
local mongo = require "resty.mongol"



-- ready to connect to mongodb
local mog, err = mongo:new()
if not mog then
	ngx.say("failed to instantiate mongodb: ", err)
	return
end


-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1200) -- 1 sec
mog:set_timeout(1000) -- 1 sec



local ok, err = mog:connect("59.41.39.161", 9092)
if not ok then
    ngx.say("failed to connect mongodb: ", err)
end



local seginf = {};
-- segments for checkinfo
local segnum = table.getn(xscene[2][2][1][1][3]);
ngx.say(segnum);
local fltseg = 1;
while fltseg <= segnum do
	for k, v in pairs(xscene[2][2][1][1][3][fltseg]) do
		if k > 0 then
			if type(v) == "table" then
				seginf[v[0]] = v[1];
			end
		end
	end
	fltseg = fltseg + 1;
end
ngx.say(JSON.encode(seginf));




local cangwei = xscene[2][1][2][polidx]:find("FlightBaseInfos");
local bunkidx = 1;
-- local segnum = table.getn(xscene[2][1][1][polidx][3]);
local segnum = table.getn(xscene[2][1][1][1][3]);
ngx.say(segnum);
local tbunks = {};
while bunkidx <= segnum do
	local tmpbunk = {};
	for k, v in pairs(cangwei[bunkidx]) do
		if k > 0 then
			if type(v) == "table" then
				tmpbunk[v[0]] = v[1]
			end
		end
	end
	ngx.say(xml.str(cangwei[bunkidx]));
	bunkidx = bunkidx + 1;
	table.insert(tbunks, tmpbunk)
end
table.insert(bunktb, tbunks)






-- mongodb
local db = mog:new_db_handle("admin")
local ok, err = db:auth("bestfly", "b6x7p6")
if ok then
	local db = mog:new_db_handle("test")
	col = db:get_col("test")
end

-- r, err = col:delete({}, nil, true)
-- if not r then ngx.say("delete failed: "..err) end
--[[

local i, j
local t = {}
for i = 1,10 do
    j = 10 - i
    --r, err = col:insert({{name="dog",n=i,m=j}}, nil, true)
    --if not r then ngx.say("insert failed: "..err) end
    table.insert(t, {name="dog",n=i,m=j})
end
r, err = col:insert(t, nil, true)
if not r then ngx.say("insert failed: "..err) end
ngx.say(r)
]]

r, err = col:insert({{name="dog",n=20,m=30}, {name="cat"}}, 
            nil, true)
if not r then ngx.say("insert failed: "..err) end
ngx.say(r)

r = col:find({name="dog"}, nil, 100)
-- r:limit(5)
for k,v in r:pairs() do
    ngx.say(v["n"])
    -- break
end

r = col:find_one({name="dog"})

-- ngx.say(r["_id"].id)
ngx.say(r["_id"]:tostring())
ngx.say(r["_id"]:get_ts())
ngx.say(r["_id"]:get_hostname())
ngx.say(r["_id"]:get_pid())
ngx.say(r["_id"]:get_inc())
ngx.say(r["name"])


local ok, err = mog:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive mongodb: ", err)
	return
end
