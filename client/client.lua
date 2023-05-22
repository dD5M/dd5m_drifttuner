local driftMode = false
local InProgress = false
local playerPed, playerCoords, inVehicle, playerVehicle, vehicleClass, driverSeat
local engines = {"engine", "engine_a", "bumper_f"}
local isChipped = false
local handleMods = {
	{"fInitialDragCoeff", 90.22},
	{"fDriveInertia", .31},
	{"fSteeringLock", 22},
	{"fTractionCurveMax", -1.1},
	{"fTractionCurveMin", -.4},
	{"fTractionCurveLateral", 2.5},
	{"fLowSpeedTractionLossMult", -.57}
}
local radialupdated = false

exports('drifttuner', function(data, slot)
    chipAddClient()
end)

Citizen.CreateThread( function()
	while true do
        Citizen.Wait(500)
        playerPed = PlayerPedId()
        inVehicle = IsPedInAnyVehicle(playerPed)
        if inVehicle then
            playerVehicle = GetVehiclePedIsIn(playerPed, false)
            vehiclePlate = GetVehicleNumberPlateText(playerVehicle)
            vehicleClass = GetVehicleClass(playerVehicle)
            driverSeat = GetPedInVehicleSeat(playerVehicle, -1) == playerPed
            isChipped = lib.callback.await('dds-drifttuner:isChiped', 500, vehiclePlate)
        else
            playerVehicle, vehicleClass, driverSeat = 0, 0, 0
        end
        if inVehicle and isChipped then
            if not radialupdated then
                lib.addRadialItem({
                    id = 'driftmode',
                    label = 'Toggle Drift',
                    icon = {'fas', 'steering-wheel'},
                    onSelect = function()
                        ExecuteCommand("toggledrift")
                    end,
                    keepOpen = false
                })
                radialupdated = true
            end
        else
            if radialupdated == true then
                lib.removeRadialItem('driftmode')
                radialupdated = false
            end
        end
    end
end)

RegisterCommand('toggledrift', function()
	playerPed = GetPlayerPed(-1)
	if inVehicle then
		if driverSeat then
			if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fDriveBiasFront") ~= 1 and IsVehicleOnAllWheels(playerVehicle) then
                if isChipped then
                    if InProgress == false then
                        InProgress = true
                        ToggleDrift(playerVehicle, false)
                    else
                        driftalerts("Safety features already disabling!", 'error')
                    end
                else
                    driftalerts("No drift chip present.", 'error')
                end
            end
			if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
				SetVehicleEnginePowerMultiplier(playerVehicle, 0.0)
			else
				if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fDriveBiasFront") == 0.0 then
					SetVehicleEnginePowerMultiplier(playerVehicle, 190.0)
				else
					SetVehicleEnginePowerMultiplier(playerVehicle, 100.0)
				end
            end
		end
	end
end)


-- Add tuner chip
function chipAddClient()
    playerPed = PlayerPedId()
    playerCoords = GetEntityCoords(playerPed)
	if inVehicle then
        driftalerts("You cannot do this in the vehicle!", 'error')
		return
    end

    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
    if IsVehicleModelWhitelisted(GetEntityModel(vehicle)) then
        local engine = nil
        for i=1, #engines do
            local getEngineIndex = GetEntityBoneIndexByName(vehicle, engines[i])
            if getEngineIndex ~= -1 then
                engine = getEngineIndex
                break
            end
        end
        if #(playerCoords - GetWorldPositionOfEntityBone(vehicle, engine)) <= 2.3 then
            if DoesEntityExist(vehicle) then
                SetVehicleDoorOpen(vehicle, 4, 0, 0)
                TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
                if lib.progressBar({
                    duration = config.chipInstallTime,
                    label = 'Installing Drift Tuning Chip',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                    },
                }) then 
                    Wait(2000)
                    TriggerServerEvent("dds-drifttuner:chipAdd", GetVehicleNumberPlateText(vehicle))
                    driftalerts("Drift Tuning Chip Installed", 'success')
                    ClearPedTasksImmediately(playerPed)
                    SetVehicleDoorShut(vehicle, 4, 0)
                else
                    exports.emotemenu:CancelAnimation()
                end
            end
        else
            driftalerts("You are too far from engine!", 'error')
        end
    else
        driftalerts("You cannot drift this vehicle!", 'error')
    end
end

function ToggleDrift(vehicle, isAdmin)
    local modifier = 1
    if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90 then
        driftMode = true
        dtoggle = 'Disabling'
        modifier = -1
    else
        driftMode = false
        dtoggle = 'Enabling'
    end

    if isAdmin then progTimer = 2000 else progTimer = 30000 end
    if lib.progressBar({
        duration = progTimer,
        label = dtoggle.." Drift Mode ..",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
    }) then 
        for index, value in ipairs(handleMods) do
            SetVehicleHandlingFloat(vehicle, "CHandlingData", value[1], GetVehicleHandlingFloat(vehicle, "CHandlingData", value[1]) + value[2] * modifier)
            InProgress = false
        end
        if driftMode then
            -- PrintDebugInfo("stock")
            driftalerts("TCS, ABS, ESP is on!  Drift Mode DISABLED", 'success')
        else
            -- PrintDebugInfo("drift")
            driftalerts("TCS, ABS, ESP is OFF! Drift Mode ENABLED", 'success')
        end
    else
        InProgress = false
        driftalerts("Cancelled drift mode change.", 'error')
    end
end

function PrintDebugInfo(mode)
	playerPed = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(playerPed, false)
	print(mode)
	for index, value in ipairs(handleMods) do
		print(GetVehicleHandlingFloat(vehicle, "CHandlingData", value[1]))
	end
end

function IsVehicleModelWhitelisted(vehicleModel)
	for index, value in ipairs(config.vehicleModelWhitelist) do
		if GetHashKey(value) == vehicleModel then
			return true
		end
	end
	return false
end

--Drift/Performance Mod vehicle check
RegisterNetEvent('dds-drifttuner:TuneStatus', function()
    local ped = PlayerPedId()
    local closestVehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
    local plate = GetVehicleNumberPlateText(closestVehicle)
    local vehModel = GetEntityModel(closestVehicle)
    turbo = IsToggleModOn(closestVehicle, 18)
    if vehModel ~= 0 then
        if turbo == 1 then
            driftalerts("Performance Tune present.", 'success')
        else
            driftalerts("No performance mods present.", 'error')
        end
        chiped = lib.callback.await('dds-drifttuner:isChiped', plate)
        if chiped then
            driftalerts("Drift Tune present.", 'success')
        else
            driftalerts("No drift mods present.", 'error')
        end
    else
        driftalerts("No Vehicle Nearby", 'error')
    end
end)

RegisterNetEvent("dds-drifttuner:testdrift", function()
	playerPed = GetPlayerPed(-1)
	if inVehicle then
		if driverSeat then
			if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fDriveBiasFront") ~= 1 and IsVehicleOnAllWheels(playerVehicle) then
                if InProgress == false then
                    InProgress = true
                    ToggleDrift(playerVehicle, true)
                else
                    driftalerts("Safety features already disabling!", 'error')
                end
            end
			if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
				SetVehicleEnginePowerMultiplier(playerVehicle, 0.0)
			else
				if GetVehicleHandlingFloat(playerVehicle, "CHandlingData", "fDriveBiasFront") == 0.0 then
					SetVehicleEnginePowerMultiplier(playerVehicle, 190.0)
				else
					SetVehicleEnginePowerMultiplier(playerVehicle, 100.0)
				end
            end
		end
	end
end)