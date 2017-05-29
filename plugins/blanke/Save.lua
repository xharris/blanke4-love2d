Save = {
    file_path = "",
    file_name = "_",
    file_data = {}
}
    
Save.open = function(name)
    Save.file_name = name
    Save.file_path = Save.file_name
    
    -- file exists check
    if love.filesystem.exists(Save.file_path) then
        local contents = love.filesystem.read(Save.file_path)
        Save.file_data = json.decode(contents)
    end
end

-- open must be called first
Save.write = function(key, value)
    Save.file_data[key] = value
    Save:save()
end

-- open must be called first
Save.read = function(key)
    return Save.file_data[key]
end

-- saves the currently loaded file
Save.save = function()
    local json_data = json.encode(Save.file_data)
    print(json_data)
    local success = love.filesystem.write(Save.file_path, json_data)
    print(success)
end

-- check if a key exists (usually before reading)
Save.has_key = function(key)
    return (Save.file_data[key] ~= nil)
end

Save.open('_')

return Save