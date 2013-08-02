-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for bestfly service
-- load library
local JSON = require("cjson");
local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted airports"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get Prices from extension is no response"});
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
local ok, err = red:connect("127.0.0.1", 6389)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
-- end of nosql init.
-- init the DICT.
local byfs = ngx.shared.biyifei;
local port = ngx.shared.airport;
local porg = port:get(string.upper(ngx.var.org));
local pdst = port:get(string.upper(ngx.var.dst));
local city = ngx.shared.citycod;
local torg = city:get(string.upper(ngx.var.org));
local tdst = city:get(string.upper(ngx.var.dst));
if ngx.var.request_method == "GET" then
	if porg or pdst then
		ngx.print(error001);
	else
		-- ngx.print(torg, tdst);
		-- ngx.print("\r\n---------------------\r\n");
		-- location ~ '^/extctrip/FlightSearch/([a-zA-Z]{3,4})/([A-Za-z0-9]{3})/([A-Za-z0-9]{3})/([a-zA-Z]{2})/([0-9]{8})$'
		-- nginx location for ctirp extension.
		if torg and tdst then
			local uri = "/extctrip/FlightSearch/dom/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.rt .. "/" .. ngx.var.date;
			local session = ngx.md5(ngx.now() .. uri);
			local res = ngx.location.capture(uri);
			if res.status == 200 then
				-- ngx.print(res.body);
				local tbody = res.body;
				-- search for substatement having the tag "RequestResponse"
				local idx1 = string.find(tbody, "<RequestResponse");
				local idx2 = string.find(tbody, "</RequestResponse>");
				local prdata = string.sub(tbody, idx1, idx2+17);
				local pr_xml = xml.eval(prdata);
				local xscene = pr_xml:find("DomesticFlightRoute");
				-- ngx.say(xml.str(xscene));
				local rcs = tonumber(xscene[1][1]);
				local rc = 1;
				while rc <= rcs do
					-- echo segments info at 20130706 by huangqi.
					local seginf = {};
					-- echo policy info of limitinfo and prices & tax
					local limtab = {};
					local pritab = {};
					-- echo bunks_idx for price.
					local bunktb = {};
					local fltkey = {};
					local fid = "";
					for k, v in pairs(xscene[4][rc]) do
						-- local tmpseg = {};
						if k > 0 then
							if type(v) == "table" then
								if v[0] == "DPortCode" then
									fltkey[1] = v[1];
									seginf[v[0]] = v[1];
								end
								if v[0] == "TakeOffTime" then
									local t = string.find(v[1], "T")
									local m = string.sub(v[1], t+1, -4);
									t = string.find(m, ":")
									fltkey[2] = string.sub(m, 1, t-1) .. string.sub(m, t+1, -1)
									seginf[v[0]] = v[1];
								end
								if v[0] == "APortCode" then
									fltkey[3] = v[1];
									seginf[v[0]] = v[1];
								end
								if v[0] == "ArriveTime" then
									local t = string.find(v[1], "T")
									local m = string.sub(v[1], t+1, -4);
									t = string.find(m, ":")
									fltkey[4] = string.sub(m, 1, t-1) .. string.sub(m, t+1, -1)
									seginf[v[0]] = v[1];
								end
								if v[0] == "DepartCityCode" or v[0] == "ArriveCityCode" or v[0] == "CraftType" or v[0] == "AirlineCode" or v[0] == "MealType" or v[0] == "StopTimes" then
									seginf[v[0]] = v[1];
								end
								if v[0] == "Flight" then
									seginf["FlightNo"] = v[1];
								end
								if v[0] == "Class" or v[0] == "SubClass" or v[0] == "DisplaySubclass" or v[0] == "Quantity" or v[0] == "IsStandardClass" then
									bunktb[v[0]] = v[1];
								end
								if v[0] == "Rate" or v[0] == "Price" or v[0] == "StandardPrice" or v[0] == "ChildStandardPrice" or v[0] == "BabyStandardPrice" or v[0] == "AdultTax" or v[0] == "BabyTax" or v[0] == "ChildTax" or v[0] == "AdultOilFee" or v[0] == "BabyOilFee" or v[0] == "ChildOilFee" or v[0] == "PriceType" or v[0] == "ProductType" or v[0] == "IsLowestPrice" or v[0] == "IsLowestCZSpecialPrice" then
									pritab[v[0]] = v[1];
								end
								if v[0] == "Nonrer" or v[0] == "Nonend" or v[0] == "Nonref" or v[0] == "Rernote" or v[0] == "Endnote" or v[0] == "Refnote" or v[0] == "Remarks" or v[0] == "BeforeFlyDate" or v[0] == "InventoryType" or v[0] == "NeedApplyString" or v[0] == "CanUpGrade" or v[0] == "CanSeparateSale" or v[0] == "OnlyOwnCity" or v[0] == "PolicyID" then
									limtab[v[0]] = v[1];
								end
							end
						end
					end
					-- caculate the fid
					-- PEK1830/CAN2140 ow example.
					fid = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
					-- put the fids into redis sets
					local res, err = red:sadd("fid:" .. session, fid)
					if res then
						red:expire("fid:" .. session, 120)
					else
						ngx.say("failed to SET fid index for Caculate the fid of China: ", err);
						return
					end
					-- echo bunks_index.
					local tmptab = {};
					local bolfid = byfs:get(fid .. ":bunks");
					if not bolfid then
						local cntmp = {};
						table.insert(cntmp, bunktb)
						table.insert(tmptab, cntmp)
						byfs:set(fid .. ":bunks", JSON.encode(tmptab));
					else
						local tmpfid = JSON.decode(bolfid);
						local cntmp = {};
						table.insert(cntmp, bunktb)
						table.insert(tmpfid, cntmp)
						byfs:replace(fid .. ":bunks", JSON.encode(tmpfid));
					end
					-- combinate the price & limit.
					local priceinfo = {};
					-- local tcnprices = {};
					local goalprice = {};
					priceinfo["priceinfo"] = pritab;
					priceinfo["salelimit"] = limtab;
					-- 20130708 by huangqi
					-- table.insert(tcnprices, priceinfo)
					goalprice["ctrip"] = priceinfo;
					-- begin to insert other ota price.
					-- 20130726 by huangqi
					-- get data by seginf["FlightNo"]
					local paddelong = {};
					paddelong["ctrip"] = priceinfo;
					local res, err = red:hget("elong:" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.date .. "/", seginf["FlightNo"])
					-- if res == null then its type is userdata or is string.
					if res ~= JSON.null then
						paddelong["elong"] = JSON.decode(res);
					end
					-- more ota
					local tmppri = {};
					local bolfid = byfs:get(fid .. ":price");
					if not bolfid then
						table.insert(tmppri, paddelong)
						-- ngx.say(JSON.encode(tmppri));
						byfs:set(fid .. ":price", JSON.encode(tmppri));
					else
						local tmpfid = JSON.decode(bolfid);
						table.insert(tmpfid, goalprice)
						byfs:replace(fid .. ":price", JSON.encode(tmpfid));
					end
					-- echo seginfo.
					local bolfid = byfs:get(fid .. ":seg");
					if not bolfid then
						byfs:set(fid .. ":seg", JSON.encode(seginf));
					end
					-- table.insert(seginf, tmpseg)
					rc = rc + 1;
					-- table.insert(bigtab, limtab)
					-- table.insert(bigtab, pritab)
				end
				-- echo the result in bigtab.
				local bigtab = {};
				-- local bigbunks = {};
				local fids, fide = red:smembers("fid:" .. session)
				if not fids then
					ngx.say("failed to smembers " .. session .. ":bunk", fide);
					return
				else
					-- ngx.print(JSON.encode(fids));
					local fidnum = table.getn(fids);
					local fidi = 1;
					while fidi <= fidnum do
						local ctrip = {};
						local tmpbunkstab = byfs:get(fids[fidi] .. ":bunks");
						-- table.insert(bigbunks, JSON.decode(tmptab))
						ctrip["bunks_idx"] = JSON.decode(tmpbunkstab);
						byfs:delete(fids[fidi] .. ":bunks");
						-- ngx.print(fids[fidi], tmptab);
						-- local bigprice = {};
						local tmppricetab = byfs:get(fids[fidi] .. ":price");
						-- local ctripdata = {};
						-- local tmppritab = {};
						-- tmppritab["ctrip"] = JSON.decode(tmppricetab);
						-- table.insert(ctripdata, JSON.decode(tmppricetab))
						ctrip["prices_data"] = JSON.decode(tmppricetab);
						-- table.insert(bigprice, JSON.decode(tmptab))
						byfs:delete(fids[fidi] .. ":price");
						-- segments
						local tmpseginfo = {};
						local tmpsegtab = byfs:get(fids[fidi] .. ":seg");
						table.insert(tmpseginfo, JSON.decode(tmpsegtab))
						byfs:delete(fids[fidi] .. ":seg");
						ctrip["checksum_seg"] = tmpseginfo;
						ctrip["flightline_id"] = ngx.md5(fids[fidi]);
						table.insert(bigtab, ctrip)
						fidi = fidi + 1;
					end
				end
				ngx.print(JSON.encode(bigtab));
			else
				ngx.print(error002);
			end
		else
			local res = ngx.location.capture("/extctrip/FlightSearch/intl/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.rt .. "/" .. ngx.var.date);
			if res.status == 200 then
				-- ngx.print(res.body);
				local tbody = res.body;
				-- search for substatement having the tag "RequestResponse"
				local idx1 = string.find(tbody, "<RequestResponse");
				local idx2 = string.find(tbody, "</RequestResponse>");
				local prdata = string.sub(tbody, idx1, idx2+17);
				local pr_xml = xml.eval(prdata);
				local xscene = pr_xml:find("IntlFlightSearchResponse");
				-- /RequestResponse/RequestResult/Response/IntlFlightSearchResponse/RecordsCount
				local rcs = tonumber(xscene[1][1]);
				local rc = 1;
				local bigtab = {};
				while rc <= rcs do
					-- echo segments info at 20130705 by huangqi.
					local seginf = {};
					local fid = "";
					-- segments for checkinfo
					-- /RequestResponse/RequestResult/Response/IntlFlightSearchResponse/ShoppingResults/ShoppingResultInfo/FlightInfos/FlightsInfo/Flights
					local segnum = table.getn(xscene[2][rc][1][1][3]);
					-- ngx.say(segnum);
					local fltseg = 1;
					while fltseg <= segnum do
						local tmpseg = {};
						local fltkey = {};
						for k, v in pairs(xscene[2][rc][1][1][3][fltseg]) do
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
							fid = fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
						else
							fid = fid .. "-" .. fltkey[1] .. fltkey[2] .. "/" .. fltkey[3] .. fltkey[4];
						end
						fltseg = fltseg + 1;
						table.insert(seginf, tmpseg)
					end
					-- echo policy info of limitinfo and prices & tax
					local limtab = {};
					local pritab = {};
					-- echo bunks_idx for price.
					local bunktb = {};
					local polnum = table.getn(xscene[2][rc][2]);
					local polidx = 1;
					while polidx <= polnum do
						local idxtab = {};
						local tmppri = {};
						for k, v in pairs(xscene[2][rc][2][polidx]) do
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
									end
								end
							end
						end
						-- echo bunks and Quantity of the bunk.
						local cangwei = xscene[2][rc][2][polidx]:find("FlightBaseInfos");
						local bunkidx = 1;
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
							-- ngx.say(xml.str(cangwei[bunkidx]));
							bunkidx = bunkidx + 1;
							table.insert(tbunks, tmpbunk)
						end
						table.insert(bunktb, tbunks)
						-- table.insert(limtab, idxtab)
						local priceinfo = {};
						-- local ctripdata = {};
						local tmppritab = {};
						priceinfo["priceinfo"] = tmppri;
						priceinfo["salelimit"] = idxtab;
						-- table.insert(ctripdata, priceinfo)
						tmppritab["ctrip"] = priceinfo;
						table.insert(pritab, tmppritab)
						polidx = polidx +1;
					end
					--[[
					ngx.print(JSON.encode(seginf));
					ngx.print("\r\n---------------------\r\n");
					ngx.print(JSON.encode(limtab));
					ngx.print("\r\n---------------------\r\n");
					ngx.print(JSON.encode(pritab));
					ngx.print("\r\n---------------------\r\n");
					ngx.print(JSON.encode(bunktb));
					ngx.print("\r\n---------------------\r\n");
					--]]
					local ctrip = {};
					ctrip["bunks_idx"] = bunktb;
					ctrip["checksum_seg"] = seginf;
					-- ngx.say(fid)
					ctrip["flightline_id"] = ngx.md5(fid);
					-- ctrip["limit"] = limtab;
					ctrip["prices_data"] = pritab;
					-- ngx.print(JSON.encode(ctrip));
					-- ngx.print("\r\n---------------------\r\n");
					table.insert(bigtab, ctrip)
					rc = rc + 1;
				end
				ngx.print(JSON.encode(bigtab));
			else
				ngx.print(error002);
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
	-- or just close the connection right away:
	-- local ok, err = red:close()
	-- if not ok then
		-- ngx.say("failed to close: ", err)
		-- return
	-- end
end
if ngx.var.request_method == "POST" then
	if porg or pdst then
		ngx.print(error001);
	else
		ngx.req.read_body();
		local pcontent = ngx.req.get_body_data();
		-- local puri = ngx.var.URI;
		-- local args = ngx.req.get_headers();
		if pcontent then
			ngx.print(pcontent);
		end
	end
end