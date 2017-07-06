Net = {
    entity_update_rate = 500, -- m/s
    
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

    _entity_property_excludes = {'^_images','^_sprites','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$'},
    
    init = function(address, port)
        require "plugins.lube"
        
        Net.address = ifndef(address, "localhost")        
        Net.is_init = true
    end,
    
    update = function(dt)
        if Net.is_init then
            if Net.server then Net.server:update(dt) end
            if Net.client then Net.client:update(dt) end

            Net._updateEntities()
        end
    end,

    -- returns "Server" object
    host = function(port)
        Net.init(Net.address, port)      

        Net.server = lube.udpServer()
        
        Net.server.callbacks.connect = Net._onConnect
        Net.server.callbacks.disconnect = Net._onDisconnect
        Net.server.callbacks.recv = Net._onReceive
        
        Net.server.handshake = "welcome ppl"
        
        Net.server:listen(Net.port)
        -- room_create() -- default room
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        Net.init(address, port)
        Net.client = lube.udpClient()
        
        Net.client.callbacks.recv = Net._onReceive
        
        Net.client.handshake = "join"
        
        Net.client:connect(Net.address, Net.port)
    end,
    
    _onConnect = function(data)
        if Net.onConnect then Net.onConnect(data) end
    end,
    
    _onDisconnect = function(data) 
        if Net.onDisconnect then Net.onDisconnect(data) end
    end,
    
    _onReceive = function(data)
        if data:starts('{') then
            data = json.decode(data)
        end

        if data.type and data.type == '_netevent' then
            -- new entity added
            if data.event == 'entity.add' then
                local info = data.info
                print_r(info)
                local new_entity = _G[data.info.classname]()
                data.info.classname = nil

                -- set properties
                for key, val in pairs(info) do
                    new_entity[key] = val
                end

                table.insert(Net._server_entities, new_entity)
            end
        end

        if Net.onReceive then Net.onReceive(data) end
    end,

    send = function(data) 
        data = json.encode(data)
        Net.client:send(data)
    end,

    addEntity = function(entity)
        table.insert(Net._client_entities, entity)
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

        --notify the other server clients
        Net.send({
            type='_netevent',
            event='entity.add',
            info=entity_info
        })
    end,

    _updateEntities = function()

    end,

    draw = function(obj_name)
        if Net._server_entities[obj_name] then
            for i, obj in ipairs(Net._server_entities[obj_name]) do
                obj:draw()
            end
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

return Net