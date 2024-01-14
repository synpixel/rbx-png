local function switchEndianness(number: number)
	local b0 = bit32.lshift(bit32.band(number, 0x000000ff), 24)
	local b1 = bit32.lshift(bit32.band(number, 0x0000ff00), 8)
	local b2 = bit32.rshift(bit32.band(number, 0x00ff0000), 8)
	local b3 = bit32.rshift(bit32.band(number, 0xff000000), 24)
	return bit32.bor(b0, b1, b2, b3)
end

return switchEndianness
