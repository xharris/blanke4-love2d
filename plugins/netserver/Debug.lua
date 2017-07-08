Debug = {
    lines = {},
    
    draw = function()
        for i_line, line in ipairs(Debug.lines) do
            love.graphics.push()
            local alpha = 255
            local margin = 12
            local y = (i_line-1)*margin
            if y > love.graphics:getHeight()/2 then
                alpha = 255 - ((y-love.graphics:getHeight()/2)/(love.graphics:getHeight()/2)*255)
            end
            love.graphics.setColor(255,0,0,alpha)
            love.graphics.print(line, margin, y)
            love.graphics.pop()
        end
    end,
    
    log = function(...)
        table.insert(Debug.lines, 1, tostring(...))
        print(...)
    end,

    clear = function()
        Debug.lines = {}
    end
}

return Debug