local _views = {}
Group = Class{
	init = function (self)
		self.entities = {}
	end,

	add = function(self, ent)
		table.insert(self.entities, ent)
	end,

	remove = function(self, i)
		self.entities[i] = nil
	end,

	closest_point = function(self, x, y)
		local min_dist, min_ent

		for i_e, e in ipairs(self.entities) do
			local dist = e:distance_point(x, y)
			if dist < min_dist then
				min_dist = dist
				min_ent = e
			end
		end

		return min_ent
	end,

	closest = function(self, ent)
		return self:closest_point(ent.x, ent.y)
	end,
}