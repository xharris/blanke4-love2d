local _views = {}
View = Class{
	init = function (self)
		table.insert(_views, self)

		self._dt = 0
		self.auto_update = true

		self.camera = Camera(0, 0)
		self.follow_entity = nil
		self.follow_x = 0
		self.follow_y = 0

		self.motion_type = 'none' -- linear, smooth
		self.speed = 1 
		self.max_distance = 0
		self._last_motion_type = self.motion_type
		self._last_speed = self.speed
		self._smoother = nil

		self.angle = 0
		self.rot_speed = 5
		self.rot_type = 'none'
        
		self.scale_x = 1
        self.scale_y = 1
		self.zoom_speed = .5
		self.zoom_type = 'none'
        
        self.port_x = 0
        self.port_y = 0
        self.port_width = love.graphics:getWidth()
        self.port_height = love.graphics:getHeight()
        self.noclip = false
        
        self.shake_x = 0
        self.shake_y = 0
        self.shake_intensity = 7
        self.shake_falloff = 2.5
        self.shake_type = 'smooth'
        
        table.insert(game.view, self)
        --[[
		Signal.register('love.update', function(dt)
			self._dt = dt
			if self.auto_update then
				self:update()
			end
		end)
        ]]--
	end,

	follow = function(self, entity)
		self.followEntity = entity

		self:update()
	end,

	moveTo = function(self, entity) 
		self.follow_x = entity.x
		self.follow_y = entity.y

		self:update()
	end,	

	moveToPosition = function(self, x, y, fromUpdate)
		self.follow_x = x
		self.follow_y = y

		-- if called from 'update', fromUpdate = dt
		if not fromUpdate then
			self:update()
		end
	end,

	snapTo = function(self, entity)
		self:snapToPosition(entity.x, entity.y)
	end,

	snapToPosition = function(self, x, y)
		self.camera:lookAt(x, y)
	end,

	rotateTo = function(self, angle)
		self.angle = angle
	end,

	zoom = function(self, scale_x, scale_y)
        if not scale_y then
            scale_y = scale_x
        end
        
        self.scale_x = scale_x
		self.scale_y = scale_y
	end,
    
    mousePosition = function(self)
        return self.camera:mousePosition()
    end,
    
    shake = function(self, x, y)
        if not y then
            y = x
        end
        
        self.shake_x = x
        self.shake_y = y
    end,
    
    squeezeH = function(self, amt)
        self.squeeze_x = math.abs(amt)
        self._squeeze_dt = 0
    end,

	update = function(self)
		if self.followEntity then
			local follow_x = self.followEntity.x
			local follow_y = self.followEntity.y

			self:moveToPosition(follow_x, follow_y, true)
		end

		-- determine the smoother to use 
		if self._last_speed ~= self.speed or self._last_motion_type ~= self.motion_type then
			if self.motion_type == 'none' then
				self._smoother = Camera.smooth.none()

			elseif self.motion_type == 'linear' then
				self._smoother = Camera.smooth.linear(self.speed)

			elseif self.motion_type == 'damped' then
				self._smoother = Camera.smooth.damped(self.speed)

			end
		end

		-- rotation
		if math.deg(self.camera.rot) ~= self.angle then
			local new_angle
			if self.rot_type == 'none' then
				new_angle = self.angle

			elseif self.rot_type == 'damped' then
				new_angle = lerp(math.deg(self.camera.rot), self.angle, self.rot_speed, self._dt)

			end
			self.camera:rotateTo(math.rad(new_angle))
		end

		-- zoom
        if self.scale_y == nil then
            self.scale_y = scale.scale_x
        end
        
		if self.camera.scale_x ~= self.scale_x or self.camera.scale_y ~= self.scale_y then
			local new_zoom_x = self.scale_x
            local new_zoom_y = self.scale_y
			if self.zoom_type == 'none' then
				new_zoom_x = self.scale_x
                new_zoom_y = self.scale_y

			elseif self.zoom_type == 'damped' then
				new_zoom_x = lerp(self.camera.scale_x, self.scale_x, self.zoom_speed, self._dt)
				new_zoom_y = lerp(self.camera.scale_y, self.scale_y, self.zoom_speed, self._dt)

			end
			self.camera:zoomTo(new_zoom_x, new_zoom_y)
		end
        
        -- shake
        local modifier = 1
        if self.shake_type == 'smooth' then
            modifier = 1
        elseif self.shake_type == 'rigid' then
            modifier =  (random_range(1, 20)/10)
        end
        
        local shake_x = sinusoidal(-self.shake_x, self.shake_x, self.shake_intensity * modifier, 0)
        local shake_y = sinusoidal(-self.shake_y, self.shake_y, self.shake_intensity * modifier, 0)
        
        if self.shake_y > 0 then
            self.shake_y = lerp(self.shake_y, 0 ,self._dt*self.shake_falloff)
        end
        
        if self.shake_x > 0 then
            self.shake_x = lerp(self.shake_x, 0 ,self._dt*self.shake_falloff)
        end
        
		-- move the camera
		local wx = love.graphics.getWidth()/2
		local wy = love.graphics.getHeight()/2
		self.camera:lockWindow(self.follow_x + shake_x, self.follow_y + shake_y, wx-self.max_distance, wx+self.max_distance,  wy-self.max_distance, wy+self.max_distance, self._smoother)
	end,

	attach = function(self)   
        self.camera:attach(self.port_x, self.port_y, self.port_width, self.port_height, self.noclip)
    end,

	detach = function(self)
		self.camera:detach()
	end,
}

return View