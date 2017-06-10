Input = Class{
	inputs = {},
	onInput = nil,
	_on = false, -- are any of the inputs active?

	init = function(self, ...)
		-- store inputs
		arg_inputs = {...}
		for i_in, input in ipairs(arg_inputs) do
			self:add(input)
		end

		-- keyboard 
	end,

	add = function(self, input)
		table.insert(self.inputs, input)
	end,

	
}
function Input.__call(self, ...)
	return self._on
end
return Input