VFX = {}

-- brick hit functions
function VFX.switch()
    dmgVFXOn = not dmgVFXOn
end

local bricksInHitstun = {}
function brickHitFX(brick, ball, intensity)
    if love.timer.getTime() - (brick.lastHitVfxTime or 0) < 0.15 then
        return
    end
    if not dmgVFXOn then
        return
    end
    if brick.lastHitVfxTime then
        brick.lastHitVfxTime = love.timer.getTime()
    end
    brick.color = getBrickColor(brick.health, brick.type == "big", brick.type == "boss")
    local colorBeforeHit = brick.color -- Default to white if no color is set
    brick.color = {1,1,1,1}
    --local colorTweenBack = tween.new(0.5, brick, {color = colorBeforeHit}, tween.outSine)
    --addTweenToUpdate(colorTweenBack)

    local offsetX, offsetY
    if ball then
        if ball.speedX and ball.speedY then
            offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
        else
            offsetX, offsetY = 0, -1
        end
        if ball.speedX and ball.speedY then
            offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
        else
            offsetX, offsetY = 0, -1 -- Default direction if ball speed is not defined
        end
    else
        offsetX, offsetY = 0, -1
    end
    local offsetRotation = math.atan2(offsetY, offsetX) * 0.1
    offsetX = offsetX * (mapRange(intensity, 1, 10, 10, 30) + 5)
    offsetY = offsetY * (mapRange(intensity, 1, 10, 10, 30) + 5)
    local scaleOffset = mapRangeClamped(intensity, 1, 15, 1.1, 1.75)
    brick.drawScale, brick.drawOffsetX, brick.drawOffsetY, brick.drawOffsetRot = scaleOffset, offsetX, offsetY, 0
    table.insert(bricksInHitstun, brick)
end

function VFX.brickHit(brick, ball, damage)
    if brick.health >= 1 and damage > 0 then
        -- makes the brick knockback
        brickHitFX(brick, ball, damage)
    end
end

-- update
function VFX.update(dt)
    for i = #bricksInHitstun, 1, -1 do
        local dtIntensity = dt
        local brick = bricksInHitstun[i]
        if brick.drawScale and brick.drawScale > 1 then
            dtIntensity = dt * mapRange(brick.drawScale, 1, 2, 0.25, 2.5)
            brick.drawScale = math.max(brick.drawScale - dt, 1)
        end
        if brick.drawOffsetX ~= 0 then
            dtIntensity = dt * mapRange(math.abs(brick.drawOffsetX), 0, 25, 1, 15)
            if brick.drawOffsetX > 0 then
                brick.drawOffsetX = math.max(brick.drawOffsetX - dtIntensity * 5, 0)
            else
                brick.drawOffsetX = math.min(brick.drawOffsetX + dtIntensity * 5, 0)
            end
        end
        if brick.drawOffsetY ~= 0 then
            dtIntensity = dt * mapRange(math.abs(brick.drawOffsetY), 0, 25, 1, 20)
            if brick.drawOffsetY > 0 then
                brick.drawOffsetY = math.max(brick.drawOffsetY - dtIntensity * 5, 0)
            else
                brick.drawOffsetY = math.min(brick.drawOffsetY + dtIntensity * 5, 0)
            end
        end
        if brick.drawOffsetRot ~= 0 then
            dtIntensity = dt * mapRange(math.abs(brick.drawOffsetRot), 0, 25, 1, 20)
            if brick.drawOffsetRot > 0 then
                brick.drawOffsetRot = math.max(brick.drawOffsetRot - dtIntensity * 5, 0)
            else
                brick.drawOffsetRot = math.min(brick.drawOffsetRot + dtIntensity * 5, 0)
            end
        end
        if brick.drawScale == 1 and brick.drawOffsetX == 0 and brick.drawOffsetY == 0 and brick.drawOffsetRot == 0 then
            table.remove(bricksInHitstun, i)
        end
        if brick.color ~= getBrickColor(brick.health, brick.type == "big", brick.type == "boss") then
            local targetColor = getBrickColor(brick.health, brick.type == "big", brick.type == "boss")
            dtIntensity = dt * mapRange(brick.color[1] - targetColor[1], 0, 1, 1.25, 2.5)
            brick.color[1] = math.max(brick.color[1] - dtIntensity, targetColor[1])
            dtIntensity = dt * mapRange(brick.color[2] - targetColor[2], 0, 1, 1.25, 2.5)
            brick.color[2] = math.max(brick.color[2] - dtIntensity, targetColor[2])
            dtIntensity = dt * mapRange(brick.color[3] - targetColor[3], 0, 1, 1.25, 2.5)
            brick.color[3] = math.max(brick.color[3] - dtIntensity, targetColor[3])
        end
    end
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