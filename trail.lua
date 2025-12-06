local Trail = {};
Trail.__index = Trail;

Trail.shader = love.graphics.newShader("trail", "Shaders/trail.frag");
-- Trail.circle = love.graphics.newImage("assets/sprites/circle.png");

function Trail.new(trailRadius, trailLen)
    local instance = setmetatable({}, Trail);

    instance.prevXCoords = {}; -- list of previous positions (newset to oldest)
    instance.prevYCoords = {}; -- list of previous positions (newset to oldest)
    -- instance.prevDTs     = {}; -- list of previous dts (newest to oldest)

    instance.trailLen = trailLen; -- amount of previous positions to remember
    instance.trailRadius = trailRadius; -- radius of the trail
    -- instance.curLen = 0;

    -- instance.spriteBatch = love.graphics.newSpriteBatch(Trail.circle, trailLen);

    -- instance.verticeCount = 60; -- number of 1d vertices (mesh uses 2 2d vertices per 1d vertex)
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
    table.insert(self.prevXCoords, 1, x);
    table.insert(self.prevYCoords, 1, y);

    while #self.prevXCoords > self.trailLen do
        table.remove(self.prevXCoords, self.trailLen + 1);
        table.remove(self.prevYCoords, self.trailLen + 1);
    end

    self.minX = x;
    self.minY = y;
    self.maxX = x;
    self.maxY = y;

    for i = 2, #self.prevXCoords do
        self.minX = math.min(self.minX, self.prevXCoords[i]);
        self.minY = math.min(self.minY, self.prevYCoords[i]);
        self.maxX = math.max(self.maxX, self.prevXCoords[i]);
        self.maxY = math.max(self.maxY, self.prevYCoords[i]);
    end

    --self:formMesh();
end

function Trail:kickData()
    table.remove(self.prevXCoords, #self.prevXCoords);
    table.remove(self.prevYCoords, #self.prevYCoords);

    return #self.prevXCoords == 0;
end

function Trail:draw()
    -- love.graphics.setColor(1,1,1); -- white

    if #self.prevXCoords <= 0 then
        return;
    end

    self.shader:send("points_x", unpack(self.prevXCoords));
    self.shader:send("points_y", unpack(self.prevYCoords));
    self.shader:send("trailRadius", self.trailRadius);
    self.shader:send("usedPoints", #self.prevXCoords);

    love.graphics.setShader(self.shader);

    love.graphics.rectangle("fill", self.minX - self.trailRadius, self.minY - self.trailRadius, (self.maxX - self.minX) + self.trailRadius * 2, (self.maxY - self.minY) + self.trailRadius * 2);
    -- love.graphics.draw(self.mesh);

    love.graphics.setShader();

    -- love.graphics.circle("fill", love.mouse.getX(), love.mouse.getY(), 10);
end

return Trail;