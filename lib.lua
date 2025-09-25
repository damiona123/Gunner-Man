


function lerp(A, B, t)
	return A + (B - A) * t
end

function randomFloat(min, max, precision)
    local scale = 10 ^ precision
    return math.floor((min + math.random() * (max - min)) * scale + 0.5) / scale
end

function clamp(value, min, max)
    if value > max then
        return max
    elseif value < min then
        return min
    else
        return value
    end
end

function sine(input, amplitude, frequency, phase)
	-- input: could be time, x, or y (whatever you're basing motion on)
	-- amplitude: how "tall" the wave is (max distance from the center)
	-- frequency: how "fast" the wave cycles (higher = more waves in same space/time)
	-- phase: horizontal offset of the wave (useful for multiple enemies offset)

	-- Convert input to radians for math.sin (expects radians, not degrees)
	-- 2 * π * frequency turns a cycle into a full wave based on frequency
	amplitude = randomFloat(amplitude, amplitude)
	frequency = frequency
	local angle = 2 * math.pi * frequency * input + (phase or 0)

	-- Calculate the sine of the angle and multiply by amplitude to scale it
	return math.sin(angle) * amplitude
end

