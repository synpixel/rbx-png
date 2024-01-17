local Buffer = require(script.Parent.Buffer)
local Chunk = require(script.Parent.Chunk)
local switchEndianness = require(script.Parent.switchEndianness)

export type ChunkResult = {
	size: Vector2,
	bitDepth: number,
	colorType: number,
	compressionMethod: number,
	filterMethod: number,
	interlaceMethod: number,
	palette: { [number]: Color3 },
	hash: number,
	zlibStream: string,
	backgroundColor: Color3,
	chromaticity: { [string]: { number } },
	gamma: number,
	renderIntent: number,
	metadata: { [string]: any },
	timestamp: DateTime,
	alpha: { [number]: number },
}

local chunks = {
	Chunk.new("IHDR", function(_state: ChunkResult, chunk)
		return {
			size = Vector2.new(switchEndianness(chunk:readU32()), switchEndianness(chunk:readU32())),
			bitDepth = chunk:readU8(),
			colorType = chunk:readU8(),
			compressionMethod = chunk:readU8(),
			filterMethod = chunk:readU8(),
			interlaceMethod = chunk:readU8(),
		}
	end),

	Chunk.new("PLTE", function(_state: ChunkResult, chunk)
		local palette = {}

		local colors = chunk:readAllBytes()

		if #chunk % 3 ~= 0 then
			error("Invalid PLTE chunk.")
		end

		for i = 1, #chunk, 3 do
			local r = colors[i]
			local g = colors[i + 1]
			local b = colors[i + 3]

			local color = Color3.fromRGB(r, g, b)
			table.insert(palette, color)
		end

		return { palette = palette }
	end),

	Chunk.new("IDAT", function(state: ChunkResult, chunk, crc)
		local hash = state.hash or 0
		return {
			hash = bit32.bxor(switchEndianness(hash), crc),
			zlibStream = (state.zlibStream or "") .. tostring(chunk),
		}
	end),

	Chunk.new("bKGD", function(state: ChunkResult, chunk)
		local bitDepth = (2 ^ state.bitDepth) - 1

		if state.colorType == 3 then
			local index = chunk:readU8()
			return { backgroundColor = state.palette[index] }
		elseif state.colorType == 0 or state.colorType == 4 then
			local gray = chunk:readU16() / bitDepth
			return { backgroundColor = Color3.fromHSV(0, 0, gray) }
		elseif state.colorType == 2 or state.colorType == 6 then
			local r = chunk:readU16() / bitDepth
			local g = chunk:readU16() / bitDepth
			local b = chunk:readU16() / bitDepth
			return { backgroundColor = Color3.new(r, g, b) }
		end

		return {}
	end),

	Chunk.new("cHRM", function(_state: ChunkResult, chunk)
		local colors = { "White", "Red", "Green", "Blue" }
		local chrome = {}

		for _, color in colors do
			chrome[color] = {
				chunk:readU32() / 10e4,
				chunk:readU32() / 10e4,
			}
		end

		return { chromaticity = chrome }
	end),

	Chunk.new("gAMA", function(_state: ChunkResult, chunk)
		return { gamma = switchEndianness(chunk:readU32()) / 10e4 }
	end),

	Chunk.new("sRGB", function(_state: ChunkResult, chunk)
		return { renderIntent = chunk:readU8() }
	end),

	Chunk.new("tEXt", function(state: ChunkResult, chunk)
		local metadata = table.clone(state.metadata or {})

		local key, value = "", ""

		for byte in chunk:readAllBytes() do
			local char = string.char(byte)

			if char == "\0" then
				key = value
				value = ""
			else
				value = value .. char
			end
		end

		metadata[key] = value

		return { metadata = metadata }
	end),

	Chunk.new("tIME", function(_state: ChunkResult, chunk)
		return {
			timestamp = DateTime.fromUniversalTime(
				chunk:readU16(),
				chunk:readU8(),
				chunk:readU8(),
				chunk:readU8(),
				chunk:readU8(),
				chunk:readU8()
			),
		}
	end),

	Chunk.new("tRNS", function(state: ChunkResult, chunk)
		local bitDepth = (2 ^ state.bitDepth) - 1

		if state.colorType == 3 then
			local palette = state.palette
			local alphaMap = {}

			for i = 1, #palette do
				local alpha = chunk:readU8() or 255
				alphaMap[i] = alpha
			end

			return { alpha = alphaMap }
		elseif state.colorType == 0 then
			local grayAlpha = chunk:readU16()
			return { alpha = grayAlpha / bitDepth }
		elseif state.colorType == 2 then
			local r = chunk:readU16() / bitDepth
			local g = chunk:readU16() / bitDepth
			local b = chunk:readU16() / bitDepth

			return { alpha = Color3.new(r, g, b) }
		end

		error("Invalid tRNS chunk.")
	end),
}

local function findChunk(name: string)
	for _, chunk in chunks do
		if chunk.name == name then
			return chunk
		end
	end

	return
end

local function parseChunks(buffer: Buffer.Buffer): ChunkResult
	local result = {}

	while true do
		local length = switchEndianness(buffer:readU32())
		local chunkName = buffer:readString(4)

		if chunkName == "IEND" then
			break
		end

		local data, crc

		if length > 0 then
			data = Buffer.fromBuffer(buffer:copy(length))
			crc = buffer:readU32()
		end

		local chunk = findChunk(chunkName)

		if chunk then
			local output = chunk:parse(table.freeze(table.clone(result)), data, crc)

			for key, value in output do
				result[key] = value
			end
		end
	end

	return result :: ChunkResult
end

return parseChunks
