local Trail = {};
Trail.__index = Trail;

Trail.shader = love.graphics.newShader("trail", "Shaders/trail.frag");
-- Trail.circle = love.graphics.newImage("assets/sprites/circle.png");

function Trail.new(trailRadius, trailLen)
    local instance = setmetatable({}, Trail);

    -- Ring buffer arrays (fixed size, no allocations after init)
    instance.xBuffer = {}; -- ring buffer of x coordinates
    instance.yBuffer = {}; -- ring buffer of y coordinates
    for i = 1, trailLen do
        instance.xBuffer[i] = 0;
        instance.yBuffer[i] = 0;
    end

    instance.trailLen = trailLen; -- maximum capacity
    instance.count = 0; -- number of valid points currently in buffer
    instance.head = 1; -- write position (1-indexed for Lua)
    instance.trailRadius = trailRadius; -- radius of the trail

    instance.mesh = love.graphics.newMesh(instance.trailLen * 2 + 1, "strip");

    instance.minX = nil;
    instance.minY = nil;
    instance.maxX = nil;
    instance.maxY = nil;

    return instance;
end

function Trail:getTrailData()
    return self.trailRadius, self.trailLen;
end

function Trail:addPosition(x, y)
    -- Write to current head position
    self.xBuffer[self.head] = x;
    self.yBuffer[self.head] = y;

    -- Advance head with wrap-around
    self.head = self.head + 1;
    if self.head > self.trailLen then
        self.head = 1;
    end

    -- Increase count until we reach max capacity
    if self.count < self.trailLen then
        self.count = self.count + 1;
    end

    -- Update bounds
    self.minX = x;
    self.minY = y;
    self.maxX = x;
    self.maxY = y;

    for i = 1, self.count do
        self.minX = math.min(self.minX, self.xBuffer[i]);
        self.minY = math.min(self.minY, self.yBuffer[i]);
        self.maxX = math.max(self.maxX, self.xBuffer[i]);
        self.maxY = math.max(self.maxY, self.yBuffer[i]);
    end
end

function Trail:kickData()
    -- Decrement the count of valid points in the buffer
    if self.count > 0 then
        self.count = self.count - 1;
    end

    return self.count == 0;
end

function Trail:draw()
    if self.count <= 0 then
        return;
    end

    -- Create ordered arrays for shader (newest to oldest)
    local orderedX = {};
    local orderedY = {};

    -- Iterate backwards from the most recent point
    local pos = self.head - 1;
    if pos < 1 then
        pos = self.trailLen;
    end

    for i = 1, self.count do
        orderedX[i] = self.xBuffer[pos];
        orderedY[i] = self.yBuffer[pos];

        pos = pos - 1;
        if pos < 1 then
            pos = self.trailLen;
        end
    end

    self.shader:send("points_x", unpack(orderedX));
    self.shader:send("points_y", unpack(orderedY));
    self.shader:send("trailRadius", self.trailRadius);
    self.shader:send("usedPoints", self.count);

    love.graphics.setShader(self.shader);
    love.graphics.rectangle("fill", self.minX - self.trailRadius, self.minY - self.trailRadius, (self.maxX - self.minX) + self.trailRadius * 2, (self.maxY - self.minY) + self.trailRadius * 2);
    love.graphics.setShader();
end

return Trail;