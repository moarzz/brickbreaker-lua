VFX = {}

-- brick hit functions
local function brickHitFX(brick, ball, intensity)
    brick.color = getBrickColor(brick.health)
    local colorBeforeHit = brick.color -- Default to white if no color is set
    brick.color = {1,1,1,1}
    local colorTweenBack = tween.new(0.5, brick, {color = colorBeforeHit}, tween.outSine)
    addTweenToUpdate(colorTweenBack)

    if ball.speedX and ball.speedY then
        local offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
    else
        local offsetX, offsetY = 0, -1
    end
    if ball.speedX and ball.speedY then
        offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
    else
        offsetX, offsetY = 0, -1 -- Default direction if ball speed is not defined
    end
    local offsetRotation = math.atan2(offsetY, offsetX) * 0.1
    offsetX = offsetX * (mapRange(intensity, 1, 10, 5, 30) + 5)
    offsetY = offsetY * (mapRange(intensity, 1, 10, 5, 30) + 5)
    local scaleOffset = mapRange(intensity, 1, 10, 1, 3)
    local hitTween = tween.new(0.05, brick, {drawScale = scaleOffset, drawOffsetX = offsetX, drawOffsetY = offsetY, drawOffsetRot = 0}, tween.outCubic)
    addTweenToUpdate(hitTween)

    Timer.after(0.05, function() 
        local hitTweenBack = tween.new(0.2, brick, {drawScale = 1, drawOffsetX = 0, drawOffsetY = 0, drawOffsetRot = 0}, tween.inOutSine)
        addTweenToUpdate(hitTweenBack)
    end)
end

local function brickHitParticles(brick, ball, intensity)
    -- Default to brick center if ball position is unavailable
    local ballX = ball.x or brick.x + brick.width/2
    local ballY = ball.y or brick.y + brick.height/2
    
    -- Calculate effect position using safe values
    local effectX = (ballX + brick.x + brick.width/2)/2
    local effectY = (ballY + brick.y + brick.height/2)/2
    
    createSpriteAnimation(effectX, effectY, mapRangeClamped(intensity, 1, 20, 0.25, 0.65), impactVFX, 512, 512, 0.005, 4)
end

--[[
local function updateBrickParticles(dt)
    for i = #brickParticles, 1, -1 do
        local particle = brickParticles[i]
         -- particle movement
        particle.x = particle.x + particle.speedX * dt
        particle.y = particle.y + particle.speedY * dt

        --Particle wall collision
        if particle.x - particle.size <= statsWidth then
            particle.x = statsWidth + particle.size
            particle.speedX = -particle.speedX
        end
        if particle.x + particle.size >= screenWidth - statsWidth then
            particle.x = screenWidth - statsWidth - particle.size
            particle.speedX = -particle.speedX
        end
        particle.speedY = particle.speedY - dt * -980
        if particle.y > screenHeight + 50 then
            table.remove(brickParticles,i)
        end

        particle.size = math.max(particle.size - dt * 4,0)
        particle.color = {particle.size/particle.startingSize, particle.size/particle.startingSize, particle.size/particle.startingSize, particle.size/particle.startingSize}
    end
end
local function drawBrickParticles()
    for _, particle in ipairs(brickParticles) do
        love.graphics.setColor(particle.color)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end]]
function VFX.brickHit(brick, ball, damage)
    if brick.health >= 1 then
        -- makes the brick knockback
        brickHitFX(brick, ball, damage)
    end

    -- makes the brick particle effect
    brickHitParticles(brick, ball, damage)
end

-- update
function VFX.update(dt)
    --updateBrickParticles(dt)
end

-- draw
VFX.backgroundIntensityOverwrite = 0.0
local backgroundIntensitySlider = {value = 0.5, min = 0, max = 1}
local function drawDebug()
    suit.layout:reset(25,screenHeight - 150, 200, 30)
    setFont(14);
    local textSize = getTextSize("backgroundIntensity : ")
    local x,y,w,h = suit.layout:row(200,30)
    suit.Slider(backgroundIntensitySlider, suit.layout:row(200,30))
    suit.Label("background Intensity", {align = "center"}, suit.layout:up(200,20))
    VFX.backgroundIntensityOverwrite = backgroundIntensitySlider.value
end
shouldDrawDebug = false
function VFX.flipDrawDebug()
    shouldDrawDebug = not shouldDrawDebug
end
function VFX.draw()
    --drawBrickParticles()
    if shouldDrawDebug then 
        drawDebug()
    end
end


return VFX