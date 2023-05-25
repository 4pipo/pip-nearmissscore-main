-- cache --
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local GetVehiclePedIsIn = GetVehiclePedIsIn
local IsEntityAVehicle = IsEntityAVehicle
local GetEntitySpeed = GetEntitySpeed

local cacheVehicle = nil

RegisterNetEvent('pip-nearmissscore:client:setPlayerVehicle')
AddEventHandler('pip-nearmissscore:client:setPlayerVehicle', function()
    cacheVehicle = GetVehiclePedIsIn(PlayerPedId()) and not 0 or nil
end)

--- func desc
---@param distance number
---@return number multiplier
local function getMultiplierValue(distance)
    if distance >= 5 and distance < 6 then
        return 1.0
    elseif distance >= 2 then
        return 1.0 + (5.0 - 1.0) * (5 - distance) / 4
    else
        return 5.0
    end
end

---@param coords vector3 The coords to check from.
---@param maxDistance number The max distance to check.
---@param includePlayerVehicle boolean Whether or not to include the player's current vehicle.
---@return number? vehicle
---@return vector3? vehicleCoords
local function getClosestVehicle(coords, maxDistance, includePlayerVehicle)
	local vehicles = GetGamePool('CVehicle')
	local closestVehicle, closestCoords
	maxDistance = maxDistance or 2.0

	for i = 1, #vehicles do
		local vehicle = vehicles[i]

		if not cacheVehicle or vehicle ~= cacheVehicle or includePlayerVehicle then
			local vehicleCoords = GetEntityCoords(vehicle)
			local distance = #(coords - vehicleCoords)

			if distance < maxDistance then
				maxDistance = distance
				closestVehicle = vehicle
				closestCoords = vehicleCoords
			end
		end
	end

	return closestVehicle, closestCoords
end

local lastVehiclePassed = nil
local totalMultiplier = 1.0
local totalScore = 0.0

CreateThread(function()
    while not cacheVehicle do
        Wait(1000)
    end
    while true do
        local playerPedVehicleCoords = GetEntityCoords(GetVehiclePedIsIn(PlayerPedId(), false))
        local closestVehicle, closestVehicleCoords = getClosestVehicle(playerPedVehicleCoords, 5, false)
        local currentSpeed = GetEntitySpeed(cacheVehicle) * 3.6
        if not lastVehiclePassed and closestVehicle or closestVehicle and lastVehiclePassed ~= closestVehicle then
            if currentSpeed >= 50.0 then
                local distance = #(playerPedVehicleCoords - closestVehicleCoords)
                local multiplier = getMultiplierValue(distance)
                totalMultiplier = totalMultiplier + (multiplier - 1.0)
                totalScore = totalScore + currentSpeed / 10 * totalMultiplier
                print("Iter Point: "..currentSpeed / 10 * totalMultiplier, "Total Point: "..totalScore, "multiplier: "..multiplier, "totalMultiplier: "..totalMultiplier)
                lastVehiclePassed = closestVehicle
            end
        end
        Wait(100)
    end
end)

RegisterCommand('cachevehicle', function()
    cacheVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
end)

AddEventHandler('entityDamaged', function (victim, culprit, weapon, baseDamage)
    if IsEntityAVehicle(victim) and IsEntityAVehicle(culprit) then --both victim and killer are peds.
        if victim == cacheVehicle or culprit == cacheVehicle then
            print(victim, culprit, weapon, baseDamage)
            totalMultiplier = 1.0
            totalScore = 0.0
        end
    end
end)