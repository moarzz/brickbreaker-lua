-- Enhanced Flamethrower VFX System with Turbulence and Performance Optimizations

FlamethrowerVFX = {}
FlamethrowerVFX.__index = FlamethrowerVFX

function FlamethrowerVFX:new(x, y, direction)
    local self = setmetatable({}, FlamethrowerVFX)
    
    -- Position and direction
    self.x = x or 0
    self.y = y or 0
    self.direction = direction or 0
    self.active = false
    
    -- Particle system properties
    self.particles = {}
    self.maxParticles = 600 -- Increased from 150
    self.spawnRate = 3 -- particles per frame when active
    self.particleIdCounter = 0 -- For unique particle IDs
    self.time = 0 -- For turbulence calculations
    
    -- Flame properties
    self.baseSpeed = 550
    self.speedVariation = 80
    self.spread = math.pi / 5 -- 30 degrees spread
    self.range = 500
    self.gravity = 35
    
    -- Turbulence properties
    self.turbulenceStrength = 150
    self.turbulenceFrequency = 3
    
    -- Visual properties optimized for additive blending
    self.colors = {
        {1.0, 0.9, 0.7, 0.5}, -- Hot white core
        {1.0, 0.6, 0.15, 0.25}, -- Yellow-orange
        {1.0, 0.4, 0.1, 0.2}, -- Orange
        {0.9, 0.3, 0.1, 0.175}, -- Reddish orange
        {0.8, 0.2, 0.1, 0.15}, -- Red
        {0.55, 0.1, 0.1, 0.125}, -- Dark red
        {0.1, 0.1, 0.1, 0.025}  -- Smoke
    }
    
    -- Performance optimization: pre-calculate values
    self.airResistanceX = 0.5
    self.airResistanceY = 0.3
    self.sizeMultiplier = 0.5
    
    return self
end

function FlamethrowerVFX:createParticle()
    local angle = self.direction + (math.random() - 0.5) * self.spread
    local speed = self.baseSpeed + (math.random() - 0.5) * self.speedVariation
    
    self.particleIdCounter = self.particleIdCounter + 1
    
    local maxLife = (1.2 + math.random() * 0.6) * 0.7
    return {
        x = self.x,
        y = self.y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        life = 1.0,
        size = 8 + math.random() * 12,
        initialSize = 8 + math.random() * 12,
        rotation = math.random() * math.pi * 2,
        rotationSpeed = (math.random() - 0.5) * 4,
        -- Turbulence properties
        id = self.particleIdCounter,
        turbulenceOffset = math.random() * math.pi * 2,
        turbulenceStrength = self.turbulenceStrength * (0.5 + math.random() * 0.5),
        -- Pre-calculate some values for performance
        lifeDecay = 1.0 / maxLife
    }
end

function FlamethrowerVFX:update(dt)
    self.time = self.time + dt
    
    -- Spawn new particles if active
    if self.active then
        for i = 1, self.spawnRate do
            if #self.particles < self.maxParticles then
                table.insert(self.particles, self:createParticle())
            end
        end
    end
    
    -- Pre-calculate common values for performance
    local gravityDt = self.gravity * dt
    local airResX = 1 - dt * self.airResistanceX
    local airResY = 1 - dt * self.airResistanceY
    
    -- Update existing particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        
        -- Apply turbulence (side-to-side wobble)
        local turbulence = math.sin(self.time * self.turbulenceFrequency + p.turbulenceOffset) * p.turbulenceStrength * dt
        local perpAngle = self.direction + math.pi/2 -- Perpendicular to flame direction
        local turbulenceX = math.cos(perpAngle) * turbulence
        local turbulenceY = math.sin(perpAngle) * turbulence
        
        -- Update position with turbulence
        p.x = p.x + (p.vx + turbulenceX) * dt
        p.y = p.y + (p.vy + turbulenceY) * dt
        
        -- Apply gravity and air resistance
        p.vy = p.vy + gravityDt
        p.vx = p.vx * airResX
        p.vy = p.vy * airResY
        
        -- Update rotation
        p.rotation = p.rotation + p.rotationSpeed * dt
        
        -- Update life and size (using pre-calculated decay)
        p.life = p.life - p.lifeDecay * dt
        p.size = p.initialSize * (self.sizeMultiplier + p.life * self.sizeMultiplier)
        
        -- Remove dead particles
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function FlamethrowerVFX:getParticleColor(life)
        -- Lerp between all palette colors for a smooth gradient
        local palette = self.colors
        local t = 1 - life -- 0 = birth, 1 = death
        local idx = t * (#palette - 1) + 1
        local i1 = math.floor(idx)
        local i2 = math.min(i1 + 1, #palette)
        local frac = idx - i1
        local c1, c2 = palette[i1], palette[i2]
        local r = c1[1] * (1 - frac) + c2[1] * frac
        local g = c1[2] * (1 - frac) + c2[2] * frac
        local b = c1[3] * (1 - frac) + c2[3] * frac
        local a = (c1[4] * (1 - frac) + c2[4] * frac) * life
        return r, g, b, a
end

function FlamethrowerVFX:render()
        -- Draw a dark background rectangle so additive particles are visible
        love.graphics.setColor(0.08, 0.08, 0.08, 0.2)
        --love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setBlendMode("add", "premultiplied")
        -- Sort particles by life (render older particles first for better blending)
        table.sort(self.particles, function(a, b) return a.life < b.life end)

        local boost = 0.8 -- Adjust for desired opacity
        for _, p in ipairs(self.particles) do
            local r, g, b, a = self:getParticleColor(p.life)
            -- Premultiplied alpha and boost
            love.graphics.setColor(r * a * boost, g * a * boost, b * a * boost, a * boost)

            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(r, g, b, a)
            love.graphics.ellipse("fill", 0, 0, p.size, p.size * 1.5)
            love.graphics.setBlendMode("add", "premultiplied")
            love.graphics.setColor(r * a * boost, g * a * boost, b * a * boost, a * boost)
            love.graphics.ellipse("fill", 0, 0, p.size, p.size * 1.5)
            love.graphics.pop()
        end

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 1, 1, 1)
end

function FlamethrowerVFX:start()
    self.active = true
end

function FlamethrowerVFX:stop()
    self.active = false
end

function FlamethrowerVFX:setPosition(x, y)
    self.x = x
    self.y = y
end

function FlamethrowerVFX:setDirection(direction)
    self.direction = direction
end

function FlamethrowerVFX:clear()
    self.particles = {}
    self.particleIdCounter = 0
    self.time = 0
end

-- Performance: Add method to get particle count for debugging
function FlamethrowerVFX:getParticleCount()
    return #self.particles
end

-- Performance: Add method to adjust quality settings
function FlamethrowerVFX:setQuality(quality)
    if quality == "low" then
        self.maxParticles = 100
        self.spawnRate = 4
    elseif quality == "medium" then
        self.maxParticles = 200
        self.spawnRate = 6
    elseif quality == "high" then
        self.maxParticles = 300
        self.spawnRate = 8
    elseif quality == "ultra" then
        self.maxParticles = 500
        self.spawnRate = 12
    end
end

return FlamethrowerVFX