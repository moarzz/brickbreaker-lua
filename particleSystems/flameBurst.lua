-- particleSystems/flameBurst.lua
-- Particle system for the Flame Burst spell (expanding fiery pulse)

local FlameBurst = {}
local bursts = {}

function FlameBurst.emit(x, y, damage, range)
    table.insert(bursts, {
        x = x,
        y = y,
        radius = 0,
        maxRadius = range or 250,
        alpha = 1,
        time = 0,
        duration = 0.5,
        damage = damage or 2,
        hitBricks = {}
    })
end

function FlameBurst.update(dt)
    for i = #bursts, 1, -1 do
        local b = bursts[i]
        b.time = b.time + dt
        b.radius = b.maxRadius * (b.time / b.duration)
        b.alpha = 1 - (b.time / b.duration)
        if b.time >= b.duration then
            table.remove(bursts, i)
        end
    end
end

function FlameBurst.getBursts()
    return bursts
end

function FlameBurst.draw()
    for _, b in ipairs(bursts) do
        for i = 1, 3 do
            local r = b.radius * (0.7 + 0.15 * i)
            local a = b.alpha * (0.3 + 0.2 * i)
            love.graphics.setColor(1, 0.5, 0, a)
            love.graphics.circle("fill", b.x, b.y, r)
        end
        love.graphics.setColor(1, 0.8, 0.2, b.alpha * 0.7)
        love.graphics.circle("line", b.x, b.y, b.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return FlameBurst
