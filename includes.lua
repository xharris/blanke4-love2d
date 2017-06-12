game_name = "<GAME_NAME>"
game = {entity={}, view={}, map={}, input={}}

function _iterateGameGroup(group, func)
    for i, obj in ipairs(game[group]) do
        func(obj)
    end
end

require "plugins.json.json"

Class = require 'plugins.hump.class'

require 'plugins.blanke.Globals'
require 'plugins.blanke.Util'
require 'plugins.blanke.Debug'

Input = require 'plugins.blanke.Input'
Signal = require 'plugins.hump.signal'
Gamestate = require 'plugins.hump.gamestate'

Net = require 'plugins.blanke.Net'
Save = require 'plugins.blanke.Save'
_Entity = require 'plugins.blanke.Entity'
Map = require 'plugins.blanke.Map'
View = require 'plugins.blanke.View'
Effect = require 'plugins.blanke.Effect'
Dialog = require 'plugins.blanke.Dialog'

-- prevents updating while window is being moved (would mess up collisions)
max_fps = 120
min_dt = 1/max_fps
next_time = love.timer.getTime()
Gamestate.run = function(to, ...) 
	Gamestate.switch(to, ...)
	Gamestate.registerEvents()

	local old_update = Gamestate.update
	Gamestate.update = function(dt)
	    dt = math.min(dt, min_dt)
	    next_time = next_time + min_dt
		
		old_update(dt) 
	end

	local old_draw = Gamestate.draw
	Gamestate.draw = function()
        Debug.draw()
		old_draw()

	    local cur_time = love.timer.getTime()
	    if next_time <= cur_time then
	        next_time = cur_time
	        return
	    end
	    love.timer.sleep(next_time - cur_time)
	end
end

Timer = require 'plugins.hump.timer'
Vector = require 'plugins.hump.vector'
Camera = require 'plugins.hump.camera'
anim8 = require 'plugins.anim8'
HC = require 'plugins.HC'


assets = require 'assets'

<INCLUDES>

function love.load()
	-- register gamestates
    updateGlobals(0)
	if "<FIRST_STATE>" ~= "" then
		Gamestate.run(<FIRST_STATE>)
	end
  
end

function love.update(dt)
    updateGlobals(dt)
    
    Net.update(dt)
    
    for i_arr, arr in pairs(game) do
        for i_e, e in ipairs(arr) do
            if e.auto_update then
                e:update(dt)
            end
        end
    end
end

function love.keypressed(key)
    _iterateGameGroup("input", function(input)
        input:keypressed(key)
    end)
end

function love.keyreleased(key)
    _iterateGameGroup("input", function(input)
        input:keyreleased(key)
    end)
end

function love.mousepressed(x, y, button) 
    _iterateGameGroup("input", function(input)
        input:mousepressed(x, y, button)
    end)
end

function love.mousereleased(x, y, button) 
    _iterateGameGroup("input", function(input)
        input:mousereleased(x, y, button)
    end)
end