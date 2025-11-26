local WeaponEntity = {};
WeaponEntity.__index = WeaponEntity;

local substeps = 5;

function WeaponEntity.new(x, y, radius)
    local instance = setmetatable({}, WeaponEntity);

    instance.x = x;
    instance.y = y;

    instance.xv = 0;
    instance.yv = 0;

    instance.radius = radius;

    instance.paddleCallback = nil;
    instance.wallCallback = nil;
    instance.brickCallback = nil;

    instance.paddleOverlap = false;
    instance.wallOverlap = false;
    instance.brickOverlap = {};

    return instance;
end

function WeaponEntity:setPaddleCallback(callback)
    self.paddleCallback = callback;
end
function WeaponEntity:setWallCallback(callback)
    self.wallCallback = callback;
end
function WeaponEntity:setBrickCallback(callback)
    self.brickCallback = callback;
end

function WeaponEntity:setVelocity(xv, yv)
    self.xv = xv;
    self.yv = yv;
end

function WeaponEntity:setPosition(x, y)
    self.x = x;
    self.y = y;
end

function WeaponEntity:setSpeed(speed)
    local curSpeed = self:getSpeed();

    if curSpeed == 0 then
        self.xv = 0;
        self.yv = speed;
    end

    local mul = speed / curSpeed;

    self.xv = self.xv * mul;
    self.yv = self.yv * mul;
end

function WeaponEntity:getSpeed()
    return math.sqrt(self.xv * self.xv + self.yv * self.yv);
end

function WeaponEntity:collidePaddle()
    local playerPaddle = _G.paddle;

    local closestX = math.min(math.max(playerPaddle.x, self.x), playerPaddle.x + playerPaddle.width);
    local closestY = math.min(math.max(playerPaddle.y - 10, self.y), playerPaddle.y + 10);

    local dx = self.x - closestX;
    local dy = self.y - closestY;

    if dx * dx + dy * dy < self.radius * self.radius then
        if self.paddleOverlap then
            return;
        end

        self.paddleOverlap = true;

        if self.paddleCallback then
            if self.paddleCallback() then
                return;
            end
        end

        if self.yv > 0 then -- if collided w/ the top of the paddle
            self.y = playerPaddle.y - 10 - self.radius;
            self.yv = math.abs(self.yv);
        else
            self.y = playerPaddle.y + 10 + self.radius;
            self.yv = -math.abs(self.yv);
        end

        -- fuck this, frenchy is evil

        local hitPosition = (self.x - (playerPaddle.x - self.radius)) / (playerPaddle.width + self.radius * 2)
        -- Calculate total speed by adding all bonuses first
        local ballSpeed = self:getSpeed();
        self.xv = (hitPosition - 0.5) * 2 * ballSpeed;
        local speedYSquared = math.max(0, ballSpeed * ballSpeed - self.xv * self.xv);
        self.speedY = math.sqrt(speedYSquared) * (self.yv > 0 and 1 or -1);

        return;
    end

    self.paddleOverlap = false;
end

function WeaponEntity:substep(dt)
    self.x = self.x + self.xv * dt;
    self.y = self.y + self.yv * dt;

    -- check collision

    -- paddle collision
    self:collidePaddle();
end

function WeaponEntity:update(dt)
    for i = 1, substeps do
        self:substep(dt / substeps);
    end
end

return WeaponEntity;