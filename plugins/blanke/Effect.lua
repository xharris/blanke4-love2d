local _effects = {}
Effect = Class{
	init = function (self, name)
		self._shader = nil
		self._effect_data = nil
		self.canvas = {love.graphics.newCanvas()}

		-- load stored effect
		assert(_effects[name]~=nil, "Effect '"..name.."' not found")
		if _effects[name] then
			self._effect_data = _effects[name]

			-- turn options into member variables
			for p, default in pairs(_effects[name].params) do
				self[p] = default

				if p == "textureSize" then
					self[p] = {game_width, game_height}
				end
			end	

			-- setup shader
			self._shader = love.graphics.newShader(_effects[name].string)
		end	

		_addGameObject('effect',self)
	end,

	update = function(self, dt)
		if self.time then self.time = self.time + dt end
		if self.dt then self.dt = self.dt + dt end
		if self.screen_size then self.screen_size = {game_width, game_height} end
		if self.inv_screen_size then self.inv_screen_size = {1/game_width, 1/game_height} end
	end,

	draw = function (self, func)
		if not self._effect_data.extra_draw then
			love.graphics.setCanvas(self.canvas[1])
			love.graphics.clear()
			
			if func then
				func()
			end
			love.graphics.setCanvas()

			love.graphics.setShader(self._shader)
			-- send variables
			for p, default in pairs(self._effect_data.params) do
				local var_name = p
				local var_value = default

				if self[p] then
					var_value = self[p]
					self:send(var_name, var_value)
				end
			end
			love.graphics.draw(self.canvas[1])

			self:clear()
		-- call extra draw function
		else
			self._effect_data:extra_draw(func)
		end
	end,

	send = function (self, name, value)
		self._shader:send(name, value)
	end,

	clear = function(self)
		love.graphics.setShader()
	end
}

local _love_replacements = {
	["float"] = "number",
	["sampler2D"] = "Image",
	["uniform"] = "extern",
	["texture2D"] = "Texel"
}
EffectManager = Class{
	new = function (options)
		local new_eff = {}
		new_eff.string = options.code
		new_eff.params = options.params
		new_eff.extra_draw = options.draw

		-- port non-LoVE keywords
		local r
		for old, new in pairs(_love_replacements) do
			new_eff.string, r = new_eff.string:gsub(old, new)
		end

		_effects[options.name] = new_eff
		return Effect(options.name)
	end,

	load = function(self, file_path)
		love.filesystem.load(file_path)()
	end,

	_render_to_canvas = function(self, canvas, func)
		local old_canvas = love.graphics.getCanvas()

		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		func()

		love.graphics.setCanvas(old_canvas)
	end
}

-- global shader vals: https://www.love2d.org/wiki/Shader_Variables

EffectManager.new{
	name = 'template',
	params = {['myNum']=1},
	code = [[
extern number myNum;

#ifdef VERTEX
	vec4 position( mat4 transform_projection, vec4 vertex_position ) {
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	// color 			- color set by love.graphics.setColor
	// texture 			- image being drawn
	// texture_coords 	- coordinates of pixel relative to image (x, y)
	// screen_coords 	- coordinates of pixel relative to screen (x, y)

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
		// Texel returns a pixel color after taking in a texture and coordinates of pixel relative to texture
		// Texel -> (r, g, b)
		vec4 pixel = Texel(texture, texture_coords );	

		pixel.r = pixel.r * myNum;
		pixel.g = pixel.g * myNum;
		pixel.b = pixel.b * myNum;
		return pixel;
	}
#endif
	]]
}

-- load bundled effects
eff_files = love.filesystem.getDirectoryItems('plugins/blanke/effects')
for i_e, effect in pairs(eff_files) do
	EffectManager:load('plugins/blanke/effects/'..effect)
end

--[[
scale with screen position

vec2 screenSize = love_ScreenSize.xy;        
number factor_x = screen_coords.x/screenSize.x;
number factor_y = screen_coords.y/screenSize.y;
number factor = (factor_x + factor_y)/2.0;

]]--

return Effect