VFX = {}

-- brick hit functions
local function brickHitFX(brick, ball, intensity)
    brick.color = brick.health > 12 and {1, 1, 1, 1} or brickColorsByHealth[brick.health]
    local colorBeforeHit = brick.color or {1, 1, 1, 1} -- Default to white if no color is set
    brick.color = {1,1,1,1}
    local colorTweenBack = tween.new(0.5, brick, {color = colorBeforeHit}, tween.outSine)
    addTweenToUpdate(colorTweenBack)

    local offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
    local offsetRotation = math.atan2(offsetY, offsetX) * 0.1
    offsetX = offsetX * (mapRange(intensity, 1, 10, 5, 30) + 5)
    offsetY = offsetY * (mapRange(intensity, 1, 10, 5, 30) + 5)
    local scaleOffset = mapRange(intensity, 1, 10, 1.2, 2)
    local hitTween = tween.new(0.05, brick, {drawScale = scaleOffset, drawOffsetX = offsetX, drawOffsetY = offsetY, drawOffsetRot = 0}, tween.outCubic)
    addTweenToUpdate(hitTween)

    Timer.after(0.05, function() 
        local hitTweenBack = tween.new(0.2, brick, {drawScale = 1, drawOffsetX = 0, drawOffsetY = 0, drawOffsetRot = 0}, tween.inOutSine)
        addTweenToUpdate(hitTweenBack)
    end)
end
local brickParticles = {}
local function brickHitParticles(brick, ball, intensity) --maybe ca c'est brick detroyed particles tbh
    local particleamount = math.floor(intensity/3 + 2)
    local particleSpeed = {100,200}
    for i=1, particleamount do
        local direction = {}
        direction.x, direction.y = normalizeVector(ball.speedX, ball.speedY)
        local particle = {
            x = (brick.x + brick.width/2 + (ball.x or (brick.x + brick.width/2)))/2,
            y = (brick.y + brick.height/2 + (ball.y or (brick.y + brick.height/2)))/2,
            speed = randomFloat(200,400)*mapRangeClamped(intensity,1,10,1,3)
        }
        local speedX, speedY = rotateVector(direction.x*particle.speed, direction.y*particle.speed, randomFloat(-math.rad(45), math.rad(45)))
        particle.speedX = speedX
        particle.speedY = speedY
        particle.size = randomFloat(1, 3) * (intensity/5 + 1.25)
        particle.startingSize = particle.size
        particle.color = {0.8, 0.8, 0.8, 1}
        table.insert(brickParticles, particle)
    end
end
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
end
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
    updateBrickParticles(dt)
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
    drawBrickParticles()
    if shouldDrawDebug then 
        drawDebug()
    end
end


return VFX