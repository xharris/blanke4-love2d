AUTO_UPDATE = true
mouse_x = 0
mouse_y = 0
game_width = 0
game_height = 0
game_time = 0

function updateGlobals(dt)
	game_time = game_time + dt
	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()
	game_width = love.graphics.getWidth()
	game_height = love.graphics.getHeight()
end