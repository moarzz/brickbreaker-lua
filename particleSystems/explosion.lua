local Smoke = require("particleSystems.smoke")

local Explosion = {}
local explosions = {}

-- Configuration for explosion particles
local config = {
    duration = 0.5,          -- How long the explosion lasts
    particleCount = 30,      -- Number of light particles per explosion
    startSize = 20,          -- Starting size of light particles
    endSize = 2,            -- End size of light particles
    speed = 300,            -- Base speed of particle movement
    startAlpha = 1.0,       -- Starting alpha value
    endAlpha = 0,           -- Ending alpha value
    color = {1, 0.7, 0.3},  -- Light particle color (orange)
    smokeCount = 15,        -- Number of smoke particles to emit
    radius = 25             -- Initial radius of the explosion
}

-- Create a new explosion
local function createExplosion(x, y, scale)
    scale = scale or 1
    local explosion = {
        x = x,
        y = y,
        particles = {},
        lifetime = 0,
        scale = scale
    }

    -- Create light particles with half scale for size
    for i = 1, config.particleCount do
        local angle = (math.pi * 2 / config.particleCount) * i + math.random() * 0.5
        local speed = config.speed * (0.8 + math.random() * 0.4) * scale  -- Full scale for spread/speed
        
        table.insert(explosion.particles, {
            x = x,
            y = y,
            speedX = math.cos(angle) * speed,
            speedY = math.sin(angle) * speed,
            size = config.startSize * (scale * 0.5),  -- Half scale for particle size
            endSize = config.endSize * (scale * 0.5),  -- Half scale for particle end size
            color = {config.color[1], config.color[2], config.color[3], config.startAlpha}
        })
    end

    -- Create smoke with full scale for radius but half scale for particle size
    for i = 1, config.smokeCount do
        local angle = (math.pi * 2 / config.smokeCount) * i + math.random() * 0.5
        local dirX = math.cos(angle)
        local dirY = math.sin(angle)
        Smoke.emit(x + dirX * config.radius * scale,  -- Full scale for radius
                  y + dirY * config.radius * scale,  -- Full scale for radius
                  dirX, dirY, 2, scale * 2.5)  -- Half scale for smoke size (5 -> 2.5)
    end

    return explosion
end

-- Create a new explosion at the specified position
function Explosion.spawn(x, y, scale)
    table.insert(explosions, createExplosion(x, y, scale))
end

-- Update all explosions
function Explosion.update(dt)
    for i = #explosions, 1, -1 do
        local explosion = explosions[i]
        explosion.lifetime = explosion.lifetime + dt

        if explosion.lifetime >= config.duration then
            table.remove(explosions, i)
        else
            local progress = explosion.lifetime / config.duration
            for _, particle in ipairs(explosion.particles) do
                -- Update particle position
                particle.x = particle.x + particle.speedX * dt
                particle.y = particle.y + particle.speedY * dt
                -- Update size and alpha
                particle.size = particle.size + (particle.endSize - particle.size) * progress
                particle.color[4] = config.startAlpha + (config.endAlpha - config.startAlpha) * progress
                -- Add some upward drift
                particle.speedY = particle.speedY - dt * 200
            end
        end
    end
end

-- Draw all explosions
function Explosion.draw()
    for _, explosion in ipairs(explosions) do
        for _, particle in ipairs(explosion.particles) do
            love.graphics.setColor(particle.color)
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Explosion
