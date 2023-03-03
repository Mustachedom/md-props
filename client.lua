CreateThread(function()
    for i = 1, #Config.Props do
        if Config.Props[i].propcoords ~= nil then
            local heading = Config.Props[i].propcoords[4]-180
            RequestModel(Config.Props[i].prop)
            while not HasModelLoaded(Config.Props[i].prop) do
                Wait(1) 
            end
            Config.Props[i].prop = CreateObject(Config.Props[i].prop, Config.Props[i].propcoords.x, Config.Props[i].propcoords.y, Config.Props[i].propcoords.z-1, false, true, true)
            SetEntityHeading(Config.Props[i].prop, heading)
            FreezeEntityPosition(Config.Props[i].prop, 1)
        end	
    end
end)

 AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i = 1, #Config.Props do
            if Config.Props[i].propcoords ~= nil then
                 DeleteEntity(Config.Props[i].prop)
            end	
        end
    end
end)
	
