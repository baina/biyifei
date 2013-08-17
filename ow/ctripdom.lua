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
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(1000) -- 1 sec
-- nosql connect
local ok, err = red:connect("10.124.20.136", 6379)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
local byfs = ngx.shared.biyifei;
-- end of nosql init.
if ngx.var.request_method == "POST" then
	local uri = ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.gdate .. "/"
	local session = ngx.md5(ngx.now() .. uri);
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	if pcontent then
		local tbody = pcontent;
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
			if rfid[fid] ~= true then
				rfid[fid] = true
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
		for k, v in pairs(rfid) do
			ngx.say(k)
		end
		--[[
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
		--]]
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