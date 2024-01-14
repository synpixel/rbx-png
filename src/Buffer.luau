local Buffer = {}

local function readU8(self: Buffer)
	local result = buffer.readu8(self.buffer, self.cursor)
	self.cursor += 1
	return result
end

local function readI8(self: Buffer)
	local result = buffer.readi8(self.buffer, self.cursor)
	self.cursor += 1
	return result
end

local function readU16(self: Buffer)
	local result = buffer.readu16(self.buffer, self.cursor)
	self.cursor += 2
	return result
end

local function readI16(self: Buffer)
	local result = buffer.readi16(self.buffer, self.cursor)
	self.cursor += 2
	return result
end

local function readU32(self: Buffer)
	local result = buffer.readu32(self.buffer, self.cursor)
	self.cursor += 4
	return result
end

local function readI32(self: Buffer)
	local result = buffer.readi32(self.buffer, self.cursor)
	self.cursor += 4
	return result
end

local function readF32(self: Buffer)
	local result = buffer.readf32(self.buffer, self.cursor)
	self.cursor += 4
	return result
end

local function readF64(self: Buffer)
	local result = buffer.readf64(self.buffer, self.cursor)
	self.cursor += 8
	return result
end

local function readString(self: Buffer, count: number)
	local result = buffer.readstring(self.buffer, self.cursor, count)
	self.cursor += count
	return result
end

local function readAllBytes(self: Buffer)
	local bytes = {}

	for i = 1, #self do
		table.insert(bytes, self:readU8())
	end

	return bytes
end

local function writeU8(self: Buffer, value: number)
	buffer.writeu8(self.buffer, self.cursor, value)
	self.cursor += 1
end

local function writeI8(self: Buffer, value: number)
	buffer.writei8(self.buffer, self.cursor, value)
	self.cursor += 1
end

local function writeU16(self: Buffer, value: number)
	buffer.writeu16(self.buffer, self.cursor, value)
	self.cursor += 2
end

local function writeI16(self: Buffer, value: number)
	buffer.writei16(self.buffer, self.cursor, value)
	self.cursor += 2
end

local function writeU32(self: Buffer, value: number)
	buffer.writeu32(self.buffer, self.cursor, value)
	self.cursor += 4
end

local function writeI32(self: Buffer, value: number)
	buffer.writei32(self.buffer, self.cursor, value)
	self.cursor += 4
end

local function writeF32(self: Buffer, value: number)
	buffer.writef32(self.buffer, self.cursor, value)
	self.cursor += 4
end

local function writeF64(self: Buffer, value: number)
	buffer.writef64(self.buffer, self.cursor, value)
	self.cursor += 8
end

local function writeString(self: Buffer, value: string)
	buffer.writestring(self.buffer, self.cursor, value)
	self.cursor += #value
end

local function fill(self: Buffer, value: number, count: number?)
	buffer.fill(self.buffer, self.cursor, value, count)
	self.cursor += count or (#self - self.cursor)
end

local function copy(self: Buffer, count: number)
	local targetBuffer = buffer.create(count)
	buffer.copy(targetBuffer, 0, self.buffer, self.cursor, count)
	self.cursor += count

	return targetBuffer
end

local function resize(self: Buffer, size: number)
	local newBuffer = buffer.create(size)
	buffer.copy(newBuffer, 0, self.buffer, 0, size)
	self.cursor = 0
	self.buffer = newBuffer
end

local function clear(self: Buffer)
	self.cursor = 0
	buffer.fill(self.buffer, 0, 0)
end

local function createBuffer(buffer: buffer)
	return setmetatable({
		cursor = 0,
		buffer = buffer,
		readU8 = readU8,
		readI8 = readI8,
		readU16 = readU16,
		readI16 = readI16,
		readU32 = readU32,
		readI32 = readI32,
		readF32 = readF32,
		readF64 = readF64,
		readString = readString,
		readAllBytes = readAllBytes,
		writeU8 = writeU8,
		writeI8 = writeI8,
		writeU16 = writeU16,
		writeI16 = writeI16,
		writeU32 = writeU32,
		writeI32 = writeI32,
		writeF32 = writeF32,
		writeF64 = writeF64,
		writeString = writeString,
		fill = fill,
		copy = copy,
		resize = resize,
		clear = clear,
	}, Buffer)
end

function Buffer.__len(self: Buffer)
	return buffer.len(self.buffer)
end

function Buffer.__tostring(self: Buffer)
	return buffer.tostring(self.buffer)
end

function Buffer.create(size: number)
	return createBuffer(buffer.create(size))
end

function Buffer.fromString(str: string)
	return createBuffer(buffer.fromstring(str))
end

function Buffer.fromBuffer(buffer: buffer)
	return createBuffer(buffer)
end

export type Buffer = typeof(createBuffer(...))

return Buffer
