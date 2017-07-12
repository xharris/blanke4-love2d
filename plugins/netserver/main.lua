require 'class'
require 'lube'
require 'Util'
require 'json'
local uuid = require 'uuid'
local Debug = require 'Debug'

Debug.setFontSize(10)
Debug.setMargin(5)

-- BlankE Net server
Net = {
    entity_update_rate = 0, -- m/s
    
    is_init = false,
    client = nil,
    server = nil,
    
    onReceive = nil,    
    onConnect = nil,    
    onDisconnect = nil, 
    
    address = "localhost",
    port = 12345,

    _client_entities = {},      -- entities added by this client
    _server_entities = {},      -- entities added by other clients

    _entity_property_excludes = {'^_images$','^_sprites$','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$','^is_net_entity$'},
    
    _timer = 0,
    uuid = nil,

    init = function(address, port)
        Net.address = ifndef(address, "localhost") 
        Net.port = ifndef(port, Net.port) 
        Net.uuid = uuid()      
        Net.is_init = true

        Debug.log("networking initialized")
    end,
    
    update = function(dt,override)
        override = ifndef(override, true)

        if Net.is_init then
            if Net.server then Net.server:update(dt) end
            if Net.client then Net.client:update(dt) end

            Net._timer = Net._timer + 1
            if override or Net._timer % Net.entity_update_rate == 0 then
                Net.updateEntities()
            end
        end
    end,

    -- returns "Server" object
    host = function()
        if not Net.is_init then
            Net.init(Net.address, Net.port)
        end      
        Net.server = lube.udpServer()

        Net.server.callbacks.connect = Net._onConnect
        Net.server.callbacks.disconnect = Net._onDisconnect
        Net.server.callbacks.recv = Net._onReceive

        Net.server.handshake = Net.uuid
        
        Net.server:listen(Net.port)

        Debug.log('hosting ' .. Net.address .. ':' .. Net.port)
        -- room_create() -- default room
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        if not Net.is_init then
            Net.init(address, port)
        end
        Net.client = lube.udpClient()
        Net.client:init()
        
        Net.client.callbacks.recv = Net._onReceive

        Net.client.handshake = Net.uuid
        
        Net.client:connect(Net.address, Net.port)
        Net.send({
            type='netevent',
            event='join',
            info={
                uuid=Net.uuid
            }
        })
    end,
    
    _onConnect = function(data) 
        Debug.log('+ ' .. data)
    end,
    
    _onDisconnect = function(data) 
        Debug.log('- ' .. data)

        if Net.onDisconnect then Net.onDisconnect(data) end
        for ent_class, entities in pairs(Net._server_entities) do
            for ent_uuid, entity in pairs(entities) do
                if entity._client_uuid == data then
                    Net._server_entities[ent_class][ent_uuid] = nil
                end
            end
        end
    end,
    
    _onReceive = function(data, id)
        Net.send(data)
        if data:starts('{') then
            data = json.decode(data)
        elseif data:starts('"') then
            data = data:sub(2,-2)
        end

        if type(data) == "string" and data:ends('\n') then
            data = data:gsub('\n','')
        end

        if type(data) == "string" and data:ends('-') then
            Net._onDisconnect(data:sub(1,-2))
            return
        end

        if type(data) == "string" and data:ends('+') then
            Net._onConnect(data:sub(1,-2))
            return
        end

        function addEntity(info)
            local classname = info.classname
            local new_entity = {}

            -- set properties
            for key, val in pairs(info) do
                new_entity[key] = val
            end
            new_entity._client_uuid = info._client_uuid
            new_entity.is_net_entity = true

            Net._server_entities[classname] = ifndef(Net._server_entities[classname], {})
            Net._server_entities[classname][info.net_uuid] = new_entity
    
            --table.insert(Net._server_entities[classname], new_entity)
        end

        if data.type and data.type == 'netevent' then
            -- new entity added
            if data.event == 'entity.add' then
                addEntity(data.info)

                Net.send(data)
            end

            -- update net entity
            if data.event == 'entity.update' then
                local info = data.info

                for net_uuid, entity in pairs(Net._server_entities[info.classname]) do
                    if entity.net_uuid == info.net_uuid then
                        for key, val in pairs(info) do
                            entity[key] = val
                        end
                    end
                end
            end

            -- entities to add on server join
            if data.event == 'entity.sync' and not data.info.exclude_uuid ~= Net.uuid then
                --for i, info in ipairs(data.info) do
                    --addEntity(info)
                --end
            end

            -- new person has joined network
            if data.event == 'join' then
                Net.send({
                    type="netevent",
                    event="entity.sync",
                    info={
                        exclude_uuid=data.info.uuid
                    }
                })
            end

            -- send to all clients
            if data.event == 'broadcast' then
                Net.send({
                    type='netevent',
                    event='broadcast',
                    info=data.info
                })
            end
        end

        if Net.onReceive then Net.onReceive(data) end
    end,

    send = function(data) 
        data = json.encode(data)
        Net.server:send(data)
    end,

    disconnect = function()
        if Net.client then Net.client:disconnect() end
    end,

    _getEntityInfo = function(entity) 
        local entity_info = {}

        -- get properties needed for syncing
        for property, value in pairs(entity) do
            add = true
            if type(value) == 'function' then add = false end
            for i_e, exclude in ipairs(Net._entity_property_excludes) do
                if string.match(property, exclude) then
                    add = false
                end
            end

            if add then
                entity_info[property] = value
            end
        end
        entity_info.classname = entity.classname
        entity_info.x = entity.x
        entity_info.y = entity.y
        entity_info._client_uuid = Net.uuid

        return entity_info
    end,

    addEntity = function(entity)
        Net._client_entities[entity.net_uuid] = entity

        --notify the other server clients
        Net.send({
            type='netevent',
            event='entity.add',
            info=Net._getEntityInfo(entity)
        })
    end,

    updateEntities = function()
        for net_uuid, entity in pairs(Net._client_entities) do
            Net.send({
                type='netevent',
                event='entity.update',
                info=Net._getEntityInfo(entity)
            })
        end
    end,
    
    --[[
    room_list = function() end,
    room_create
    room_join
    room_leave
    room_clients -- list clients in rooms
    
    entity_add -- add uuid to entity
    entity_remove
    entity_update -- manual update, usage example?

    send -- data
    
    -- events
    trigger
    receive -- data
    client_enter
    client_leave
    ]]
}

function love.load()
    Net.host()
end

function love.update(dt)
    Net.update(dt)
end

function love.draw()
    Debug.draw()
end