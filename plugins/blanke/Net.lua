Net = {
    entity_update_rate = 500, -- m/s
    
    is_init = false,
    client = nil,
    server = nil,
    
    onReceive = nil,    -- data
    onConnect = nil,    -- id
    onDisconnect = nil, -- id
    
    address = "localhost",
    port = 12345,
    
    init = function(address, port)
        require "plugins.lube"
        
        Net.address = ifndef(address, "localhost")
        Debug.log(Net.address)
        
        if not is_init then        
            Signal.register("love.update", function(dt)
                if Net.server then Net.server:update(dt) end
                if Net.client then Net.client:update(dt) end
            end) -- Signal.register update
        end -- not is_init
        
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
        
        --Net.client:send("hello") -- server always receives and prints this (see above)
        return success
    end,
    
    _onConnect = function(id)
        if Net.onConnect then Net.onConnect(id) end
    end,
    
    _onDisconnect = function(id) 
        if Net.onDisconnect then Net.onDisconnect(id) end
    end,
    
    _onReceive = function(data)
        if Net.onReceive then Net.onReceive(data) end
    end
    
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