-- Arcane Missile Particle System
-- Creates a blueish magical trail for arcane missiles

local ArcaneMissile = {}
local particles = {}

-- Settings for the trail
local TRAIL_COLOR = {0.3, 0.6, 1, 0.7} -- blueish
local PARTICLE_LIFETIME = 0.35
local PARTICLE_SIZE = 5

function ArcaneMissile.emit(x, y)
    table.insert(particles, {
        x = x,
        y = y,
        lifetime = PARTICLE_LIFETIME,
        age = 0,
        size = PARTICLE_SIZE * (0.7 + math.random() * 0.6),
        color = {TRAIL_COLOR[1], TRAIL_COLOR[2], TRAIL_COLOR[3], TRAIL_COLOR[4] * (0.7 + math.random() * 0.3)}
    })
end

function ArcaneMissile.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.age = p.age + dt
        if p.age >= p.lifetime then
            table.remove(particles, i)
        end
    end
end

function ArcaneMissile.draw()
    for _, p in ipairs(particles) do
        local t = 1 - (p.age / p.lifetime)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.color[4] * t)
        love.graphics.circle("fill", p.x, p.y, p.size * t)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ArcaneMissile
