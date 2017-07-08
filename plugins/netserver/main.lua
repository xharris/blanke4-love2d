require 'class'
require 'lube'
local Debug = require 'Debug'

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
        require "plugins.lube"
        
        Net.address = ifndef(address, "localhost")  
        Net.uuid = uuid()      
        Net.is_init = true
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
    host = function(port)
        if not Net.is_init then
            Net.init(Net.address, port)      
            Net.server = lube.udpServer()
            
            Net.server.callbacks.connect = Net._onConnect
            Net.server.callbacks.disconnect = Net._onDisconnect
            Net.server.callbacks.recv = Net._onReceive

            Net.server.handshake = Net.uuid
            
            Net.server:listen(Net.port)
            -- room_create() -- default room
            return true
        end
        return false
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        if not Net.is_init then
            Net.init(address, port)
            Net.client = lube.udpClient()
            
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
            return true
        end
        return false
    end,
    
    _onConnect = function(data) 
        if Net.onConnect then Net.onConnect(data) end
    end,
    
    _onDisconnect = function(data) 
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
            local new_entity = _G[classname]()

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
                Debug.log('sync')
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
        Debug.log('send ' .. data)
        if Net.server then Net.server:send(data) end
        if Net.client then Net.client:send(data) end
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

    draw = function(obj_name)
        if Net._server_entities[obj_name] then
            for net_uuid, obj in pairs(Net._server_entities[obj_name]) do
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

function love.conf(t)
    t.identity = nil                    -- The name of the save directory (string)
    t.version = "0.10.2"                -- The LÖVE version this game was made for (string)
    t.console = true                   -- Attach a console (boolean, Windows only)
    t.accelerometerjoystick = true      -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    t.externalstorage = false           -- True to save files (and read from the save directory) in external storage on Android (boolean) 
    t.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)
 
    t.window.title = "Server"         -- The window title (string)
    t.window.icon = nil                 -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800                -- The window width (number)
    t.window.height = 600               -- The window height (number)
    t.window.borderless = false         -- Remove all border visuals from the window (boolean)
    t.window.resizable = false          -- Let the window be user-resizable (boolean)
    t.window.minwidth = 1               -- Minimum window width if the window is resizable (number)
    t.window.minheight = 1              -- Minimum window height if the window is resizable (number)
    t.window.fullscreen = false         -- Enable fullscreen (boolean)
    t.window.fullscreentype = "desktop" -- Choose between "desktop" fullscreen or "exclusive" fullscreen mode (string)
    t.window.vsync = true               -- Enable vertical sync (boolean)
    t.window.msaa = 0                   -- The number of samples to use with multi-sampled antialiasing (number)
    t.window.display = 1                -- Index of the monitor to show the window in (number)
    t.window.highdpi = false            -- Enable high-dpi mode for the window on a Retina display (boolean)
    t.window.x = nil                    -- The x-coordinate of the window's position in the specified display (number)
    t.window.y = nil                    -- The y-coordinate of the window's position in the specified display (number)
 
    t.modules.audio = false              -- Enable the audio module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = false              -- Enable the image module (boolean)
    t.modules.joystick = false           -- Enable the joystick module (boolean)
    t.modules.keyboard = false           -- Enable the keyboard module (boolean)
    t.modules.math = false               -- Enable the math module (boolean)
    t.modules.mouse = false              -- Enable the mouse module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)
    t.modules.sound = false              -- Enable the sound module (boolean)
    t.modules.system = false             -- Enable the system module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = false              -- Enable the touch module (boolean)
    t.modules.video = false              -- Enable the video module (boolean)
    t.modules.window = true             -- Enable the window module (boolean)
    t.modules.thread = true             -- Enable the thread module (boolean)
end

function love.load()
    Debug.log('hi')
end

function love.update(dt)

end

function love.draw()
    Debug.draw()
end