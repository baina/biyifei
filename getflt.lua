-- buyhome <huangqi@rhomobi.com> 20130811 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service ifl's rt type.
-- load library
local JSON = require("cjson");
-- local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted fltID"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get fltID and it's segment from data-flt is no response"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- nosql connect
local ok, err = red:connect("192.168.13.2", 6389)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.

if ngx.var.request_method == "GET" then
	local res, err = red:zrange(ngx.var.rt .. ":" .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst), 0, -1)
	if not res then
		ngx.print(error003("failed to get FlightLine lists of " .. ngx.var.rt .. "/" .. string.upper(ngx.var.org) .. "/" .. string.upper(ngx.var.dst), err));
		return
	else
		local bigtab = {};
		for i = 1, table.getn(res) do
			local res, err = red:get("seg:" .. res[i])
			if not res then
				ngx.print(error003("failed to GET checksum_seg info: " .. res[i], err));
				return
			else
				if res ~= nil and res ~= JSON.null then
					local fid = "";
					local segs = JSON.decode(res);
					if ngx.var.rt == "ow" then
						local tmpfid = "";
						for i = 1, table.getn(segs) do
							local fltkey = {};
							for k, v in pairs(segs[i]) do
								if k == "DPort" then
									fltkey[1] = v;
									-- ngx.say(k, v)
								end
								if k == "DTime" then
									fltkey[2] = v;
								end
								if k == "APort" then
									fltkey[3] = v;
								end
								if k == "ATime" then
									fltkey[4] = v;
								end
							end
							if string.len(tmpfid) == 0 then
								tmpfid = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
							else
								tmpfid = tmpfid .. "-" .. fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
							end
						end
						fid = tmpfid;
					end
					if ngx.var.rt == "rt" then
						local tmpfid1 = "";
						local tmpfid2 = "";
						for i = 1, table.getn(segs) do
							local fltkey = {};
							for k, v in pairs(segs[i]) do
								if k == "DPort" then
									fltkey[1] = v;
									-- ngx.say(k, v)
								end
								if k == "DTime" then
									fltkey[2] = v;
								end
								if k == "APort" then
									fltkey[3] = v;
								end
								if k == "ATime" then
									fltkey[4] = v;
								end
							end
							if i <= table.getn(segs) / 2 then
								if string.len(tmpfid1) == 0 then
									tmpfid1 = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
								else
									tmpfid1 = tmpfid1 .. "-" .. fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
								end
							else
								if string.len(tmpfid2) == 0 then
									tmpfid2 = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
								else
									tmpfid2 = tmpfid2 .. "-" .. fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
								end
							end
							-- if i > table.getn(segs) / 2 then	
						end
						fid = tmpfid1 .. "," .. tmpfid2;
					end
					local tmptab = {};
					tmptab["flightline_id"] = ngx.md5(fid);
					tmptab["original_fid"] = fid;
					tmptab["checksum_seg"] = segs;
					table.insert(bigtab, tmptab)
				end
				-- ngx.print(res);
			end
		end
		if table.getn(bigtab) > 0 then
			ngx.print(JSON.encode(bigtab));
		else
			ngx.print(error002);
		end
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end
-- put it into the connection pool of size 512,
-- with 0 idle timeout
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive redis: ", err)
	return
end