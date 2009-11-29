-- Bat functions for thinkpads
--
-- Todo:
-- remove hardcoded batterycount
--
-- Sven M.


local function read_battery(number)
	local battable = {}
	local fileh

	for i, file in ipairs({ "remaining_capacity"; "last_full_capacity"; "state" }) do
		fileh = io.open("/sys/devices/platform/smapi/BAT" .. number .. "/" .. file, "r")
		if fileh then
			if file ~= "state" then
				battable[file] = fileh:read("*n")
			else
				battable[file] = fileh:read()
			end
			fileh:close()
			if battable[file] == nil then
				return nil
			end
		else
			return nil
		end
	end
	return battable
end

local function read_batteries(min, max)
	local batteries = {}
	for i = min, max do
		local temp = read_battery(i)
		table.insert(batteries, temp)
	end
	return batteries;
end

local function batsum(min, max)
	local batteries = read_batteries(min,max)
	local remsum = 0
	local fullsum = 0

	for i, battable in ipairs(batteries) do
		remsum = remsum + battable["remaining_capacity"]
		fullsum = fullsum + battable["last_full_capacity"]
	end
	batteries["remsum"] = remsum
	batteries["fullsum"] = fullsum
	if fullsum > 0 then
		batteries["percent"] = math.floor(100 * batteries["remsum"] / batteries["fullsum"])
	else
		batteries["percent"] = 0
	end
	return batteries
end

local function batcolor(percent, colorfull, colordead)
	local color = {}
	for i = 1, 3 do
		color[i] = colordead[i] + (colorfull[i] - colordead[i]) * percent / 100
	end
	return color
end

local function batpadd(string, minlen)
	if string:len() < minlen then
		return string.rep('0', minlen - string:len()) .. string
	end
	return string
end

function batcolorhex(percent, colorfull, colordead)
	local color = batcolor(percent, colorfull, colordead)

	return batpadd(string.format("%x", color[1]), 2) .. batpadd(string.format("%x", color[2]), 2) .. batpadd(string.format("%x", color[3]), 2)
end

n_batstatwindow = nil
function batstatwindow(action)
	if action == "create" then
		local batteries = read_batteries(0, 1)
		local text = ""
		for i, battable in ipairs(batteries) do
			local percent = math.floor(100 * battable["remaining_capacity"] / battable["last_full_capacity"])
			text = text .. 'Battery <span color="white">' .. i .. '</span> has <span color="#' .. batcolorhex(percent, {0; 255; 0}, {255; 0; 0}) .. '">' .. percent .. '</span> percent and is <span color="white">' .. battable["state"] .. '</span>\n'
		end
		n_batstatwindow= naughty.notify({text = text, timeout = 0, hover_timeout = 0.5, width = 265})
	elseif action == "destroy" and n_batstatwindow ~= nil then
		naughty.destroy(n_batstatwindow)
		n_batstatwindow = nil
	end
end

function batstatpoll()
	local batteries = batsum(0, 1)
	if batteries[1] ~= nil then
		return {batteries["percent"]}
	end
	return {'0'}
end
