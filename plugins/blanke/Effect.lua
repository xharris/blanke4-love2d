local _effects = {}
Effect = Class{
	init = function (self, name)
		self._shader = nil
		self._effect_data = nil
		self.canvas_h, self.canvas_v = love.graphics.newCanvas(), love.graphics.newCanvas()

		-- load stored effect
		if _effects[name] then
			self._effect_data = _effects[name]

			-- turn options into member variables
			for p, default in pairs(_effects[name].params) do
				self[p] = default
			end	

			-- setup shader
			self._shader = love.graphics.newShader(_effects[name].string)
		end	
	end,

	draw = function (self, func)
		if not self._effect_data.extra_draw then
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

			if func then
				func()
			end
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

	_render_to_canvas = function(self, canvas, func)
		local old_canvas = love.graphics.getCanvas()

		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		func()

		love.graphics.setCanvas(old_canvas)
	end
}

EffectManager.new{
	name = 'grayscale',
	params = {['factor']=1},
	code = [[
        extern number factor;
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
            vec4 pixel = Texel(texture, texture_coords );
            
            number average = (pixel.r + pixel.b + pixel.g)/3.0;
            
            pixel.r = pixel.r + (average-pixel.r) * factor;
            pixel.g = pixel.g + (average-pixel.g) * factor;
            pixel.b = pixel.b + (average-pixel.b) * factor;
            
            return pixel;
        }
	]]
}

EffectManager.new{
	name = 'chroma shift',
	params = {['strength'] = {1, 1}, ['size'] = {20, 20}},
	code = [[ 
		#ifdef PIXEL
		extern vec2 strength;
		extern vec2 size;

		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
		{
			//vec2 screenSize = love_ScreenSize.xy;        
			//number factor_x = pc.x/screenSize.x;
			//number factor_y = pc.y/screenSize.y;
			//number factor = (factor_x + factor_y)/2.0;

            vec2 shift = (strength / size);// * factor;
			return vec4(Texel(tex, tc+shift).r, Texel(tex,tc).g, Texel(tex,tc-shift).b, Texel(tex, tc).a);
		}
		#endif
	]]
}

-- wtf even is this one
-- noisetex: img
-- tex_ratio: {love.graphics.getWidth() / img:getWidth(), love.graphics.getHeight() / img:getHeight()}
EffectManager.new{
	name = 'filmgrain',
	params = {
		opacity = .3,
		grainsize = 1,
		noise = 0,
		noisetex = nil,
		tex_ratio = 0
	},
	code = [[
		extern number opacity;
		extern number grainsize;
		extern number noise;
		extern Image noisetex;
		extern vec2 tex_ratio;

		float rand(vec2 co)
		{
			return Texel(noisetex, mod(co * tex_ratio / vec2(grainsize), vec2(1.0))).r;
		}
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return color * Texel(texture, tc) * mix(1.0, rand(tc+vec2(noise)), opacity);
		}
	]]	
}

-- beatiful inner shadows around border
EffectManager.new{
	name = 'vignette',
	params = {
		radius = 1,
		softness = .45,
		opacity = .5,
		aspect = love.graphics.getWidth() / love.graphics.getHeight(),
	},
	code = [[
		extern number radius;
		extern number softness;
		extern number opacity;
		extern number aspect;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			color = Texel(texture, tc);
			number v = smoothstep(radius, radius-softness, length((tc - vec2(0.5f)) * aspect));
			return mix(color, color * v, opacity);
		}	
	]]
}

EffectManager.new{
	name = 'colorgradesimple',
	params = {
		grade = {1.0, 1.0, 1.0}
	},
	code = [[
		extern vec3 grade;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return vec4(grade, 1.0f) * Texel(texture, tc) * color;
		}
	]]	
}
--[[
  		VVVVV DONT WORK VVVVV
]] --
EffectManager.new{
	name = 'ripple',
	params = {['x'] = 0, ['y'] = 0, ['time'] = 0, ['img'] = nil},
	code = [[
		extern number time = 0.0;
        extern number x = 0.25;
        extern number y = -0.25;
        extern number size = 32.0;
        extern number strength = 8.0;
        extern vec2 res = vec2(512.0, 512.0);
        uniform sampler2D img;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
            float tmp = cos(clamp(sqrt(pow((texture_coords.x - x) * size - size / 2.0, 2.0) + pow((texture_coords.y - y) * size - size / 2.0, 2.0)) - time * 16.0, -3.1415, 3.1415));
            vec2 uv         = vec2(
                texture_coords.x - tmp * strength / 1024.0,
                texture_coords.y - tmp * strength / 1024.0
            );
         return vec4(texture2D(img,uv));
        }
	]]
}

EffectManager.new{
	name = 'box_blur',
	params = {['direction'] = {1,0}, ['radius'] = {1, 1}},
	code = [[
		extern vec2 direction;
		extern number radius;
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			vec4 c = vec4(0.0f);
			for (float i = -radius; i <= radius; i += 1.0f)
			{
				c += Texel(texture, tc + i * direction);
			}
			return c / (2.0f * radius + 1.0f) * color;
		}
	]],
	draw = function(self, func)
		print_r(func)
		local s = love.graphics.getShader()
		local co = {love.graphics.getColor()}

		-- draw scene
		EffectManager:_render_to_canvas(self.canvas_h, func)

		love.graphics.setColor(co)
		love.graphics.setShader(self._shader)

		local b = love.graphics.getBlendMode()
		love.graphics.setBlendMode('alpha', 'premultiplied')

		-- first pass (horizontal blur)
		self._shader:send('direction', {1 / love.graphics.getWidth(), 0})
		self._shader:send('radius', math.floor(self.radius[1] + .5))
		EffectManager:_render_to_canvas(self.canvas_v,
		                       love.graphics.draw, self.canvas_h, 0,0)

		-- second pass (vertical blur)
		self._shader:send('direction', {0, 1 / love.graphics.getHeight()})
		self._shader:send('radius', math.floor(self.radius[2] + .5))
		love.graphics.draw(self.canvas_v, 0,0)

		-- restore blendmode, shader and canvas
		love.graphics.setBlendMode(b)
		love.graphics.setShader(s)
	end
}

--[[
scale with screen position

vec2 screenSize = love_ScreenSize.xy;        
number factor_x = screen_coords.x/screenSize.x;
number factor_y = screen_coords.y/screenSize.y;
number factor = (factor_x + factor_y)/2.0;

]]--

return Effect