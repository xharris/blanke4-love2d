Hitbox = Class{
	init = function(self, shape, xoffset, yoffset, args, tag)
		self.HCShape = nil
		if shape == "rectangle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.rectangle(unpack(args))
		elseif shape == "polygon" then
			for a = 1, #args, 2 do
				args[a] = args[a] + xoffset
				args[a+1] = args[a+1] + yoffset
			end
			self.HCShape = HC.polygon(unpack(args))
		elseif shape == "circle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.circle(unpack(args))
		elseif shape == "point" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.point(unpack(args))
		end

		self.HCShape.xoffset = xoffset
		self.HCShape.yoffset = yoffset
		if shape ~= "polygon" then
			self.HCShape.xoffset = args[1] - xoffset
			self.HCShape.yoffset = args[2] - yoffset
		end

		self.HCShape.tag = tag

		self._enabled = true
		self.color = {255,0,0,255*(2/3)}
		self.parent = nil
		HC.register(self.HCShape)
	end,

	draw = function(self, mode)
		love.graphics.push()
		love.graphics.setColor(self.color)
		self.HCShape:draw(ifndef(mode, 'fill'))
		love.graphics.pop()
	end,

	getHCShape = function(self)
		return self.HCShape
	end,

	move = function(self, x, y)
		self.HCShape:move(x, y)
	end,

	center = function(self)
		return self.HCShape:center()
	end,	

	enable = function(self)
		if not self._enabled then
			self._enabled = true
			HC.register(self.HCShape)
		end
	end,

	disable = function(self)
		if self._enabled then
			self._enable = false
			HC.remove(self.HCShape)
		end
	end,

	setColor = function(self, new_color)
		self.color = hex2rgb(new_color)
		self.color[4] = 255/2
	end,

	setParent = function(self, parent)
		self.parent = parent
	end
}

return Hitbox