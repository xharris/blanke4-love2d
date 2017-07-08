local assets = require "assets"
 
Entity = Class{
    init = function(self)    
	    self._images = {}		
		self._sprites = {} 			-- is actually the animations
		self.sprite = nil			-- currently active animation

		-- x and y coordinate of sprite
		self.x = 0
		self.y = 0

		-- sprite/animation variables
		self._sprite_prev = '' 		-- previously used sprite
		self.sprite_index = ''		-- string index of the current sprite
		self.sprite_width = 0		-- readonly
		self.sprite_height = 0		-- readonly
		self.sprite_angle = 0		-- angle of sprite in degrees
		self.sprite_xscale = 1	
		self.sprite_yscale = 1
		self.sprite_xoffset = 0
		self.sprite_yoffset = 0
		self.sprite_xshear = 0
		self.sprite_yshear = 0
		self.sprite_color = {['r']=255,['g']=255,['b']=255}
		self.sprite_alpha = 255
		self.sprite_speed = 1
		self.sprite_frame = 0

		-- movement variables
		self.direction = 0
		self.friction = 0
		self.gravity = 0
		self.gravity_direction = 0
		self.hspeed = 0
		self.vspeed = 0
		self.speed = 0
		self.xprevious = 0
		self.yprevious = 0
		self.xstart = 0
		self.ystart = 0

		-- collision
		self.shapes = {}
		self._main_shape = ''
		self.collisionStop = nil
		self.collisionStopX = nil
		self.collisionStopY = nil	

		-- networking
		self.is_net_entity = false
		self.net_uuid = uuid()

		self.onCollision = {["*"] = function() end}
    	_addGameObject('entity', self)
    end,
    
    update = function(self, dt)
		-- bootstrap sprite:goToFrame()
		if not self.sprite then
			self.sprite = {}
			self.sprite.gotoFrame = function() end
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
				shape:moveTo(self.x, self.y)
			end
            if not self.is_net_entity then Net.updateEntities() end
		end

		self.xprevious = self.x
		self.yprevious = self.y

		-- calculate speed/direction
		local speedx = self.speed * math.cos(math.rad(self.direction))
		local speedy = self.speed * math.sin(math.rad(self.direction))

		-- calculate gravity/gravity_direction
		local gravx = self.gravity * math.cos(math.rad(self.gravity_direction))
		local gravy = self.gravity * math.sin(math.rad(self.gravity_direction))
	
		--self.hspeed = ifndef(self.hspeed, 0)
		--self.vspeed = ifndef(self.vspeed, 0)

		self.hspeed = self.hspeed + gravx
		self.vspeed = self.vspeed + gravy

		local dx = self.hspeed + speedx
		local dy = self.vspeed + speedy

		local _main_shape = self.shapes[self._main_shape]

		-- check for collisions
		for name, fn in pairs(self.onCollision) do
			-- make sure it actually exists
			if self.shapes[name] ~= nil then
				local obj_shape = self.shapes[name]:getHCShape()

				local collisions = HC.collisions(obj_shape)
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
			local hc_shape = self.shapes[shape_name]:getHCShape()
			return HC.collisions(self.shapes[shape_name])
		end
		--return {}
	end,

	debugSprite = function(self)
		local sx = self.sprite_xoffset
		local sy = self.sprite_yoffset

		love.graphics.push("all")
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.rad(self.sprite_angle))
		love.graphics.shear(self.sprite_xshear, self.sprite_yshear)
		love.graphics.scale(self.sprite_xscale, self.sprite_yscale)

		-- draw sprite outline
		love.graphics.setColor(0,255,0,255*(2/3))
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
		assert(self._sprites[index], "Animation not found: \'"..index.."\'")

		self.sprite_index = index
		self.sprite = self._sprites[self.sprite_index]

		if self._sprite_prev ~= self.sprite_index then
			self:_refreshSpriteDims()
			self._sprite_prev = self.sprite_index
		end
	end,

	_refreshSpriteDims = function(self)
		self.sprite_width, self.sprite_height = self.sprite:getDimensions()
	end,

	draw = function(self)
		if self.preDraw then
			self:preDraw()
		end

		self:setSpriteIndex(self.sprite_index)

		if self.sprite ~= nil then
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
		tag = ifndef(tag, self.classname..'.'..name)
		local new_hitbox = Hitbox(shape, args, tag, self.x, self.y)
		new_hitbox:setParent(self)
		self.shapes[name] = new_hitbox
	end,

	-- remove a collision shape
	removeShape = function(self, name)
		if self.shapes[name] ~= nil then
			self.shapes:disable()
		end
	end,

	-- the shape that the sprite will follow
	setMainShape = function(self, name) 
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

return Entity