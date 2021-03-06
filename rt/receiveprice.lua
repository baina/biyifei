-- buyhome <huangqi@rhomobi.com> 20130811 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service ifl's rt type.
-- load library
local JSON = require("cjson");
local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
local zlib = require 'zlib'
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from extension is no response"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate main redis: ", err)
	return
end
local ota, err = redis:new()
if not red then
	ngx.say("failed to instantiate otas redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(3000) -- 1 sec
ota:set_timeout(3000) -- 1 sec
-- nosql connect
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
	ngx.say("failed to connect main redis: ", err)
	return
end
local ok, err = ota:connect("192.168.13.2", 6389)
if not ok then
	ngx.say("failed to connect otas redis: ", err)
	return
end
-- end of nosql init.
-- getfid function by FlightLineID, seginf
function getfid(FlightLineID, seginf)
	local fltid = "";
	local getfidres, getfiderr = red:get("flt:" .. FlightLineID .. ":id")
	if not getfidres then
		ngx.print(error003("failed to get the flt:" .. FlightLineID .. ":id: ", getfiderr))
		return
	end
	-- ngx.print(getfidres);
	-- ngx.print("\r\n---------------------\r\n");
	if tonumber(getfidres) == nil then
		-- fare:id INCR
		-- local farecounter, cerror = red:incr("next.fare.id")
		local farecounter, cerror = red:incr("flt:id")
		if not farecounter then
			ngx.print(error003("failed to INCR flt Line: ", cerror));
			return
		else
			local resultsetnx, fiderror = red:setnx("flt:" .. FlightLineID .. ":id", farecounter)
			if not resultsetnx then
				ngx.print(error003("failed to SETNX FlightLineID: " .. FlightLineID, fiderror));
				return
			end
			-- ngx.print("INCR fare result: ", farecounter);
			-- ngx.print("\r\n---------------------\r\n");
			-- ngx.print("SETNX fid result: ", resultsetnx);
			-- ngx.print("\r\n---------------------\r\n");
			-- if resultsetnx ~= 1 that is SETNX is NOT sucess.
			if resultsetnx == 1 then
				fltid = farecounter;
			else
				fltid = red:get("flt:" .. FlightLineID .. ":id");
			end
			-- checksum_seg
			-- ngx.say(JSON.encode(seginf))
			local segstr = JSON.encode(seginf);
			local res, err = red:hset("seg:" .. fltid, ngx.md5(segstr), segstr)
			if not res then
				ngx.print(error003("failed to HSET checksum_seg info: " .. fltid, err));
				return
			end
			return fltid;
		end
	else
		fltid = tonumber(getfidres);
		return fltid;
	end
end
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = zlib.decompress(ngx.req.get_body_data());
	-- local pcontent = ngx.req.get_body_data();
	if pcontent then
		-- ngx.print(type(pcontent));
		local pr_xml = xml.eval(pcontent);
		local xscene = pr_xml:find("IntlFlightSearchResponse");
		local bigtab = {};
		for r = 1, xscene[1][1] do
			-- local xscene = pr_xml:find("ShoppingResultInfo");
			local pritab = {};
			local bunktb = {};
			local polnum = table.getn(xscene[2][r][2]);
			local polidx = 1;
			while polidx <= polnum do
				local idxtab = {};
				local tmppri = {};
				local tbunks = {};
				for k, v in pairs(xscene[2][r][2][polidx]) do
					if k > 0 then
						if type(v) == "table" then
							if v[0] ~= "FlightBaseInfos" and v[0] ~= "PriceInfos" then
								idxtab[v[0]] = v[1];
							else
								if v[0] == "PriceInfos" then
									for k, v in pairs(v[1]) do
										if k > 0 then
											if type(v) == "table" then
												tmppri[v[0]] = v[1]
											end
										end
									end
								end
								if v[0] == "FlightBaseInfos" then
									-- ngx.say(table.getn(v))
									for i = 1, table.getn(v) do
										local tmpbunk = {};
										for k, v in pairs(v[i]) do
											if k > 0 then
												if type(v) == "table" then
													-- ngx.say(v[0], v[1])
													tmpbunk[v[0]] = v[1]
												end
											end
										end
										table.insert(tbunks, tmpbunk)
									end
								end
							end
						end
					end
				end
				local priceinfo = {};
				local tmppritab = {};
				priceinfo["priceinfo"] = tmppri;
				priceinfo["salelimit"] = idxtab;
				tmppritab["ctrip"] = priceinfo;
				table.insert(pritab, tmppritab)
				table.insert(bunktb, tbunks)
				polidx = polidx + 1;
				-- ngx.say(JSON.encode(idxtab))
				-- ngx.say(JSON.encode(tmppri))
			end
			local gseginf = {};
			local bseginf = {};
			local gfid = "";
			local bfid = "";
			local fid = "";
			local fltscore = "";
			for i = 1, 2 do
				local tmpfid = "";
				for j = 1, table.getn(xscene[2][r][1][i][3]) do
					-- ngx.say(type(xscene[1][i][3][j]))
					local tmpseg = {};
					local fltkey = {};
					for k, v in pairs(xscene[2][r][1][i][3][j]) do
						if k > 0 then
							if type(v) == "table" then
								tmpseg[v[0]] = v[1];
								if v[0] == "DPort" then
									fltkey[1] = v[1];
								end
								if v[0] == "DTime" then
									fltkey[2] = v[1];
								end
								if v[0] == "APort" then
									fltkey[3] = v[1];
								end
								if v[0] == "ATime" then
									fltkey[4] = v[1];
								end
							end
						end
					end
					if string.len(fid) == 0 then
						table.insert(gseginf, tmpseg);
					else
						table.insert(bseginf, tmpseg);
					end
					if string.len(tmpfid) == 0 then
						tmpfid = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
						fltscore = tonumber(fltkey[2]);
					else
						tmpfid = tmpfid .. "-" .. fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
					end
				end
				if string.len(fid) == 0 then
					fid = tmpfid;
					gfid = tmpfid;
				else
					fid = fid .. "," .. tmpfid;
					bfid = tmpfid;
				end
				tmpfid = "";
			end
			-- Caculate FlightLineID
			local FlightLineID = ngx.md5(fid)
			local gFlightLineID = ngx.md5(gfid)
			local bFlightLineID = ngx.md5(bfid)
			local ctrip = {};
			ctrip["bunks_idx"] = bunktb;
			-- ctrip["limit"] = limtab;
			ctrip["prices_data"] = pritab;
			ctrip["flightline_id"] = FlightLineID;
			-- ctrip["checksum_seg"] = seginf;
			
			local gfltid = getfid(gFlightLineID, gseginf)
			local bfltid = getfid(bFlightLineID, bseginf)

			local tmpbid, terr = red:hget("rt:" .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst), gfltid)
			if not tmpbid then
				ngx.print(error003("failed to get tmpbid from " .. string.upper(ngx.var.org) .. "/" .. string.upper(ngx.var.dst) .. ":" .. gfltid, err));
				return
			else
				if tmpbid ~= JSON.null then
					tmpbid = JSON.decode(tmpbid);
					local rbid = {};
					for k, v in pairs(tmpbid) do
						rbid[v] = true;
					end
					if rbid[bfltid] ~= true then
						table.insert(tmpbid, bfltid);
						-- start to store the fltinfo.
						local res, err = red:hset("rt:" .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst), gfltid, JSON.encode(tmpbid))
						if not res then
							ngx.print(error003("failed to add tmpbid into " .. string.upper(ngx.var.org) .. "/" .. string.upper(ngx.var.dst) .. ":" .. gfltid, err));
							return
						end
					end
				else
					tmpbid = {};
					table.insert(tmpbid, bfltid);
					-- start to store the fltinfo.
					local res, err = red:hset("rt:" .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst), gfltid, JSON.encode(tmpbid))
					if not res then
						ngx.print(error003("failed to add tmpbid into " .. string.upper(ngx.var.org) .. "/" .. string.upper(ngx.var.dst) .. ":" .. gfltid, err));
						return
					end
				end
			end
			local res, err = red:hset("pri:rt:" .. gfltid .. ":" .. bfltid, ngx.var.gdate .. "/" .. ngx.var.bdate .. "/", JSON.encode(ctrip))
			if not res then
				ngx.print(error003("failed to HSET prices_data info: " .. fltid, err));
				return
			else
				-- ngx.print(JSON.encode(ctrip))
				table.insert(bigtab, ctrip)
			end
		end
		ngx.print(JSON.encode(bigtab));
	end
else
	-- ngx.exit(ngx.HTTP_FORBIDDEN);
	if tonumber(ngx.var.gdate) > tonumber(ngx.var.bdate) then
		ngx.print(error001);
	else
		local bigtab = {};
		-- kayak
		local kayak = {};
		local kay, krr = ota:hget('ota:' .. string.upper(ngx.var.org) .. ':' .. string.upper(ngx.var.dst) .. ':' .. 'kayak', ngx.var.gdate .. '/' .. ngx.var.bdate .. '/')
		if not kay then
			ngx.print(error003("failed to get otas prices from " .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst) .. ":" .. "kayak", err));
			return
		else
			-- ngx.say(kay)
			if kay ~= JSON.null and kay ~= nil then
				kay = JSON.decode(kay);
				for i = 1, table.getn(kay) do
					kayak[kay[i].flightline_id] = kay[i].strPrice;
				end
			end
		end
		-- start to Get the fltinfo.
		local res, err = red:hgetall("rt:" .. string.upper(ngx.var.org) .. ":" .. string.upper(ngx.var.dst))
		if not res then
			ngx.print(error003("failed to hget FlightLine combinations of " .. string.upper(ngx.var.org) .. "/" .. string.upper(ngx.var.dst), err));
			return
		else
			-- ngx.say(type(res))
			-- ngx.say(table.getn(res))
			local idxs = table.getn(res)
			for i = 1, idxs do
				if math.fmod(i, 2) == 0 then
					-- ngx.say(res[i-1])
					for k, v in pairs(JSON.decode(res[i])) do
						-- ngx.say(res[i-1], v)
						local pres, perr = red:hget("pri:rt:" .. res[i-1] .. ":" .. v, ngx.var.gdate .. "/" .. ngx.var.bdate .. "/")
						if not pres then
							ngx.print(error003("failed to HGET prices_data info: " .. res[i-1] .. ":" .. v, err));
							return
						else
							if pres ~= nil and pres ~= JSON.null then
								-- table.insert(bigtab, JSON.decode(pres))
								local pritab = JSON.decode(pres);
								-- store for getseg of res[i-1] .. v = flightline_id
								local r, e = red:setnx("seg:rt:" .. pritab.flightline_id, res[i-1] .. "," .. v)
								if not r then
									ngx.print(error003("failed to set seg_data_index of seg:rt: " .. pritab.flightline_id, err));
									return
								else
									if kayak[pritab.flightline_id] ~= nil then
										-- ngx.say(kayak[pritab.flightline_id])
										local kpri = {};
										local ky = {};
										kpri["Price"] = kayak[pritab.flightline_id]
										ky["priceinfo"] = kpri
										ky["salelimit"] = JSON.null;
										pritab.prices_data[1]["kayak"] = ky
										table.insert(bigtab, pritab)
									else
										table.insert(bigtab, JSON.decode(pres))
									end
								end
							end
						end
					end
				end
			end
			if table.getn(bigtab) > 0 then
				ngx.print(JSON.encode(bigtab));
			else
				ngx.print(error002);
			end
		end
	end
end
-- put it into the connection pool of size 512,
-- with 0 idle timeout
local ok, err = red:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive redis: ", err)
	return
end
local ok, err = ota:set_keepalive(0, 512)
if not ok then
	ngx.say("failed to set keepalive otas redis: ", err)
	return
end