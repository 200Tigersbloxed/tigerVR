local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')
local Players = game:GetService('Players')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')

local module = {}

module.baseurl = "https://tigervr.fortnite.lol/"

module.gettrackersendpoint = "api/v1/getUserTrackersInfo"

module.maxrequests = 400

module.refreshtime = 0.15

local rpm = 0

local function addandcheck()
	if rpm >= module.maxrequests then 
		warn('Ran out of allocated requests!')
		return false 
	end
	rpm = rpm + 1
	return true
end

local function handleresponse(player, response)
	tigerVR.Remotes.OnExtendedData:FireClient(player, response)
end

function module:ApplyUserTrackingInfo(players)
	if #players <= 0 then return end
	local parsedData
	if #players == 1 then
		pcall(function()
			local p = Players:WaitForChild(players[1])
			if p then
				if addandcheck() then
					local res = HttpService:GetAsync(module.baseurl..module.gettrackersendpoint..'?username='..p.Name)
					parsedData = HttpService:JSONDecode(res)
					if parsedData['result'] == 'Success' then
						--tigerVR.Remotes.ExtendedTrackingData:FireClient(p, true, parsedData['response'])
						handleresponse(p, parsedData['response'])
					end
				end
			end
		end)
	end
	if #players > 1 then
		pcall(function()
			local playe = ""
			for _, p in players do
				playe = playe..","..p
			end
			playe = playe:sub(2)
			if addandcheck() then
				local res = HttpService:GetAsync(module.baseurl..module.gettrackersendpoint..'?username='..playe)
				parsedData = HttpService:JSONDecode(res)
				if parsedData['result'] == 'Success' then
					for _, i in parsedData do
						local pr = Players:FindFirstChild(i)
						if pr then
							--tigerVR.Remotes.ExtendedTrackingData:FireClient(pr, true, parsedData[i]['response'])
							handleresponse(pr, parsedData[i]['response'])
						end
					end
				end
			end
		end)
	end
	return parsedData
end

local lastRpm = 0

function module:init()
	coroutine.wrap(function()
		while wait(60) do
			if rpm ~= lastRpm then 
				lastRpm = rpm
				if rpm ~= 0 then
					print('RPM changed! Previous: '..tostring(lastRpm)..' now: '..tostring(rpm))
				end
			end
			print("rpm 0")
			rpm = 0
		end
	end)()
end

return module
