config = {}

config.chipInstallTime = 5000
config.alerttype = 'ox' --'ox', 'custom' //Insert 'ox' to use ox_lib notifications.  For all others enter anything else and modify the function below to suit your need.

config.vehicleModelWhitelist = {
    'sultanrs',
    'yosemite2',
    'slamvan3',
    'specter2'
}

function driftalerts(text, type)
    if config.alerttype == 'ox' then
        lib.notify({title = text, type = type}) 
    else
        --Insert Custom Notification String
        exports['okokNotify']:Alert("Vehicle Tuner", text, 5000, type)
        --Insert Custom Notification String
    end
end