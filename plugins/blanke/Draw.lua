Draw = Class{
	color = {0,0,0,255},

	setColor = function(r,g,b,a)
		color = r
		if (type(color) == "string") then
			color = hex2rgb(color)
		end

		if (type(color) == "number") then
			color = {r,g,b,a}
		end
		Draw.color = color
	end,

	_draw = function(func)
		love.graphics.push('all')
		love.graphics.setColor(Draw.color)
		func()
		love.graphics.pop()
	end,

	rect = function(...)
		local args = {...}
		Draw._draw(function()
			love.graphics.rectangle(unpack(args))
		end)
	end,
}

return Draw