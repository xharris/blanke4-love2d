game_name = "<GAME_NAME>"
game = {entity={}, view={}, map={}}

require "plugins.json.json"

require 'plugins.blanke.Globals'
require 'plugins.blanke.Util'
require 'plugins.blanke.Debug'

Signal = require 'plugins.hump.signal'
Gamestate = require 'plugins.hump.gamestate'

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
		
        --Signal.emit('love.update', dt)
        for i_arr, arr in pairs(game) do
            for i_e, e in ipairs(arr) do
                if e.auto_update then
                    e:update(dt)
                end
            end
        end
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

Class = require 'plugins.hump.class'
Timer = require 'plugins.hump.timer'
Vector = require 'plugins.hump.vector'
Camera = require 'plugins.hump.camera'
anim8 = require 'plugins.anim8'
HC = require 'plugins.HC'

<INCLUDES>

assets = require 'assets'
Net = require 'plugins.blanke.Net'
Save = require 'plugins.blanke.Save'
_Entity = require 'plugins.blanke.Entity'
Map = require 'plugins.blanke.Map'
View = require 'plugins.blanke.View'
Effect = require 'plugins.blanke.Effect'
Dialog = require 'plugins.blanke.Dialog'
Input = require 'plugins.blanke.Input'

function love.load()
	-- register gamestates
    updateGlobals(0)
	if "<FIRST_STATE>" ~= "" then
		Gamestate.run(<FIRST_STATE>)
	end
  
end

function love.update(dt)
    updateGlobals(dt)
    
end