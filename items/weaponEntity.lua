local WeaponEntity = {};
WeaponEntity.__index = WeaponEntity;

local substeps = 5;

function WeaponEntity.new(x, y, radius)
    local instance = setmetatable({}, WeaponEntity);

    instance.x = x;
    instance.y = y;

    instance.xn = 0;
    instance.yn = 1;

    instance.speed = 0;
    instance.extraSpeed = 0;

    instance.radius = radius;

    instance.paddleCallback = nil;
    instance.wallCallback = nil;
    instance.brickCallback = nil;

    instance.paddleOverlap = false;
    instance.wallOverlap = false;
    instance.brickOverlap = {};

    return instance;
end

function WeaponEntity:setDirection(x, y)
    if not y then
        y = math.sin(x);
        x = math.cos(x);
    end

    local dist = math.sqrt(x * x + y * y);

    self.xn = x / dist;
    self.yn = y / dist;
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

function WeaponEntity:setPosition(x, y)
    self.x = x;
    self.y = y;
end

function WeaponEntity:setSpeed(speed)
    self.speed = speed;
end
function WeaponEntity:setExtraSpeed(speed)
    self.extraSpeed = speed;
end
function WeaponEntity:addExtraSpeed(speed)
    self.extraSpeed = self.extraSpeed + speed;
end

function WeaponEntity:getSpeed()
    return self.speed + self.extraSpeed;
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

        if self.yn > 0 then -- if collided w/ the top of the paddle
            self.y = playerPaddle.y - 10 - self.radius;
            self.yn = math.abs(self.yn);
        else
            self.y = playerPaddle.y + 10 + self.radius;
            self.yn = -math.abs(self.yn);
        end

        local hitPerun = (self.x - playerPaddle.x) / (playerPaddle.width + self.radius) * 2 - 1;

        local newDir = hitPerun * math.pi / 2 * 0.95;

        if self.yn < 0 then
            newDir = newDir + math.pi;
        end

        self:setDirection(newDir);
        self:addExtraSpeed(5);

        return;
    end

    self.paddleOverlap = false;
end

function WeaponEntity:collideBricks()
    local checkBricks = _G.bricks;

    for _, brick in ipairs(checkBricks) do
        self:collideBrick(brick);
    end
end

function WeaponEntity:collideBrick(brick)
    local closestX = math.min(math.max(brick.x, self.x), brick.x + brick.width);
    local closestY = math.min(math.max(brick.y, self.y), brick.y + brick.height);

    local dx = self.x - closestX;
    local dy = self.y - closestY;

    if dx * dx + dy * dy < self.radius * self.radius then
        if self.brickOverlap[brick.id] then
            return;
        end

        self.brickOverlap[brick.id] = true;

        if self.brickCallback then
            if self.brickCallback(brick) then
                return;
            end
        end

        local distLeft  = self.x + self.radius - brick.x;
        local distRight = brick.x + brick.width - self.x + self.radius;
        local distTop   = self.y + self.radius - brick.y;
        local distBot   = brick.y + brick.height - self.y + self.radius;

        local horizontalDist;
        local verticalDist;

        if self.xn > 0 then
            horizontalDist = distLeft * self.xn;
        else
            horizontalDist = distRight * -self.xn;
        end

        if self.yn > 0 then
            verticalDist = distTop * self.yn;
        else
            verticalDist = distBot * -self.yn;
        end

        if verticalDist > horizontalDist then
            if self.xn > 0 then
                self.x = self.x - distLeft;
            else
                self.x = self.x + distRight;
            end

            self.xn = -self.xn;
        else
            if self.yn > 0 then
                self.y = self.y - distTop;
            else
                self.y = self.y + distBot;
            end

            self.yn = -self.yn;
        end

        return;
    end

    self.brickOverlap[brick.id] = nil;
end

function WeaponEntity:collideWalls()
    if self.x < self.radius then
        self.x = self.radius;
        self.xn = math.abs(self.xn);
    end

    if self.x > screenWidth - self.radius then
        self.x = screenWidth - self.radius;
        self.xn = -math.abs(self.xn);
    end

    if self.y < self.radius then
        self.y = self.radius;
        self.yn = math.abs(self.yn);
    end

    if self.y > math.max(screenHeight, paddle.y + 150) - self.radius then
        self.y = math.max(screenHeight, paddle.y + 150) - self.radius;
        self.yn = -math.abs(self.yn);
    end
end

function WeaponEntity:substep(dt)
    self.x = self.x + self.xn * (self.speed + self.extraSpeed) * dt;
    self.y = self.y + self.yn * (self.speed + self.extraSpeed) * dt;

    -- check collision

    -- paddle collision
    self:collidePaddle();

    -- brick collision
    self:collideBricks();
end

function WeaponEntity:update(dt)
    for i = 1, substeps do
        self:substep(dt / substeps);
    end
end

return WeaponEntity;