local module = {}

module.double3toVector3 = function(double3)
	local x, y, z = tonumber(double3['X']), tonumber(double3['Y']), tonumber(double3['Z'])
	local v3 = Vector3.new(x, y, z)
	return v3
end

module.double4toFloats = function(double4)
	return double4['X'], double4['Y'], double4['Z'], double4['W']
end

return module
