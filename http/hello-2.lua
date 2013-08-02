-- print(arg[0])
print(arg[1])
-- print(arg[2])
function datetime (t)
	return os.date("%Y%m%d", os.time() + 24 * 60 * 60 * t)
end


-- Get the mission.(org/dst/t)
local org = string.sub(arg[1], 1, 3);
local dst = string.sub(arg[1], 5, 7);
local t = string.sub(arg[1], 9, -2);
print(org)
print(dst)
print(t)