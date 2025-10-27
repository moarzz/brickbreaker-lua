local W95_CursorIndicator = {}

W95_CursorIndicator.__index = W95_CursorIndicator

Textures.getTexture('crooky/mouse/hand', true)

function W95_CursorIndicator.newCursorIndicator(pointAtX, pointAtY, pointDir, timerOffset, pointType)
    local instance = setmetatable({}, W95_CursorIndicator)

    instance.x = pointAtX
    instance.y = pointAtY

    instance.pointDir = pointDir

    instance.time = timerOffset or 0

    instance.pointType = pointType or 'normal'

    return instance
end
function W95_CursorIndicator.newConnectedCursorIndicator(connectedObject, offsetX, offsetY, pointDir, timerOffset, pointType)
    local instance = setmetatable({}, W95_CursorIndicator)

    instance.connectedObject = true
    instance.obj = connectedObject

    instance.x = 0
    instance.y = 0

    instance.offsetX = offsetX
    instance.offsetY = offsetY

    instance.pointDir = pointDir

    instance.time = timerOffset or 0

    instance.pointType = pointType or 'normal'

    return instance
end

local normalEase = function(x)
    return math.cos(x * math.pi * 2) / 2 + 0.5
end
local doubleClickEase = function(x)
    if x < 0.4 then
        return 1 - (2.5 * x) ^ 2
    elseif x > 0.6 then
        return 1 - (2.5 * x - 2.5) ^ 2
    else
        return 0.25 - (5 * x - 2.5) ^ 2
    end
end
local fasterEase = function(x)
    if x < 0.25 then
        return 1 - (8 * x - 1) ^ 2
    elseif x < 0.5 then
        return 1 - (8 * x - 3) ^ 2
    elseif x < 0.75 then
        return 1 - (8 * x - 5) ^ 2
    else
        return 1 - (8 * x - 7) ^ 2
    end
end

local pointSwitch = {
    ['normal'] = normalEase,
    ['double'] = doubleClickEase,
    ['faster'] = fasterEase
}

function W95_CursorIndicator:getPosition()
    return self.x, self.y
end
function W95_CursorIndicator:setPosition(x, y)
    self.x = x
    self.y = y
end
function W95_CursorIndicator:setTime(time)
    self.time = time
end
function W95_CursorIndicator:setPointDir(dir)
    self.pointDir = dir
end
function W95_CursorIndicator:setPointType(pointType)
    self.pointType = pointType or 'normal'
end

function W95_CursorIndicator:update(dt)
    if self.connectedObject then
        if self.obj then
            local offsetX = self.offsetX
            local offsetY = self.offsetY

            if not offsetX then
                if self.obj.w then
                    offsetX = self.obj.w / 2
                else
                    offsetX = 0
                end
            end

            if not offsetY then
                if self.obj.h then
                    offsetY = self.obj.h / 2
                else
                    offsetY = 0
                end
            end

            if self.obj.getPosition then
                local nx, ny = self.obj:getPosition()

                self.x = nx + offsetX
                self.y = ny + offsetY
            elseif self.obj.x and self.obj.y then
                self.x = self.obj.x + offsetX
                self.y = self.obj.y + offsetY
            end
        end
    end

    self.time = (self.time + dt) % 1
end

function W95_CursorIndicator:draw()
    if self.pointDir == 'right' then
        love.graphics.draw(Textures.getTexture('mouse/hand'), self.x - 10 - pointSwitch[self.pointType](self.time) * 20, self.y, math.pi / 2, 4, 4, 6, 0)
    elseif self.pointDir == 'left' then
        love.graphics.draw(Textures.getTexture('mouse/hand'), self.x + 10 + pointSwitch[self.pointType](self.time) * 20, self.y, -math.pi / 2, 4, 4, 6, 0)
    elseif self.pointDir == 'up' then
        love.graphics.draw(Textures.getTexture('mouse/hand'), self.x, self.y + 10 + pointSwitch[self.pointType](self.time) * 20, 0, 4, 4, 6, 0)
    elseif self.pointDir == 'down' then
        love.graphics.draw(Textures.getTexture('mouse/hand'), self.x, self.y - 10 - pointSwitch[self.pointType](self.time) * 20, math.pi, 4, 4, 6, 0)
    end

    love.graphics.circle('fill', self.x, self.y, 4) --? MARK: -for debug purposes
end

return W95_CursorIndicator