local confetti = {}
confetti.__index = confetti

-- Colors for the confetti pieces
local confettiColors = {
    {1, 0, 0},    -- Bright Red
    {0, 1, 0},    -- Bright Green
    {0, 0, 1},    -- Bright Blue
    {1, 1, 0},    -- Yellow
    {1, 0, 1},    -- Magenta
    {0, 1, 1},    -- Cyan
    {1, 0.5, 0},  -- Orange
    {0.5, 0, 1},  -- Purple
    {1, 0.8, 0.8},-- Pink
    {0.8, 1, 0}   -- Lime
}

function confetti.new()
    local self = setmetatable({
        particles = {},  -- Initialize particles table
        emitterLeft = {
            x = 100,  -- Left side of screen
            y = love.graphics.getHeight() - 50  -- Near bottom
        },
        emitterRight = {
            x = love.graphics.getWidth() - 100,  -- Right side of screen
            y = love.graphics.getHeight() - 50   -- Near bottom
        },
        creationTime = love.timer.getTime()  -- Track the creation time of the confetti system
    }, confetti)
    
    -- Spawn initial burst of confetti
    self:spawnBurst(50)  -- 50 particles per side
    
    return self
end

function confetti:spawnBurst(amount)
    -- Spawn from left emitter
    for i = 1, amount do
        local particle = self:createParticle(self.emitterLeft.x, self.emitterLeft.y)
        table.insert(self.particles, particle)
    end
    
    -- Spawn from right emitter
    for i = 1, amount do
        local particle = self:createParticle(self.emitterRight.x, self.emitterRight.y)
        table.insert(self.particles, particle)
    end
end

function confetti:createParticle(x, y)
    local particle = {
        x = x,
        y = y,
        -- Random initial velocity
        vx = love.math.random(-50, 50),  -- Reduced horizontal velocity for slower fall
        vy = love.math.random(-1000, -500),  -- Reduced upward velocity for slower fall
        rotation = love.math.random() * math.pi * 2,
        rotationSpeed = love.math.random(-5, 5),
        color = confettiColors[love.math.random(#confettiColors)],
        size = love.math.random(4, 8),
        lifetime = love.math.random(3, 5),  -- Random lifetime between 3-5 seconds
        age = 0
    }

    -- Adjust velocity based on spawn position (left or right side)
    if x < love.graphics.getWidth() / 2 then
        particle.vx = love.math.random(100, 500)  -- Move right if spawned on left
    else
        particle.vx = love.math.random(-500, -100)  -- Move left if spawned on right
    end

    return particle
end

function confetti:update(dt)
    if not self.particles then
        self.particles = {}
    end

    -- Ensure emitters are initialized
    if not self.emitterLeft then
        self.emitterLeft = {
            x = 100,
            y = love.graphics.getHeight() - 50
        }
    end

    if not self.emitterRight then
        self.emitterRight = {
            x = love.graphics.getWidth() - 100,
            y = love.graphics.getHeight() - 50
        }
    end

    -- Ensure creationTime is initialized
    if not self.creationTime then
        self.creationTime = love.timer.getTime()
    end

    -- Stop emitting new particles after 1.5 seconds
    if love.timer.getTime() - self.creationTime > 1.5 then
        self.emitterLeft = nil
        self.emitterRight = nil
    end

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]

        -- Update position
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        -- Apply gravity
        p.vy = p.vy + 400 * dt  -- Gravity

        -- Add some horizontal wobble
        p.vx = p.vx + math.sin(love.timer.getTime() * 2 + p.x) * 50 * dt

        -- Update rotation
        p.rotation = p.rotation + p.rotationSpeed * dt

        -- Update age
        p.age = p.age + dt

        -- Remove if too old or off screen
        if p.age >= p.lifetime or p.y > love.graphics.getHeight() + 50 then
            table.remove(self.particles, i)
        end
    end

    -- Spawn new particles occasionally for continuous effect
    if self.emitterLeft and self.emitterRight and #self.particles < 50 and love.math.random() < 0.75 then
        if love.math.random() < 0.75 then
            table.insert(self.particles, self:createParticle(self.emitterLeft.x, self.emitterLeft.y))
        else
            table.insert(self.particles, self:createParticle(self.emitterRight.x, self.emitterRight.y))
        end
    end
end

function confetti:draw()
    if not self.particles then
        self.particles = {}
        return
    end

    for _, p in ipairs(self.particles) do
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rotation)

        -- Keep full opacity
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], 1)

        -- Draw as small rectangle
        love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size)

        love.graphics.pop()
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

return confetti
