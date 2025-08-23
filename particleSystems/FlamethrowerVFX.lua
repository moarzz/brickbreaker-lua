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
    self.spawnRate = 4 -- particles per frame when active
    self.particleIdCounter = 0 -- For unique particle IDs
    self.time = 0 -- For turbulence calculations
    
    -- Flame properties
    self.baseSpeed = 550
    self.speedVariation = 80
    self.spread = math.pi / 6 -- 30 degrees spread
    self.range = 500
    self.gravity = 35
    
    -- Turbulence properties
    self.turbulenceStrength = 40
    self.turbulenceFrequency = 3
    
    -- Visual properties optimized for additive blending
    self.colors = {
        {1.0, 1.0, 0.8, 0.5}, -- Hot white core
        {1.0, 0.8, 0.2, 0.3}, -- Bright yellow
        {1.0, 0.4, 0.1, 0.2}, -- Orange
        {0.8, 0.2, 0.1, 0.1}, -- Red
        {0.3, 0.1, 0.1, 0.075}, -- Dark red/smoke
        {0.1, 0.1, 0.1, 0.05}  -- Smoke
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
    
    local maxLife = 1.2 + math.random() * 0.6
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
    local colorIndex = math.floor((1 - life) * (#self.colors - 1)) + 1 + (life > 0.95 and 0 or 1)
    colorIndex = math.min(colorIndex, #self.colors)
    
    local color = self.colors[colorIndex]
    local alpha = color[4] * life -- Fade out over time
    
    return color[1], color[2], color[3], alpha
end

function FlamethrowerVFX:render()
    -- Sort particles by life (render older particles first for better blending)
    table.sort(self.particles, function(a, b) return a.life < b.life end)
    
    for _, p in ipairs(self.particles) do
        local r, g, b, a = self:getParticleColor(p.life)
        
        -- Set color and alpha
        love.graphics.setColor(r, g, b, a)
        
        -- Draw particle as a rotated rectangle or circle
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rotation)
        
        -- Draw as stretched oval for flame-like appearance
        love.graphics.ellipse("fill", 0, 0, p.size, p.size * 1.5)
        
        love.graphics.pop()
    end
    
    -- Reset color
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