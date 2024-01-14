local Buffer = require(script.Parent.Buffer)

local Chunk = {}

local function parse<T, K>(self: Chunk, state: K, chunk: Buffer.Buffer, crc: number): T
	return self.callback(state, chunk, crc)
end

function Chunk.new<T, K>(name: string, callback: (state: K, chunk: Buffer.Buffer, crc: number) -> T)
	return {
		name = name,
		callback = callback,
		parse = parse,
	}
end

export type Chunk = typeof(Chunk.new(...))

return Chunk
