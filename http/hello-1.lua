local function _formencodepart(s)
	if type(s) == number then
		return s
	else
		return s and (s:gsub("%W", function (c)
	 		if c ~= " " then
	 			return string.format("%%%02x", c:byte());
	 		else
	 			return "+";
	 		end
	 	end));
	end
end

local bakdate = os.date("%Y/%m/%d %X", os.time());
print(bakdate);
print(os.date(os.time()))

local tmp = "CZ|0|340|2013/8/1 17:00:00|CAN|False|False|false"

for a, b, c, x, y, z in string.gmatch(tmp, "(%a+)|(%d+)|(%d+)|(.*)|(%a+)|(%a+)|(%a+)|(.*)") do
	print(_formencodepart(x))
end




