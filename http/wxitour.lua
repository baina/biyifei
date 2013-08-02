-- buyhome <huangqi@rhomobi.com> 20130511 (v0.5.1)
-- License: same to the Lua one
-- TODO: copy the LICENSE file
-------------------------------------------------------------------------------
-- begin of the idea : http://rhomobi.com/topics/150
-- wx interface
local xml = require("LuaXml")
local JSON = require("cjson");
local http = require "resty.http"
local memcached = require "resty.memcached"
-- ready to connect to memcached
local memc, err = memcached:new()
if not memc then
	ngx.say("failed to instantiate memc: ", err)
	return
end
-- lua socket timeout
-- Sets the timeout (in ms) protection for subsequent operations, including the connect method.
memc:set_timeout(1000) -- 1 sec
local ok, err = memc:connect("127.0.0.1", 63286)
if not ok then
	ngx.say("failed to connect memcache: ", err)
	return
end
if ngx.var.request_method == "GET" then
	local args = ngx.req.get_uri_args()
	ngx.say(args.echostr)
	--[[
	for key, val in pairs(args) do
		if type(val) == "table" then
			ngx.say(key, ": ", table.concat(val, ", "))
		else
			ngx.say(key, ": ", val)
		end
	end
	--]]
end
if ngx.var.request_method == "POST" then
	ngx.req.read_body();
	local pcontent = ngx.req.get_body_data();
	local puri = ngx.var.URI;
	local args = ngx.req.get_headers();
	if pcontent then
		-- load XML data into local table xfile
		local wxdata = xml.eval(pcontent)
		-- ngx.say(pcontent)
		-- ngx.say(type(wxdata))
		-- search for substatement having the tag "MsgType"
		-- local xscene = xfile:find("MsgType")
		-- if this substatement is found...
		local wxtable = {};
		for k,v in pairs(wxdata) do
			if k > 0 then
				if type(v) == "table" then
					wxtable[v[0]] = v[1];
					--[[
					-- cancel the if check
					if v[0] == "MsgType" then
						motype = v[1]
					end
					--]]
				end
			end
		end
		local mo = wxtable.Content;
		local wx = wxtable.FromUserName;
		local mt = "";
		-- ngx.say(wxtable.MsgType, wxtable.FromUserName);
		if wxtable.MsgType ~= "text" then
			if wxtable.MsgType == "event" and wxtable.Event == "subscribe" then
				mt = "告诉你一个秘密，刚刚关注的是微信小纵，你可以把她当成出行小秘书，在微信上能帮你比较纵横b2b平台的机票价格！\n\n回复序号查询航班比价：\n\n[1]单程比价\n[2]往返比价\n[3]热点线路";
				ngx.print(([=[<xml>
				            <ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
				        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
			else
				mt = "亲，我还小不懂您老人家的意思呢，请跟我文字聊天吧！\n\n回复序号查询航班比价：\n\n[1]单程比价\n[2]往返比价\n[3]热点线路";
				-- ngx.print(mt)
				-- Define the main request tag and it\'s attributes

				--[[
				local request = xml.new("request")
				request["xmlns:jaxb"]="http://java.sun.com/xml/ns/jaxb"
				request["xmlns:xjc"]="http://java.sun.com/xml/ns/jaxb/xjc"
				request["xmlns"]="http://blahblahsystems.com/appconnect/request"
				request["xmlns:xsi"]="http://www.w3.org/2001/XMLSchema-instance"

				-- Define the header tag
				local header = xml.new("header")
				local credential = xml.new("credential")
				local body = xml.new("body")
				local operation = xml.new("operation")
				operation["action"]="create"

				--define the event tag and it\'s attributes
				local event = xml.new("event")
				event["xmlns"]="http://blahblahsystems.com/event"
				event["xmlns:blahblah"]="http://blahblahsystems.com/common"
				local blahblahID = xml.new("blahblah:identityObject")
				local blahblahREF = xml.new("blahblah:reference")
				blahblahREF["uniqueKey"]="eventId"

				header:append("correlationId")[1] = "121"
				header:append("destination")[1] = "appConnect"
				header:append("source")[1] = "app Connect XML File Builder"
				credential:append("name")[1] = "barry"
				credential:append("password")[1] = "b"
				header:append(credential)
				header:append("timestamp")[1] = "2009-04-03T09:00:00"
				header:append("replyTo")[1] = "response"
				request:append(header)
				operation:append("targetRef")[1] = "app_USR"
				operation:append("sourceRef")[1] = "NUMBER"
				blahblahREF:append("blahblah:value")[1] = "10005156"
				blahblahID:append(blahblahREF)
				event:append(blahblahID)
				event:append("blahblah:remarks")[1] = "app Connect testing. Cloned from another model event"
				operation:append(event)
				body:append(operation)
				request:append(body)


				local resp = xml.new("xml")
				resp:append("FromUserName")[1] = 123
				resp:append("CreateTime")[1] = ngx.now()
				resp:append("MsgType")[1] = "text"
				resp:append("Content")[1] = mt
				resp:append("FuncFlag")[1] = 0
				ngx.say('<?xml version="1.0" encoding="UTF-8"?>', xml.str(resp,0))
				ngx.print(xml.tag(wxdata,<![CDATA]>))
				ngx.print(xml.str(resp,0))

				--]]
				ngx.print(([=[<xml>
							<ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
						</xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
			end
		else
			-- ngx.print(JSON.encode(wxtable))
			-- ngx.say(mo)
			if tonumber(mo) ~= 1 and tonumber(mo) ~= 2 and tonumber(mo) ~= 3 then
				if string.len(mo) < 6 then
					mt = "亲，看不懂您老人家的论文呢，小纵很受伤:-(\n\n回复序号查询航班比价：\n\n[1]单程比价\n[2]往返比价\n[3]热点线路";
					ngx.print(([=[<xml>
				            <ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
				        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
				else
					local res, flags, err = memc:get(wx)
					if res then
						local xff80 = string.find(pcontent,"[\x80-\xff]");
						if xff80 ~= nil then
							mt = "亲，我还小看不懂中文呢，据说中文是一门很高级的语言:-)\n\n不久的将来小纵一定学会！";
							ngx.print(([=[<xml>
						            <ToUserName><![CDATA[%s]]></ToUserName>
									<FromUserName><![CDATA[%s]]></FromUserName>
									<CreateTime>%s</CreateTime>
									<MsgType><![CDATA[text]]></MsgType>
									<Content><![CDATA[%s]]></Content>
									<FuncFlag>0</FuncFlag>
						        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
						else
							-- can send wxinfo to biyifei system api.
							local hc = http:new()
							local ok, code, headers, status, body = hc:request {
								url = "http://192.168.13.2:8080/wxapi/FlightSearch/weixin",
								--- proxy = "http://127.0.0.1:8888",
								--- timeout = 3000,
								method = "POST", -- POST or GET
								-- add post content-type and cookie
								headers = { ["Content-Type"] = "application/xml" },
								body = pcontent,
							}
							if body then
								local wname = "/data/logs/rholog.txt"
								local wfile = io.open(wname, "w+");
								wfile:write(os.date());
								wfile:write("\r\n---------------------\r\n");
								wfile:write(pcontent);
								wfile:write("\r\n---------------------\r\n");
								wfile:write(ngx.var.remote_addr);
								wfile:write("\r\n---------------------\r\n");
								wfile:write(puri);
								wfile:write("\r\n---------------------\r\n");
								for k, v in pairs(args) do
									wfile:write(k .. ":" .. v .. "\n");
								end
								wfile:write("\r\n---------------------\r\n");
								wfile:write(body .. "\n");
								io.close(wfile);
							end
							if code == 200 then
								ngx.print(body);
							end
						end
					else
						mt = "亲，在纵横没有捷径！拜托按次序来...\n\n回复序号查询航班比价：\n\n[1]单程比价\n[2]往返比价\n[3]热点线路";
						ngx.print(([=[<xml>
				        		<ToUserName><![CDATA[%s]]></ToUserName>
								<FromUserName><![CDATA[%s]]></FromUserName>
								<CreateTime>%s</CreateTime>
								<MsgType><![CDATA[text]]></MsgType>
								<Content><![CDATA[%s]]></Content>
								<FuncFlag>0</FuncFlag>
				        		</xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
					end
				end
			else
				if tonumber(mo) == 1 then
					local ok, err = memc:set(wx, mo)
					mt = "单程航班全球有200多万条线路，小纵很轻松:-)\n\n请连续输入出发城市到达城市，如：“广州纽约”。\n\n纵横给您加油！";
					ngx.print(([=[<xml>
				            <ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
				        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
				end
				if tonumber(mo) == 2 then
					local ok, err = memc:set(wx, mo)
					mt = "往返航班全球超500多万条线路，小纵很辛苦:-)\n\n请连续输入出发城市到达城市和目的地停留天数(默认3天)\n\n如：“广州新加坡3”\n\n纵横给您加油！";
					ngx.print(([=[<xml>
				            <ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
				        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
				end
				if tonumber(mo) == 3 then
					mt = "纵横day day up，敬请期待...";
					ngx.print(([=[<xml>
				            <ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[text]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
				        </xml>]=]):format(wxtable.FromUserName, wxtable.ToUserName, ngx.now(), mt))
				end
			end
		end
	end
	-- put it into the connection pool of size 512,
	-- with 0 idle timeout
	local ok, err = memc:set_keepalive(0, 512)
	if not ok then
		ngx.say("failed to set keepalive memcache: ", err)
		return
	end
end
