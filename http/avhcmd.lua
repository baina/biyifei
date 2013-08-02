-- buyhome <huangqi@rhomobi.com> 20130321 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- avh of hangxin interface
-- load library
local JSON = require("cjson");
local redis = require "resty.redis"
local http = require "resty.http"
local memcached = require "resty.memcached"
--[[
local p = "/usr/local/openresty/lualib/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s?/init.lua;%s",
    p, p, m_package_path)
local mongo = require "resty.mongol"
]]
-- originality
-- local sbeId = "CANZHTD01";
-- local Pwd = "canzhtd01";
local sbeId = "12zhtd0106";
local Pwd = "12345678";
local authclientinfo = sbeId .. "#" .. ngx.md5(Pwd) .. "#" .. "23456915";
local clientinfo = ngx.encode_base64(authclientinfo);
local error001 = JSON.encode({ ["errorcode"] = 1, ["description"] = "Get token from hangxin is no response"});
local error002 = JSON.encode({ ["errorcode"] = 2, ["description"] = "Get avhdata from hangxin is no response"});
function error003 (mes)
	local res = JSON.encode({ ["errorcode"] = 3, ["description"] = mes});
	return res
end
-- ready to connect to master redis.
local red, err = redis:new()
if not red then
	ngx.say("failed to instantiate redis: ", err)
	return
end
-- ready to connect to memcached
local memc, err = memcached:new()
if not memc then
	ngx.say("failed to instantiate memc: ", err)
	return
end
--[[
-- ready to connect to mongodb
local mog, err = mongo:new()
if not mog then
	ngx.say("failed to instantiate mongodb: ", err)
	return
end
mog:set_timeout(1000)
]]
-- lua socket timeout
memc:set_timeout(1000) -- 1 sec
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
red:set_timeout(600)
-- nosql connect
local ok, err = red:connect("127.0.0.1", 6389)
if not ok then
	ngx.say("failed to connect redis: ", err)
	return
end
local ok, err = memc:connect("127.0.0.1", 11211)
if not ok then
	ngx.say("failed to connect memcache: ", err)
	return
end
--[[
local ok, err = mog:connect("127.0.0.1", 27017)
if not ok then
    ngx.say("failed to connect mongodb: ", err)
end
]]
-- end of nosql init.
function DEACTIVE (id)
	local basetime = ngx.localtime();
	-- INITD sbe
	local ACCOUNT_DEACTIVE = JSON.encode({ ["clientInfo"] = clientinfo, ["timestamp"] = basetime, ["token"] = null, ["serviceName"] = "ACCOUNT_DEACTIVE"});
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = "http://113.108.131.149:8060/sbe",
		--- proxy = "http://127.0.0.1:8888",
		--- timeout = 3000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		-- headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
		body = ACCOUNT_DEACTIVE,
	}
	local resbody = JSON.decode(body);
	return resbody.resultCode
end
function ACTIVE (id)
	local basetime = ngx.localtime();
	-- INITD sbe
	local ACCOUNT_ACTIVE = JSON.encode({ ["clientInfo"] = clientinfo, ["timestamp"] = basetime, ["token"] = null, ["serviceName"] = "ACCOUNT_ACTIVE"});
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = "http://113.108.131.149:8060/sbe",
		--- proxy = "http://127.0.0.1:8888",
		--- timeout = 3000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		-- headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
		body = ACCOUNT_ACTIVE,
	}
	local resbody = JSON.decode(body);
	return resbody.resultCode
end
function gettoken (id)
	local basetime = ngx.localtime();
	local errorcodeNo = 404;
	-- GET Token
	local APPTOKEN = JSON.encode({ ["authenticator"] = clientinfo, ["timestamp"] = basetime, ["token"] = null, ["serviceName"] = "APPLY_TOKEN", ["class"] = "com.travelsky.sbeclient.authorization.AuthorizationRequest"});
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = "http://113.108.131.149:8060/sbe",
		--- proxy = "http://127.0.0.1:8888",
		--- timeout = 3000,
		method = "POST", -- POST or GET
		-- add post content-type and cookie
		-- headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
		body = APPTOKEN,
	}
	if code == 200 then
		local resbody = JSON.decode(body);
		if resbody.token ~= JSON.null then
			local ok, err = memc:set(id, resbody.token)
			return resbody.resultCode, resbody.token
		else
			local deres = DEACTIVE(sbeId);
			local acres = ACTIVE(sbeId);
			if acres == 0 then
				local hc1 = http:new()
				local ok, code, headers, status, body = hc1:request {
					url = "http://113.108.131.149:8060/sbe",
					--- proxy = "http://127.0.0.1:8888",
					--- timeout = 3000,
					method = "POST", -- POST or GET
					-- add post content-type and cookie
					-- headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
					body = APPTOKEN,
				}
				if code == 200 then
					local resbody = JSON.decode(body);
					if resbody.token ~= JSON.null then
						local ok, err = memc:set(id, resbody.token)
						return resbody.resultCode, resbody.token
					else
						return errorcodeNo, "failed to Get Token, Please check your sbeid if it is can be DEACTIVE!"
					end
				else
					return errorcodeNo, status
				end
			else
				return errorcodeNo, "failed to ACTIVE!"
			end
		end
	else
		return errorcodeNo, status
	end
end
if ngx.var.request_method == "POST" then
	ngx.exit(ngx.HTTP_FORBIDDEN);
	--[[
    local key = "SNzKrqjakN"
    local src = "ifl"
    local digest = ngx.hmac_sha1(key, src)
    ngx.say(ngx.encode_base64(digest))
	
	local hashpwd = ngx.sha1_bin(key .. src)
	ngx.say(hashpwd)
	
	ngx.say(authclientinfo);
	ngx.say(clientinfo);
	
	-- mongodb
    local db = mog:new_db_handle("test")
	col = db:list()
    -- col = db:get_col("test")
    -- r = col:find_one({name="dog"})
    -- ngx.say(r["name"])
	ngx.say(col)
	]]
end
if ngx.var.request_method == "GET" then
	local basetime = ngx.localtime();
	local tres, tflags, terr = memc:get(sbeId)
	-- ngx.say(tres)
	if tres then
		local avhdata = JSON.encode({ ["org"] = ngx.var.org,  ["dst"] = ngx.var.dst, ["airline"] = ngx.var.airline, ["date"] = tonumber(ngx.var.date), ["direct"] = null, ["fltNo"] = null, ["ibeFlag"] = "false", ["nonstop"] = "false", ["officeNo"] = "CAN911", ["page"] = 0, ["serviceName"] = "SBE_AV", ["stopCity"] = "", ["timestamp"] = basetime, ["token"] = tres});
		local skybusAuth = ngx.md5(tres .. "_" .. avhdata);
		local hc = http:new()
		local ok, code, headers, status, body1  = hc:request {
			url = "http://113.108.131.149:8060/sbe",
			--- proxy = "http://127.0.0.1:8888",
			--- timeout = 3000,
			method = "POST", -- POST or GET
			-- add post content-type and cookie
			headers = { skybusAuth = skybusAuth, ["Content-Type"] = "application/json" },
			body = avhdata,
		}
		if body1 then
			local resbody1 = JSON.decode(body1);
			local resultcode = tonumber(resbody1.resultCode);
			if resultcode == 20005 then
				local resultCode1, token1 = gettoken(sbeId);
				if resultCode1 == 404 then
					-- Apply token get no response.
					ngx.print(error003(token1));
				else
					local avhdata1 = JSON.encode({ ["org"] = ngx.var.org,  ["dst"] = ngx.var.dst, ["airline"] = ngx.var.airline, ["date"] = tonumber(ngx.var.date), ["direct"] = null, ["fltNo"] = null, ["ibeFlag"] = "false", ["nonstop"] = "false", ["officeNo"] = "CAN911", ["page"] = 0, ["serviceName"] = "SBE_AV", ["stopCity"] = "", ["timestamp"] = basetime, ["token"] = token1});
					local skybusAuth1 = ngx.md5(token1 .. "_" .. avhdata1);
					-- ngx.say(avhdata1)
					-- ngx.say(skybusAuth1)
					local hc1 = http:new()
					local ok1, code1, headers, status, body1  = hc1:request {
						url = "http://113.108.131.149:8060/sbe",
						--- proxy = "http://127.0.0.1:8888",
						--- timeout = 3000,
						method = "POST", -- POST or GET
						-- add post content-type and cookie
						headers = { skybusAuth = skybusAuth1, ["Content-Type"] = "application/json" },
						body = avhdata1,
					}
					if body1 then
						local resbody1 = JSON.decode(body1);
						local resultcode1 = tonumber(resbody1.resultCode);
						if resultcode2 == 0 then
							ngx.print(body2);
						else
							local res = ngx.location.capture("/data-avh/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.airline .. "/" .. ngx.var.date .. "/");
							if res.status == 200 then
								ngx.print(res.body);
							end
						end
					else
						ngx.print(error002);
					end
				end
			else
				if resultcode == 0 then
					ngx.print(body1);
				else
					local res = ngx.location.capture("/data-avh/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.airline .. "/" .. ngx.var.date .. "/");
					if res.status == 200 then
						ngx.print(res.body);
					end
				end
			end
		else
			ngx.print(error002);
		end
	else
		local resultCode1, token1 = gettoken(sbeId);
		if resultCode1 == 404 then
			-- Apply token get no response.
			ngx.print(error003(token1));
		else
			local avhdata1 = JSON.encode({ ["org"] = ngx.var.org,  ["dst"] = ngx.var.dst, ["airline"] = ngx.var.airline, ["date"] = tonumber(ngx.var.date), ["direct"] = null, ["fltNo"] = null, ["ibeFlag"] = "false", ["nonstop"] = "false", ["officeNo"] = "CAN911", ["page"] = 0, ["serviceName"] = "SBE_AV", ["stopCity"] = "", ["timestamp"] = basetime, ["token"] = token1});
			local skybusAuth1 = ngx.md5(token1 .. "_" .. avhdata1);
			-- ngx.say(avhdata1)
			-- ngx.say(skybusAuth1)
			local hc1 = http:new()
			local ok1, code1, headers, status, body1  = hc1:request {
				url = "http://113.108.131.149:8060/sbe",
				--- proxy = "http://127.0.0.1:8888",
				--- timeout = 3000,
				method = "POST", -- POST or GET
				-- add post content-type and cookie
				headers = { skybusAuth = skybusAuth1, ["Content-Type"] = "application/json" },
				body = avhdata1,
			}
			if body1 then
				local resbody1 = JSON.decode(body1);
				local resultcode1 = tonumber(resbody1.resultCode);
				if resultcode2 == 0 then
					ngx.print(body2);
				else
					local res = ngx.location.capture("/data-avh/" .. ngx.var.org .. "/" .. ngx.var.dst .. "/" .. ngx.var.airline .. "/" .. ngx.var.date .. "/");
					if res.status == 200 then
						ngx.print(res.body);
					end
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
		ngx.say("failed to set keepalive: ", err)
		return
	end
	-- or just close the connection right away:
	-- local ok, err = red:close()
	-- if not ok then
		-- ngx.say("failed to close: ", err)
		-- return
	-- end
end