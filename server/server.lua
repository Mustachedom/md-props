local props = MySQL.query.await('SELECT * FROM mdprops', {})
local cacheProps = {}

local function loadProps()
    for i = 1, #props do
        cacheProps[i] = {
            id = props[i].id,
            model = props[i].model,
            loc = json.decode(props[i].loc)
        }
    end
    return cacheProps
end
loadProps()

local function command(name, func, chat)
    RegisterCommand(name, function(source, args, raw)
        if not IsPlayerAceAllowed(source, 'command') then return  end
        func(source, args, raw)
    end, true)
    TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, chat.description or '', chat.arguments or {})
end

command('addObject', function(source, args, raw)
    if not IsPlayerAceAllowed(source, 'command') then return  end
    local model = args[1]
    if not model then return end
    TriggerClientEvent('md-props:addObject', source, model)
end, {
    description = 'Spawn a prop to place it',
    arguments = {
        { name = 'model', help = 'The model of the prop you want to spawn' },
    }
})

command('editObject', function(source, args, raw)
    if not IsPlayerAceAllowed(source, 'command') then return  end
    TriggerClientEvent('md-props:editObject', source)
end, {
    description = 'Edit a placed prop',
})

Bridge.Callback.Register('md-props:check', function(source)
    return IsPlayerAceAllowed(source, 'command')
end)

RegisterServerEvent('md-props:placeObject', function(coord, head, model, type, id)
    local src = source
    if not IsPlayerAceAllowed(src, 'command') then return false end
    if type == 'delete' then 
        MySQL.query.await('DELETE FROM mdprops WHERE id = ?', {id})
        cacheProps[id] = nil
        TriggerClientEvent('md-props:updateObjects', -1, cacheProps)
        return
    end
    if type == 'editcoord' then 
        local loc = {x = coord.x, y = coord.y, z = coord.z, w = head}
        MySQL.query.await('UPDATE mdprops SET loc = ? WHERE id = ?', {json.encode(loc), id})
        cacheProps[id].loc = vector4(coord.x, coord.y, coord.z, head)
        TriggerClientEvent('md-props:updateObjects', -1, cacheProps)
        return
    end
    if type == 'editObject' then
        MySQL.query.await('UPDATE mdprops SET model = ? WHERE id = ?', {model, id})
        cacheProps[id].model = model
        TriggerClientEvent('md-props:updateObjects', -1, cacheProps)
        return
    end
    local coords = {x = coord.x, y = coord.y, z = coord.z, w = head}
    MySQL.query.await('INSERT INTO mdprops SET model = ?, loc = ?', { model, json.encode(coords)})
    Wait(300)
    cacheProps[#cacheProps + 1] = {
        id = #cacheProps + 1,
        model = model,
        loc = vector4(coord.x, coord.y, coord.z, head)
    }
    TriggerClientEvent('md-props:updateObjects', -1,cacheProps)
end)

RegisterNetEvent('md-props:goto', function(id)
    local src = source
    if not IsPlayerAceAllowed(source, 'command') then return false end
    local prop = nil
    for i = 1, #cacheProps do
        if cacheProps[i].id == id then
            prop = cacheProps[i]
            break
        end
    end
    SetEntityCoords(GetPlayerPed(src), prop.loc.x, prop.loc.y, prop.loc.z)
end)

Bridge.Callback.Register('md-props:getObjects', function(source)
    return cacheProps
end)
