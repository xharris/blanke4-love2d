local assets = require "assets"

Scene = Class{
	init = function(self, name)
		self.load_objects = {}
		self.layers = {}
		self.images = {}

		if name then
			assert(assets[name] ~= nil, "No scene named '"..name.."'")
			self:load(assets[name]())
		end

		self.draw_hitboxes = false
		self.auto_update = true
		table.insert(game.scene, self)
	end,

	load = function(self, path, compressed)
		scene_string = love.filesystem.read(path)
		scene_data = json.decode(scene_string)

		self.load_objects = scene_data["object"]

		--[[
			image -> tile
			rect -> entity
			polygon -> hitbox
		]]
		for layer, data in pairs(scene_data["layer"]) do
			self.layers[layer] = {entity={},tile={},hitbox={}}

			if data["rect"] then
				for i_r, rect in ipairs(data["rect"]) do
					local uuid = rect.uuid
					local rect_obj = self.load_objects[uuid]

					self:addEntity(rect_obj.name, rect.x, rect.y, layer, rect_obj.width, rect_obj.height)
				end
			end

			if data["image"] then
				for i_i, image in ipairs(data["image"]) do
					local uuid = image.uuid
					local image_obj = self.load_objects[uuid]

					self:addTile(image_obj.name, image.x, image.y, image.crop, layer)
				end
			end

			if data["polygon"] then
				for i_h, hitbox in ipairs(data["polygon"]) do
					local uuid = hitbox.uuid
					local hitbox_obj = self.load_objects[uuid]

					-- turn points into array
					hitbox.points = hitbox.points:split(',')

					self:addHitbox(hitbox_obj.name, hitbox, layer)
				end
			end
		end
	end,

	_checkLayerArg = function(self, layer)
		if layer == nil then
			return self:_checkLayerArg(0)
		end
		if type(layer) == "number" then
			layer = "layer"..tostring(layer)
		end
		return layer
	end,

	addEntity = function(self, ent_name, x, y, layer, width, height) 
		layer = self:_checkLayerArg(layer)

		local new_entity = _G[ent_name](width, height)
		new_entity.x = x
		new_entity.y = y

		self.layers[layer]["entity"] = ifndef(self.layers[layer]["entity"], {})
		table.insert(self.layers[layer].entity, new_entity)
		return new_entity
	end,

	addTile = function(self, img_name, x, y, img_info, layer) 
		layer = self:_checkLayerArg(layer)

		-- check if the spritebatch exists yet
		self.layers[layer]["tile"] = ifndef(self.layers[layer]["tile"], {})
		self.images[img_name] = ifndef(self.images[img_name], Image(img_name))
		self.layers[layer].tile[img_name] = ifndef(self.layers[layer].tile[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))

		-- add tile to batch
		local spritebatch = self.layers[layer].tile[img_name]
		return spritebatch:add(love.graphics.newQuad(img_info.x, img_info.y, img_info.width, img_info.height, self.images[img_name].height, self.images[img_name].width), x, y)
	end,

	addHitbox = function(self, hit_name, hit_info, layer) 
		layer = self:_checkLayerArg(layer)

		self.layers[layer]["hitbox"] = ifndef(self.layers[layer]["hitbox"], {})
		local new_hitbox = Hitbox("polygon", 0, 0, hit_info.points, hit_name)
		new_hitbox:setColor(hit_info.color)
		table.insert(self.layers[layer].hitbox, new_hitbox)
	end,

	getEntity = function(self, in_entity, in_layer)
		local entities = {}
		for name, layer in pairs(self.layers) do
			if in_layer == nil or in_layer == layer then
				for i_e, entity in ipairs(layer.entity) do
					if entity.classname == in_entity then
						table.insert(entities, entity)
					end
				end
			end
		end

		if #entities == 1 then
			return entities[1]
		end
			return entities
	end,

	update = function(self, dt) 
		-- update entities
		for name, layer in pairs(self.layers) do
			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					entity:update(dt)
				end
			end

			if layer.hitbox then
				for i_h, hitbox in ipairs(layer.hitbox) do
					-- nothing at the moment
				end
			end
		end
	end,

	draw = function(self) 
		for name, layer in pairs(self.layers) do
			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					entity:draw()
				end
			end

			if layer.tile then
				for name, tile in pairs(layer.tile) do
					love.graphics.draw(tile)
				end
			end

			if layer.hitbox and self.draw_hitboxes then
				for i_h, hitbox in ipairs(layer.hitbox) do
					hitbox:draw()
				end
			end
		end
	end
}

return Scene