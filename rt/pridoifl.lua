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
local ok, err = red:connect("127.0.0.1", 6379)
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
			-- local session = ngx.md5(ngx.now() .. uri);
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
				local rfid = {};
				local dfid = {};
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
					-- put the fids into rfid instead of redis sets
					if rfid[fid] ~= true then
						rfid[fid] = true
					end
					-- echo bunks_index.
					local tmptab = {};
					-- local bolfid = byfs:get(fid .. ":bunks");
					-- local bolfid = {};
					local bolfid = dfid[fid .. ":bunks"]
					if bolfid == nil then
						local cntmp = {};
						table.insert(cntmp, bunktb)
						table.insert(tmptab, cntmp)
						-- byfs:set(fid .. ":bunks", JSON.encode(tmptab));
						dfid[fid .. ":bunks"] = tmptab;
					else
						-- local tmpfid = JSON.decode(bolfid);
						local tmpfid = bolfid;
						local cntmp = {};
						table.insert(cntmp, bunktb)
						table.insert(tmpfid, cntmp)
						-- byfs:replace(fid .. ":bunks", JSON.encode(tmpfid));
						dfid[fid .. ":bunks"] = tmpfid;
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
					--[[
					local res, err = red:hget("elong:" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.date .. "/", seginf["FlightNo"])
					-- if res == null then its type is userdata or is string.
					if res ~= JSON.null then
						paddelong["elong"] = JSON.decode(res);
					end
					--]]
					-- more ota insert first index.
					local tmppri = {};
					local bolfid = dfid[fid .. ":price"]
					-- local bolfid = byfs:get(fid .. ":price");
					if bolfid == nil then
						table.insert(tmppri, paddelong)
						-- ngx.say(JSON.encode(tmppri));
						-- byfs:set(fid .. ":price", JSON.encode(tmppri));
						dfid[fid .. ":price"] = tmppri;
					else
						-- local tmpfid = JSON.decode(bolfid);
						local tmpfid = bolfid;
						table.insert(tmpfid, goalprice)
						-- byfs:replace(fid .. ":price", JSON.encode(tmpfid));
						dfid[fid .. ":price"] = tmpfid;
					end
					-- echo seginfo.
					-- local bolfid = byfs:get(fid .. ":seg");
					local bolfid = dfid[fid .. ":seg"]
					if bolfid == nil then
						-- byfs:set(fid .. ":seg", JSON.encode(seginf));
						dfid[fid .. ":seg"] = seginf;
					end
					-- table.insert(seginf, tmpseg)
					rc = rc + 1;
					-- table.insert(bigtab, limtab)
					-- table.insert(bigtab, pritab)
				end
				-- echo the result in bigtab.
				local bigtab = {};
				for k, v in pairs(rfid) do
					-- ngx.print(k)
					local ctrip = {};
					-- local tmpbunkstab = byfs:get(k .. ":bunks");
					-- local tmpbunkstab = dfid[fid .. ":bunks"];
					-- table.insert(bigbunks, JSON.decode(tmptab))
					-- ctrip["bunks_idx"] = JSON.decode(tmpbunkstab);
					ctrip["bunks_idx"] = dfid[k .. ":bunks"];
					-- byfs:delete(k .. ":bunks");
					-- ngx.print(fids[fidi], tmptab);
					-- local bigprice = {};
					-- local tmppricetab = byfs:get(k .. ":price");
					-- local ctripdata = {};
					-- local tmppritab = {};
					-- tmppritab["ctrip"] = JSON.decode(tmppricetab);
					-- table.insert(ctripdata, JSON.decode(tmppricetab))
					-- ctrip["prices_data"] = JSON.decode(tmppricetab);
					ctrip["prices_data"] = dfid[k .. ":price"]
					-- table.insert(bigprice, JSON.decode(tmptab))
					-- byfs:delete(k .. ":price");
					-- segments
					local tmpseginfo = {};
					-- local tmpsegtab = byfs:get(k .. ":seg");
					-- local tmpsegtab = dfid[fid .. ":seg"]
					table.insert(tmpseginfo, dfid[k .. ":seg"])
					-- byfs:delete(k .. ":seg");
					ctrip["checksum_seg"] = tmpseginfo;
					ctrip["flightline_id"] = ngx.md5(k);
					table.insert(bigtab, ctrip)
				end
				if table.getn(bigtab) > 0 then
					ngx.print(JSON.encode(bigtab));
				else
					ngx.print(error002);
				end
			else
				ngx.print(error002);
			end
		else
			local res = ngx.location.capture("/data-ifl/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.gdate .. "/" .. ngx.var.bdate .. "/");
			if res.status == 200 then
				-- ngx.print(res.body);
				local tbody = JSON.decode(res.body);
				if tbody.resultCode == 1 or tbody.resultCode == 2 then
					ngx.exit(ngx.HTTP_MOVED_TEMPORARILY);
				else
					ngx.print(res.body);
				end
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