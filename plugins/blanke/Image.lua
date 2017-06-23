local assets = require "assets"

local _images = {}
 
Image = Class{
	init = function(self, name)
		self.name = name

		if _images[name] == nil then
			assert(assets[name] ~= nil, "No image named '"..name.."'")
			_images[name] = assets[name]()
		end
		self.image = _images[name]

		self.x = 0
		self.y = 0
		self.angle = 0
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.color = {['r']=255,['g']=255,['b']=255}
		self.alpha = 255

		self.orig_width = self.image:getWidth()
		self.orig_height = self.image:getHeight()
		self.width = self.orig_width
		self.height = self.orig_height
	end,

	setWidth = function(self, width)
		self.xscale = width / self.orig_width
	end,

	setHeight = function(self, height)
		self.yscale = height / self.orig_height
	end,

	draw = function(self)
		self.width = self.orig_width * self.xscale
		self.height = self.orig_height * self.yscale

		love.graphics.push()
		love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)	
		love.graphics.draw(self.image, self.x, self.y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		love.graphics.pop()
	end
}

return Image