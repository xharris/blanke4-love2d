require 'includes'

function love.load()
	Signal.emit('love.load') -- used to register first game state
  
end

function love.update(dt)
    Signal.emit('love.update', dt)
    
end

--[[

other love functions:
- love.draw()
- love.mousepressed(x, y, button, istouch)
- love.keypressed(key)
- love.keyreleased(key)
- love.focus(f)
- love.quit()

]]--