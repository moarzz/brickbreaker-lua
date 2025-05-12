VFX = {}
local function brickHitFX(brick, ball, intensity)
    brick.color = brick.health > 12 and {1, 1, 1, 1} or brickColorsByHealth[brick.health]
    local colorBeforeHit = brick.color or {1, 1, 1, 1} -- Default to white if no color is set
    brick.color = {1,1,1,1}
    local colorTweenBack = tween.new(0.5, brick, {color = colorBeforeHit}, tween.outSine)
    addTweenToUpdate(colorTweenBack)

    local offsetX, offsetY = normalizeVector(ball.speedX, ball.speedY)
    local offsetRotation = math.atan2(offsetY, offsetX) * 0.1
    offsetX = offsetX * mapRange(intensity, 1, 10, 5, 30)
    offsetY = offsetY * mapRange(intensity, 1, 10, 5, 30)
    local scaleOffset = mapRange(intensity, 1, 10, 1.2, 2)
    local hitTween = tween.new(0.05, brick, {drawScale = scaleOffset, drawOffsetX = offsetX, drawOffsetY = offsetY, drawOffsetRot = 0}, tween.outCubic)
    addTweenToUpdate(hitTween)

    Timer.after(0.05, function() 
        local hitTweenBack = tween.new(0.2, brick, {drawScale = 1, drawOffsetX = 0, drawOffsetY = 0, drawOffsetRot = 0}, tween.inOutSine)
        addTweenToUpdate(hitTweenBack)
    end)
end

function VFX.bricksHitFX(brick, ball, damage)
    -- makes the brick knockback
    brickHitFX(brick, ball, damage)

    -- Propagates the effect to nearby bricks on a smaller scale based on distance
    local closeBricks = getBricksTouchingCircle(brick.x, brick.y, brick.width*mapRangeClamped(damage))
    for _, closeBrick in ipairs(closeBricks) do
        
    end
end



return VFX