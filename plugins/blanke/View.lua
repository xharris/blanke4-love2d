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

		self.scale = 1
		self.zoom_speed = 5
		self.zoom_type = 'none'

		Signal.register('love.update', function(dt)
			self._dt = dt
			if self.auto_update then
				self:update()
			end
		end)
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
		self:camera:lookAt(x, y)
	end,

	rotateTo = function(self, angle)
		self.angle = angle
	end,

	zoom = function(self, scale)
		self.scale = scale
	end,

	update = function(self)
		if self.followEntity then
			local follow_x = self.followEntity.x
			local follow_y = self.followEntity.y

			self:goToPosition(follow_x, follow_y, true)
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
		if self.camera.scale ~= self.scale then
			local new_zoom
			if self.zoom_type == 'none' then
				new_zoom = self.scale

			elseif self.zoom_type == 'damped' then
				new_zoom = lerp(self.camera.scale, self.scale, self.zoom_speed, self._dt)

			end
			self.camera:zoomTo(new_zoom)
		end

		-- move the camera
		local wx = love.graphics.getWidth()/2
		local wy = love.graphics.getHeight()/2
		self.camera:lockWindow(self.follow_x, self.follow_y, wx-self.max_distance, wx+self.max_distance,  wy-self.max_distance, wy+self.max_distance, self._smoother)
	end,

	attach = function(self)
		self.camera:attach()
	end,

	detach = function(self)
		self.camera:detach()
	end,
}

return View