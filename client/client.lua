local objects = {}

local run = false
local function StartRay(obj)
	local heading = 180.0
	local created = false
	local coord = GetEntityCoords(PlayerPedId())
	lib.requestModel(obj, 30000)
    local entity = CreateObject(obj, coord.x, coord.y, coord.z, false, false)
    local z = math.floor(coord.z * 100) / 100
    run = true
    repeat

        local hit, entityHit, endCoords, surfaceNormal, matHash = lib.raycast.cam(511, 4, 30)
        if not created then 
            created = true
            lib.showTextUI('[E] To Place  \n  [DEL] To Cancel  \n  [<-] To Move Left  \n  [->] To Move Right')
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
            lib.hideTextUI()
            run = false
            DeleteEntity(entity)
            local loc ={x = math.floor(endCoords.x * 100) / 100, y = math.floor(endCoords.y * 100) / 100, z = math.floor(endCoords.z * 100) / 100}
            return loc, heading, obj
        end

        if IsControlPressed(0, 178) then
            lib.hideTextUI()
            run = false
            DeleteEntity(entity)
            return nil
        end
    until run == false
end

local function spawn()
    for k, v in pairs (objects) do
        DeleteEntity(v.object)
        table.remove(objects, k)
    end
    local list = lib.callback.await('md-props:getObjects', false)
    if list == 'No Objects' then print('No Objects: Add Some Nerd') return end
    for k, v in pairs (list) do
        local coords = json.decode(v.loc)
        lib.requestModel(v.model, 30000)
        local obj = CreateObject(v.model, coords.x, coords.y, coords.z, false, true, true)
        SetEntityHeading(obj, coords.w)
        FreezeEntityPosition(obj, true)
        table.insert(objects, {object = obj, coords = coords, model = v.model, id = v.id})
    end
end

RegisterNetEvent('md-props:addObject', function()
local can = lib.callback.await('md-props:check', false)
if not can then return end
local model = lib.inputDialog('Enter Model Name', {
    {description = 'Type The Model You Want',  type = 'input'}
})
if not model then return end
local hash = GetHashKey(model[1])
if IsModelValid(hash) then 
    local coord, head = StartRay(model[1])
    if coord then
        TriggerServerEvent('md-props:placeObject', coord, head, model[1])
    end
end
end)

CreateThread(function()
    spawn()
end)

RegisterNetEvent('md-props:updateObjects', function()
    spawn()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i = 1, #objects do
            DeleteEntity(objects[i].object)
        end
        objects = {}
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
                lib.registerContext({
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
                                local model = lib.inputDialog('Enter Model Name', {
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
                                SetEntityCoords(PlayerPedId(), coord.x, coord.y, coord.z)
                            end
                        }
                    }
                })
                lib.showContext('edit_Objects')
            end
        }
    end
    lib.registerContext({    id = 'edit_ObjectsMenu',    title = 'Edit Object',    options = options})
    lib.showContext('edit_ObjectsMenu')
end)
