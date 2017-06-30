local assets = require "assets"
 
_Entity = Class{
	_images = {},		
	_sprites = {}, 			-- is actually the animations
	sprite = nil,			-- currently active animation

	-- x and y coordinate of sprite
	x = 0,	
	y = 0,
    auto_update = AUTO_UPDATE,

	-- sprite/animation variables
	_sprite_prev = '', 		-- previously used sprite
	sprite_index = '',		-- string index of the current sprite
	sprite_width = 0, 		-- readonly
	sprite_height = 0,		-- readonly
	sprite_angle = 0, 		-- angle of sprite in degrees
	sprite_xscale = 1,		
	sprite_yscale = 1,
	sprite_xoffset = 0,
	sprite_yoffset = 0,
	sprite_xshear = 0,
	sprite_yshear = 0,
	sprite_color = {['r']=255,['g']=255,['b']=255},
	sprite_alpha = 255,
	sprite_speed = 1,
	sprite_frame = 0,

	-- movement variables
	direction = 0,
	friction = 0,
	gravity = 0,
	gravity_direction = 0,
	hspeed = 0,
	vspeed = 0,
	speed = 0,
	xprevious = 0,
	yprevious = 0,
	xstart = 0,
	ystart = 0,

	-- collision
	shapes = {},
	_main_shape = '',
	collisionStop = nil,
	collisionStopX = nil,
	collisionStopY = nil,	

	onCollision = {["*"] = function() end},
    
    on_include = function(self)
        table.insert(game.entity, self)
    end,
    
    update = function(self, dt)
		-- bootstrap sprite:goToFrame()
		if not self.sprite then
			self.sprite = {}
			self.sprite.gotoFrame = function()end
		end

		if self.preUpdate then
			self:preUpdate(dt)
		end	

		if self.sprite ~= nil and self.sprite.update ~= nil then
			self.sprite:update(self.sprite_speed*dt)
		end

		-- x/y extra coordinates
		if self.xstart == 0 then
			self.xstart = self.x
		end
		if self.ystart == 0 then
			self.ystart = self.y
		end

		-- move shapes if the x/y is different
		if self.xprevious ~= self.x or self.yprevious ~= self.y then
			for s, shape in pairs(self.shapes) do
				-- account for x/y offset?
				--shape:moveTo(self.x + shape.xoffset, self.y + shape.yoffset)
			end
		end

		self.xprevious = self.x
		self.yprevious = self.y

		-- calculate speed/direction
		local speedx = self.speed * math.cos(math.rad(self.direction))
		local speedy = self.speed * math.sin(math.rad(self.direction))

		-- calculate gravity/gravity_direction
		local gravx = self.gravity * math.cos(math.rad(self.gravity_direction))
		local gravy = self.gravity * math.sin(math.rad(self.gravity_direction))
	
		self.hspeed = self.hspeed + gravx
		self.vspeed = self.vspeed + gravy

		local dx = self.hspeed + speedx
		local dy = self.vspeed + speedy

		local _main_shape = self.shapes[self._main_shape]

		-- check for collisions
		for name, fn in pairs(self.onCollision) do
			-- make sure it actually exists
			if self.shapes[name] ~= nil then
				local collisions = HC.collisions(self.shapes[name])
				for other, separating_vector in pairs(collisions) do
                
					-- collision action functions
					self.collisionStopX = function(self)
						for name, shape in pairs(self.shapes) do
							shape:move(separating_vector.x, 0)
						end
			            self.hspeed = 0
			            dx = 0
					end

					self.collisionStopY = function(self)
						for name, shape in pairs(self.shapes) do
							shape:move(0, separating_vector.y)
						end
			            self.vspeed = 0
			            dy = 0
					end
					
					self.collisionStop = function(self)
						self:collisionStopX()
						self:collisionStopY()
					end

					-- call users collision callback if it exists
					fn(other, separating_vector)
				end
			end
		end
        
		-- move all shapes
		for s, shape in pairs(self.shapes) do
			shape:move(dx*dt, dy*dt)
		end

		-- set position of sprite
		if self.shapes[self._main_shape] ~= nil then
			self.x, self.y = self.shapes[self._main_shape]:center()
		else
			self.x = self.x + dx*dt
			self.y = self.y + dy*dt
		end

		if self.speed > 0 then
			self.speed = self.speed - (self.speed * self.friction)*dt
		end

		if self.postUpdate then
			self:postUpdate(dt)
		end	
	end,

	getCollisions = function(self, shape_name)
		if self.shapes[shape_name] then
			return HC.collisions(self.shapes[shape_name])
		end
		--return {}
	end,

	debugSprite = function(self)
		local sx = self.sprite_xoffset
		local sy = self.sprite_yoffset

		love.graphics.push()
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.rad(self.sprite_angle))
		love.graphics.shear(self.sprite_xshear, self.sprite_yshear)
		love.graphics.scale(self.sprite_xscale, self.sprite_yscale)

		-- draw sprite outline
		love.graphics.rectangle("line", -sx, -sy, self.sprite_width, self.sprite_height)

		-- draw origin point
		love.graphics.circle("line", 0, 0, 2)

		love.graphics.pop()
	end,

	debugCollision = function(self)
		-- draw collision shapes
		for s, shape in pairs(self.shapes) do
			shape:draw("line")
		end
	end,

	setSpriteIndex = function(self, index)
		self.sprite_index = index
		self.sprite = self._sprites[self.sprite_index]
	end,

	draw = function(self)
		if self.preDraw then
			self:preDraw()
		end

		self.sprite = self._sprites[self.sprite_index]

		if self.sprite ~= nil then
			-- sprite dimensions
			if self._sprite_prev ~= self.sprite_index  then
				self.sprite_width, self.sprite_height = self.sprite:getDimensions()
				self._sprite_prev = self.sprite_index
			end

			-- draw current sprite (image, x,y, angle, sx, sy, ox, oy, kx, ky) s=scale, o=origin, k=shear
			local img = self._images[self.sprite_index]
			love.graphics.push()
			love.graphics.setColor(self.sprite_color.r, self.sprite_color.g, self.sprite_color.b, self.sprite_alpha)
			
			-- is it an Animation or an Image
			if self.sprite.update ~= nil then
				self.sprite:draw(img, self.x, self.y, math.rad(self.sprite_angle), self.sprite_xscale, self.sprite_yscale, self.sprite_xoffset, self.sprite_yoffset, self.sprite_xshear, self.sprite_yshear)
			elseif img then
				love.graphics.draw(img, self.x, self.y, math.rad(self.sprite_angle), self.sprite_xscale, self.sprite_yscale, self.sprite_xoffset, self.sprite_yoffset, self.sprite_xshear, self.sprite_yshear)
			end
			love.graphics.pop()
		else
			self.sprite_width = 0
			self.sprite_height = 0
		end

		if self.postDraw then
			self:postDraw()
		end
	end,

	addAnimation = function(...)
		local args = {...}
		local self = args[1]

		local ani_name = args[2]
		local name = args[3]
		local frames = args[4]
		local other_args = {}

		-- get other args
		for a = 5,#args do
			table.insert(other_args, args[a])
		end

		if assets[name] ~= nil then
			local sprite, image = assets[name]()

			-- this is an image not a spritesheet
			if image == nil then
				self._images[ani_name] = sprite
				self._sprites[ani_name] = sprite
			else
				local sprite = anim8.newAnimation(sprite(unpack(frames)), unpack(other_args))

				self._images[ani_name] = image
				self._sprites[ani_name] = sprite
			end
		end	
	end,

	-- add a collision shape
	-- str shape: rectangle, polygon, circle, point
	-- str name: reference name of shape
	addShape = function(self, name, shape, args, tag)
		local new_hitbox = Hitbox(shape, self.x, self.y, args, tag)
		new_hitbox.auto_update = false
		new_hitbox:disable()
		local new_shape = new_hitbox:getHCShape()

        new_shape.parent_ent = self
		self.shapes[name] = new_shape

		HC.register(new_shape)
	end,

	-- remove a collision shape
	removeShape = function(self, name)
		if self.shapes[name] ~= nil then
			HC.remove(self.shapes[name])
		end
	end,

	-- the shape that the sprite will follow
	setMainShape = function(self, name, x_offset, y_offset) 
		if self.shapes[name] ~= nil then
			self._main_shape = name
		end 
	end,

	distance_point = function(self, x, y)
		return math.sqrt((x - self.x)^2 + (y - self.y)^2)
	end,

	-- other : Entity object
	-- returns distance between center of self and other object in pixels
	distance = function(self, other)
		return self:distance(other.x, other.y)
	end,

	-- self direction and speed will be set towards the given point
	-- this method will not set the speed back to 0 
	move_towards_point = function(self, x, y, speed)
		self.direction = math.deg(math.atan2(y - self.y, x - self.x))
		self.speed = speed
	end,
    
    -- checks if the point is inside the current sprite
    contains_point = function(self, x, y)
        if x >= self.x and y >= self.y and x < self.x + self.sprite_width and  y < self.y + self.sprite_height then
            return true
        end
        return false
    end
}

return _Entity