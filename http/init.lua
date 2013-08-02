-- buyhome <huangqi@rhomobi.com> 20130706 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service
-- load city of cn.
local city = ngx.shared.citycod;
local port = ngx.shared.airport;
city:flush_all();
port:flush_all();
-- local file = io.open("config.json", "r");
-- local content = cjson.decode(file:read("*all"));
-- file:close();
-- load cncity.ini
local rfile = io.open("/Users/rhomobi/Documents/cncity.ini", "r");
-- print(type(rfile));
-- local citytab = {};
for line in rfile:lines() do
	city:set(line, true);
end
io.close(rfile);
-- load airport.ini
local afile = io.open("/Users/rhomobi/Documents/airport.ini", "r");
for line in afile:lines() do
	port:set(line, true);
end
io.close(afile);