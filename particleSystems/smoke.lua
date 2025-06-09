-- Smoke particle system module

local Smoke = {}

local particles = {}

-- Configuration for smoke particles
local config = {
    lifetime = 0.4,     -- How long each particle lives
    startSize = 4,      -- Base starting size of particles
    endSize = 1,        -- Base end size of particles
    speed = 100,        -- Base speed of particle movement
    spread = 0.3,       -- How much the particles spread
    startAlpha = 0.8,   -- Starting alpha value
    endAlpha = 0,       -- Ending alpha value
    color = {0.9, 0.9, 1}, -- Smoke color (light blue-white)
    -- Two-range scaling system
    lowDamageMax = 10,  -- Threshold between low and high damage scaling
    lowScaleMin = 0.5,  -- Scale at damage = 1
    lowScaleMax = 1.0,  -- Scale at damage = 10
    highScaleMax = 5.0  -- Scale at damage = 100
}

-- Create a new smoke particle
local function createParticle(x, y, directionX, directionY, damage)
    local angle = math.atan2(directionY, directionX) + (math.random() - 0.5) * config.spread
    local speed = config.speed * (0.8 + math.random() * 0.4)
    
    -- Calculate scale based on damage with two ranges
    local scale
    if damage <= config.lowDamageMax then
        -- Scale from 0.5 to 1.0 for damage 1-10
        scale = config.lowScaleMin + (config.lowScaleMax - config.lowScaleMin) * ((damage - 1) / (config.lowDamageMax - 1))
    else
        -- Scale from 1.0 to 5.0 for damage 10-100
        scale = config.lowScaleMax + (config.highScaleMax - config.lowScaleMax) * ((damage - config.lowDamageMax) / (100 - config.lowDamageMax))
    end
    scale = math.max(config.lowScaleMin, math.min(config.highScaleMax, scale))
    
    return {
        x = x,
        y = y,
        speedX = math.cos(angle) * speed,
        speedY = math.sin(angle) * speed,
        size = config.startSize * scale,
        endSize = config.endSize * scale,
        alpha = config.startAlpha,
        lifetime = 0,
        color = {config.color[1], config.color[2], config.color[3], config.startAlpha}
    }
end

-- Emit smoke particles
function Smoke.emit(x, y, directionX, directionY, amount, damage)
    amount = amount or 1
    damage = damage or 1
    for i = 1, amount do
        table.insert(particles, createParticle(x, y, directionX, directionY, damage))
    end
end

-- Update smoke particles
function Smoke.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.lifetime = p.lifetime + dt
        
        if p.lifetime >= config.lifetime then
            table.remove(particles, i)
        else
            local progress = p.lifetime / config.lifetime
            
            -- Update position
            p.x = p.x + p.speedX * dt
            p.y = p.y + p.speedY * dt
            
            -- Wall bounce at x = 450 and screenWidth - 450
            if p.x - p.size <= 450 then
                p.x = 450 + p.size
                p.speedX = -p.speedX * 0.8  -- Bounce with some energy loss
            elseif p.x + p.size >= screenWidth - 450 then
                p.x = screenWidth - 450 - p.size
                p.speedX = -p.speedX * 0.8  -- Bounce with some energy loss
            end
            
            -- Update size and alpha
            p.size = p.size + (p.endSize - p.size) * progress
            p.color[4] = config.startAlpha + (config.endAlpha - config.startAlpha) * progress
            p.speedY = p.speedY - dt * 50  -- Add slight upward drift
        end
    end
end

-- Draw smoke particles
function Smoke.draw()
    for _, p in ipairs(particles) do
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

return Smoke
