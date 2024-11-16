

lib.addCommand('addObject', {
    help = 'Add An Object To Your Server',
    restricted = 'group.admin'
}, function(source, args, raw)
    if not IsPlayerAceAllowed(source, 'command') then return  end
    TriggerClientEvent('md-props:addObject', source)
end)

lib.addCommand('editObject', {
    help = 'edit Objects',
    restricted = 'group.admin'
}, function(source, args, raw)
    if not IsPlayerAceAllowed(source, 'command') then return  end
    TriggerClientEvent('md-props:editObject', source)
end)

lib.callback.register('md-props:check', function(source)
    if not IsPlayerAceAllowed(source, 'command') then return false end
    return true
end)

RegisterServerEvent('md-props:placeObject', function(coord, head, model, type, id)
    local src = source
    if not IsPlayerAceAllowed(source, 'command') then return false end
    if type == 'delete' then 
        MySQL.query.await('DELETE FROM mdprops WHERE id = ?', {id})
        TriggerClientEvent('md-props:updateObjects', -1)
        return
    end
    if type == 'editcoord' then 
        local loc = {x = coord.x, y = coord.y, z = coord.z, w = head}
        MySQL.query.await('UPDATE mdprops SET loc = ? WHERE id = ?', {json.encode(loc), id})
        TriggerClientEvent('md-props:updateObjects', -1)
        return
    end
    if type == 'editObject' then
        MySQL.query.await('UPDATE mdprops SET model = ? WHERE id = ?', {model, id})
        TriggerClientEvent('md-props:updateObjects', -1)
        return
    end
    local coords = {x = coord.x, y = coord.y, z = coord.z, w = head}
    MySQL.query.await('INSERT INTO mdprops SET model = ?, loc = ?', { model, json.encode(coords)})
    TriggerClientEvent('md-props:updateObjects', -1)
end)


lib.callback.register('md-props:getObjects', function(source)
    local data = MySQL.query.await('SELECT * FROM mdprops', {})
    if data[1] == nil then return 'No Objects' end
    return data
end)