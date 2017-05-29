Dialog = Class{
	init = function (self, x, y, width)
        self.x = x
        self.y = y
        self.width = ifndef(width, game_width - x)
        
        self.font_size = 12
        self.text_speed = 20
        self.align = "left"
        self.delay = 2000
        
        self.texts = {}
        self.text_char = 1
        
        self.timer = Timer.new()
        self.font_obj = love.graphics.newFont(self.font_size)
        self.text_obj = love.graphics.newText(self.font_obj, "")
    
        Signal.register('love.update', function(dt)
            self:update(dt)
        end)
    end,
    
    update = function(self, dt)
        self.timer:update(dt)
    end,
    
    draw = function(self)
        love.graphics.draw(self.text_obj, self.x, self.y)
    end,
    
    addText = function(self, text)
        table.insert(self.texts, text)
    end,
    
    _resetPrintVars = function(self)
        self.text_index = 1
        self.text_char = 1
    end,
    
    _addSubstr = function(self, str, isPlayAll)        
        -- display the new string
        local text_index = self.text_obj:setf(str, self.width, self.align)
        
        if #str < #self.texts[1] then
            self.timer:after(self.text_speed/1000, function()
                local extra_txt = str .. self.texts[1]:sub(self.text_char, self.text_char)
                self.text_char = self.text_char + 1
                self:_addSubstr(extra_txt, isPlayAll)
            end)
        else
            table.remove(self.texts, 1)

            if isPlayAll and #self.texts > 0 then
                -- show next text after delay
                self.timer:after(self.delay/1000, function()
                    self.text_char = 1
                    self:_addSubstr("", isPlayAll)
                end)
            else
                -- set text to nothing
                self.timer:after(self.delay/1000, function() self:reset() end)
            end
            
        end
    end,
    
    playAll = function(self)
        self:_resetPrintVars()
        local ret_val = self:_addSubstr("", true)
    end,
    
    -- remove all dialogs
    reset = function(self)
        self.texts = {}
        self.text_obj:set("")
        self:_resetPrintVars()
    end
}

return Dialog