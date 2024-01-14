local Buffer = require(script.Buffer)
local parseChunks = require(script.parseChunks)

export type Pixel = {
	color: Color3,
	alpha: number,
}

local PNG = {}
PNG.Buffer = Buffer

local function readPixel(self: PNG, position: Vector2): Pixel
	return {
		color = Color3.fromRGB(255, 255, 255),
		alpha = 1,
	}
end

function PNG.new(buffer: Buffer.Buffer)
	local header = buffer:readString(8)

	if header ~= "\137PNG\r\n\26\n" then
		error("Input data is not a PNG file.")
	end

	local data = parseChunks(buffer)

	local success, response = pcall(function()
		local result = ""

		--TODO: inflate the zlib stream and stream it to result

		return result
	end)

	if not success then
		error(`Unable to unpack PNG data: "{response}"`)
	end

	print(response)

	return {
		data = data,
		readPixel = readPixel,
	}
end

export type PNG = typeof(PNG.new(...))

return PNG
