Net = {
    entity_update_rate = 500, -- m/s
    
    is_init = false,
    host = nil,
    server = nil,
    
    address = "localhost:12345",
    
    init = function(address)
        require "plugins.lube"
        
        Net.address = ifndef(address, "localhost:12345")
        Debug.log(Net.address)
        
        if not is_init then      
            Signal.register("love.update", function(dt)
                if Net.host then
                    local evt = Net.host:service(100)
                    
                    for i_evt, event in ipairs(evt) do
                        if event.type == "receive" then
                            Debug.log("Got message: ", event.data, event.peer)
                            event.peer:send( "pong" )
                        elseif event.type == "connect" then
                            Debug.log(event.peer, "connected.")
                        elseif event.type == "disconnect" then
                            Debug.log(event.peer, "disconnected.")
                        else
                            Debug.log(dt)
                        end
                        event = host:service()
                    end
                    
                end
            end) -- Signal.register update
        end -- not is_init
        
    end,

    -- returns "Server" object
    host = function(address)
        Net.init(address)
        
        Net.host = enet.host_create(Net.address)
        -- room_create() -- default room
    end,
    
    -- returns "Client" object
    join = function(address) 
        Net.init(address)
        
        Net.host = enet.host_create()
        Net.server = Net.host:connect(Net.address)
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