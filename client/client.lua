local objects = {}

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, hit, endCoords, surfaceNormal, entityHit  = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return _, hit, endCoords, surfaceNormal, entityHit
end

local function ray()
   local _, hit, endCoords, surfaceNormal, entityHit  = RayCastGamePlayCamera(1000.0)
    return hit, endCoords, surfaceNormal, entityHit
end

local function requestModel(modelHash, timeout)
    local model = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))
    local start = GetGameTimer()
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
            if timeout and GetGameTimer() - start >= timeout then
                return false
            end
        end
    end
    return true
end

local run = false
local function StartRay(obj)
	local heading = 180.0
	local created = false
	local coord = GetEntityCoords(PlayerPedId())
	requestModel(obj, 30000)
    local entity = CreateObject(obj, coord.x, coord.y, coord.z, false, false)
    local z = math.floor(coord.z * 100) / 100
    run = true
    repeat
        Wait(0)
        local hit, endCoords, surfaceNormal, entityHit = ray()
        if not created then 
            created = true
            Bridge.HelpText.ShowHelpText('[E] To Place  \n  [DEL] To Cancel  \n  [<-] To Move Left  \n  [->] To Move Right')
        else
            SetEntityCoords(entity, endCoords.x, endCoords.y, z)
            SetEntityHeading(entity, heading)
            SetEntityCollision(entity, false, false)
        end
        if IsControlPressed(0, 174) then heading = heading - 1 end
        if IsControlPressed(0, 175) then heading = heading + 1 end
        if IsControlPressed(0, 172) then z = z + 0.1 end 
        if IsControlPressed(0, 173) then z = z - 0.1 end
        if IsControlPressed(0, 38) then
            Bridge.HelpText.HideHelpText()
            run = false
            DeleteEntity(entity)
            local loc ={x = math.floor(endCoords.x * 100) / 100, y = math.floor(endCoords.y * 100) / 100, z = math.floor(endCoords.z * 100) / 100}
            return loc, heading, obj
        end

        if IsControlPressed(0, 178) then
            Bridge.HelpText.HideHelpText()
            run = false
            DeleteEntity(entity)
            return nil
        end
    until run == false
end

local function spawn()
    local list = Bridge.Callback.Trigger('md-props:getObjects', false)
    if list == 'No Objects' then print('No Objects: Add Some Nerd') return end
    for k, v in pairs (list) do
        local coords = v.loc
        requestModel(v.model, 30000)
        local obj = CreateObject(v.model, coords.x, coords.y, coords.z, false, true, true)
        SetEntityHeading(obj, coords.w)
        FreezeEntityPosition(obj, true)
        objects[k] = {object = obj, coords = coords, model = v.model, id = v.id}
    end
end

local function newSpawn(data)
    for k, v in pairs (objects) do
        DeleteEntity(v.object)
        objects[k] = nil
    end
    for k, v in pairs (data) do
        local coords = v.loc
        requestModel(v.model, 30000)
        local obj = CreateObject(v.model, coords.x, coords.y, coords.z, false, true, true)
        SetEntityHeading(obj, coords.w)
        FreezeEntityPosition(obj, true)
        objects[k] = {object = obj, coords = coords, model = v.model, id = v.id}
    end
end

RegisterNetEvent('md-props:addObject', function(model)
    local can = Bridge.Callback.Trigger('md-props:check', false)
    if not can then return end
    local coord, head = StartRay(model)
    if coord then
        TriggerServerEvent('md-props:placeObject', coord, head, model)
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function() spawn() end)
AddEventHandler('esx:playerLoaded', function(playerData)  spawn()end)
RegisterNetEvent('md-props:updateObjects', function(data) newSpawn(data) end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(objects) do
            DeleteEntity(v.object)
        end
        objects = {}
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        spawn()
    end
end)
RegisterNetEvent('md-props:editObject', function()
    local options = {}
    for k, v in pairs(objects) do
        local coord = v.coords
        options[#options + 1] = {
            title = 'Model: ' .. v.model,
            description = string.format('vector4(%s, %s, %s, %s)', coord.x, coord.y, coord.z, coord.w),
            onSelect = function()
                Bridge.Menu.Open({
                    id = 'edit_Objects',
                    title = 'Edit Object',
                    options = {
                        {
                            title = 'Delete Object',
                            onSelect = function()
                                TriggerServerEvent('md-props:placeObject', coord, coord.w, v.model, 'delete', v.id)
                            end
                        },
                        {
                            title = 'Edit Coords',
                            onSelect = function()
                                local coords, head = StartRay(v.model)
                                if coords then
                                    TriggerServerEvent('md-props:placeObject', coords, head, v.model, 'editcoord', v.id)
                                end
                            end
                        },
                        {
                            title = 'Edit Model',
                            onSelect = function()
                                local model = Bridge.Input.Open('Enter Model Name', {
                                    {description = 'Type The Model You Want', type = 'input'}
                                })
                                if not model or not model[1] then return end
                                local hash = GetHashKey(model[1])
                                if IsModelValid(hash) then
                                    TriggerServerEvent('md-props:placeObject', coord, coord.w, model[1], 'editObject', v.id)
                                end
                            end
                        },
                        {
                            title = 'Teleport To Object',
                            onSelect = function()
                                TriggerServerEvent('md-props:goto', v.id)
                            end
                        }
                    }
                })
            end
        }
    end
    Bridge.Menu.Open({    id = 'edit_ObjectsMenu',    title = 'Edit Object',    options = options})
end)
