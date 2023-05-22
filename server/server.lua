local QBCore = exports['qbx-core']:GetCoreObject()

local isChiped = {}
local removeItem = function(PlayerPed, item, amount)
    return PlayerPed.Functions.RemoveItem(item, amount)
end


Citizen.CreateThread(function()
    Citizen.Wait(1000)
    MySQL.query('SELECT plate FROM player_vehicles WHERE drifttuner = ?', {'1'}, function(result)
            if #result > 0 then
            for i=1, #result do
                isChiped[result[i].plate] = true
            end
        end
    end)
end)

lib.callback.register('dds-drifttuner:isChiped', function(source, plate)
    chiped = isChiped[plate]
    return chiped
end)


RegisterNetEvent('dds-drifttuner:chipAdd', function(plate)
    local src = source
    local PlayerPed = QBCore.Functions.GetPlayer(src)
    if PlayerPed then
        removeItem(PlayerPed, config.chipItem, 1)
        isChiped[plate] = true
        MySQL.update('UPDATE player_vehicles SET drifttuner = 1 WHERE plate = @plate',{
            ['@plate'] = plate
        })
    end
end)

RegisterNetEvent('dds-drifttuner:chipRemove', function(plate)
    isChiped[plate] = nil
    MySQL.update("UPDATE player_vehicles SET drifttuner = 0 WHERE plate = @plate", {
        ['@plate'] = plate,
    })
end)

lib.addCommand('testdrift', {
    help = 'Test Drift Tune (admin)',
    restricted = "qbox.admin",
}, function(source)
    TriggerClientEvent('dds-drifttuner:testdrift', source)
end)