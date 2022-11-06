local VRService = game:GetService('VRService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')

local module = {}

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')

module.InputDevices = {
	["Oculus"] = 0,
	["Index"] = 0,
	["ViveWand"]= 1
}

module.UserInputService = UserInputService

local InputBindings = {
	["KeyCode"] = {},
	["UserInputType"] = {}
}

function module:AddKeyCode(keycode, id, callback)
	if RunService:IsServer() then
		warn("Cannot use Bindings on the Server!")
		return
	end
	--[[
		Adds a binding with a callback
		User-Friendly! Feel free to make your own bindings :3
		
		A Proper Object looks like this
		InputBindings = {
			["KeyCode"] = {
				[Enum.KeyCode.A] = {
					["someid"] = function(inputObject)
									 print("Position is "..inputObject.Position)
								 end
				}
			},
			["UserInputType"] = {
				[Enum.UserInputType.MouseMovement] = {
					["someid"] = function(inputObject)
							    	 print("Delta is "..tostring(inputObject.Delta))
								 end
				}
			}
		}
	]]
	if not InputBindings["KeyCode"][keycode] then InputBindings["KeyCode"][keycode] = {} end
	InputBindings["KeyCode"][keycode][id] = callback
end

function module:AddUserInputType(userinputtype, id, callback)
	if not InputBindings["UserInputType"][userinputtype] then InputBindings["UserInputType"][userinputtype] = {} end
	InputBindings["UserInputType"][userinputtype][id] = callback
end

local function invokebindings_kc(input)
	if InputBindings["KeyCode"][input.KeyCode] then
		for id, bindingCallback in pairs(InputBindings["KeyCode"][input.KeyCode]) do
			bindingCallback(input)
		end
	end
end

local function invokebindings_uit(input)
	if InputBindings["UserInputType"][input.UserInputType] then
		for id, bindingCallback in InputBindings["UserInputType"][input.UserInputType] do
			bindingCallback(input)
		end
	end
end

function module:unbind(id)
	if RunService:IsServer() then
		warn("Cannot use Bindings on the Server!")
		return
	end
	-- Removes all callbacks for a keycode and id
	for keycode, lid in pairs(InputBindings["KeyCode"]) do
		if lid == id then
			lid = nil
		end
	end
	for userinputtype, lid in pairs(InputBindings["UserInputType"]) do
		if lid == id then
			lid = nil
		end
	end
end

function module:unbindall()
	if RunService:IsServer() then
		warn("Cannot use Bindings on the Server!")
		return
	end
	-- Removes all bindings
	InputBindings = {
		["KeyCode"] = {},
		["UserInputType"] = {}
	}
end

local function inputdevicetotouchpadmode(id)
	if id == module.InputDevices.Oculus then return Enum.VRTouchpadMode.Touch end
	if id == module.InputDevices.ViveWand then return Enum.VRTouchpadMode.ABXY end
	return Enum.VRTouchpadMode.VirtualThumbstick
end

function module:SetTouchpadMode(inputDevice)
	if RunService:IsServer() then
		warn("Cannot use Bindings on the Server!")
		return
	end
	VRService:SetTouchpadMode(Enum.VRTouchpad.Left, inputdevicetotouchpadmode(inputDevice))
	VRService:SetTouchpadMode(Enum.VRTouchpad.Right, inputdevicetotouchpadmode(inputDevice))
end

function module.Setup()
	if RunService:IsServer() then
		warn("Cannot use Bindings on the Server!")
		return
	end
	UserInputService.InputBegan:Connect(function(Input)
		pcall(function()
			invokebindings_kc(Input)
		end)
	end)
	
	UserInputService.InputChanged:Connect(function(Input)
		pcall(function()
			invokebindings_uit(Input)
		end)
	end)
end

return module
