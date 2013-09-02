-- buyhome <huangqi@rhomobi.com> 20130705 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/
-- price of extension for elong website : http://flight.elong.com/beijing-shanghai/cn_day19.html
-- load library
local JSON = require("cjson");
-- local xml = require("LuaXml");
local redis = require "resty.redis"
local http = require "resty.http"
-- local ltn12 = require "ltn12"

-- originality
local error001 = JSON.encode({ ["resultCode"] = 1, ["description"] = "No response because you has inputted error"});
local error002 = JSON.encode({ ["resultCode"] = 2, ["description"] = "Get cityDicts from ctrip.com is no response"});
function error003 (mes)
	local res = JSON.encode({ ["resultCode"] = 3, ["description"] = mes});
	return res
end
if ngx.var.request_method == "GET" then
	local hc = http:new()
	local ok, code, headers, status, body = hc:request {
		url = "http://flights.ctrip.com/international/tools/GetCities.ashx?s=" .. ngx.var.qkey .. "&a=0&t=" .. ngx.var.char,
		-- url = "http://labs.rhomobi.com:18081/rholog",
		-- proxy = "http://" .. ngx.decode_base64(ngx.var.proxy),
		timeout = 3000,
		method = "GET", -- POST or GET
		-- add post content-type and cookie
		headers = { ["Host"] = "flight.ctrip.com", ["User-Agent"] = "Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-CN; rv:1.9.1.6) Gecko/20091201 Firefox/3.5.6"},
		-- body = ltn12.source.string(form_data),
		-- body = form_data,
	}
	if code == 200 and body ~= nil then
		local i = string.find(body, 'Response=');
		if i ~= nil then
			body = string.sub(body, i+1, -1);
			ngx.print(body);
		else
			ngx.print(error002);
		end
	else
		ngx.print(error003(code, status))
	end
else
	ngx.exit(ngx.HTTP_FORBIDDEN);
end