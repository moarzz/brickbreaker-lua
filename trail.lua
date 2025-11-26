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

--[[
function Trail:formMesh()
    if #self.prevXCoords <= 1 then -- dont cause issues
        return;
    end

    local vertices = {};

    local prevInd = 0;
    local prevTime = 0;
    for i = 1, #self.prevXCoords do
        local prevVertX = self.prevXCoords[i - 1];
        local prevVertY = self.prevYCoords[i - 1];
        local curVertX =  self.prevXCoords[i    ];
        local curVertY =  self.prevYCoords[i    ];
        local nextVertX = self.prevXCoords[i + 1];
        local nextVertY = self.prevYCoords[i + 1];

        if i == 1 then
            prevVertX = curVertX - (nextVertX - curVertX);
            prevVertY = curVertY - (nextVertY - curVertY);
        elseif i == #self.prevXCoords then
            nextVertX = curVertX - (prevVertX - curVertX);
            nextVertY = curVertY - (prevVertY - curVertY);
        end

        local pxn = curVertX - prevVertX;
        local pyn = curVertY - prevVertY;

        local pdist = math.sqrt(pxn * pxn + pyn * pyn);

        pxn = pxn / pdist;
        pyn = pyn / pdist;

        local nxn = nextVertX - curVertX;
        local nyn = nextVertY - curVertY;

        local ndist = math.sqrt(nxn * nxn + nyn * nyn);

        nxn = nxn / ndist;
        nyn = nyn / ndist;

        local curRadius = self.trailRadius * (self.trailLen - i + 1) / self.trailLen;
        local perun = 1 - ((i - 1) / self.trailLen);

        local vert1;
        local vert2;

        -- if the ball has not bounced in this time step
        if pxn * nxn + pyn * nyn >= 0.99 then
            vert1 = {
                curVertX - nyn * curRadius; -- x
                curVertY + nxn * curRadius; -- y
                0; -- texture coord x
                perun; -- texture coord y
                1,1,1,1; -- colour
            };

            vert2 = {
                curVertX + nyn * curRadius; -- x
                curVertY - nxn * curRadius; -- y
                1; -- texture coord x
                perun; -- texture coord y
                1,1,1,1; -- colour
            };
        else -- if the ball bounced in this timestep

        end
    end

    for i = 1, #self.prevXCoords do
        local perun = i / self.trailLen;
        local time = perun * self.curLen;

        while prevTime < time do
            prevInd = prevInd + 1;
            prevTime = prevTime + self.prevDTs[prevInd];
        end

        local x, y; -- position of the next 1d vertex
        local xn, yn; -- normals of the next 1d vertex

        if prevInd == #self.prevDTs then -- if its the last value, then we need to interpolate based off of other info
            local lerpToNext = (prevTime - time) / self.prevDTs[prevInd] + 1;

            xn = self.prevXCoords[prevInd] - self.prevXCoords[prevInd - 1];
            yn = self.prevYCoords[prevInd] - self.prevYCoords[prevInd - 1];
            x = self.prevXCoords[prevInd - 1] + xn * lerpToNext;
            y = self.prevYCoords[prevInd - 1] + yn * lerpToNext;

            local normalLen = math.sqrt(xn * xn + yn * yn);

            xn = xn / normalLen;
            yn = yn / normalLen;
        else
            local lerpToNext = (prevTime - time) / self.prevDTs[prevInd];

            xn = self.prevXCoords[prevInd + 1] - self.prevXCoords[prevInd];
            yn = self.prevYCoords[prevInd + 1] - self.prevYCoords[prevInd];
            x = self.prevXCoords[prevInd] + xn * lerpToNext;
            y = self.prevYCoords[prevInd] + yn * lerpToNext;

            local normalLen = math.sqrt(xn * xn + yn * yn);

            xn = xn / normalLen;
            yn = yn / normalLen;
        end

        local curRadius = self.trailRadius * time / self.trailLen;

        local leftVertex = {
            x - yn * curRadius; -- x
            y + xn * curRadius; -- y
            0; -- texture coord x
            perun; -- texture coord y
            1,1,1,1; -- colour
        };

        local rightVertex = {
            x + yn * curRadius; -- x
            y - xn * curRadius; -- y
            1; -- texture coord x
            perun; -- texture coord y
            1,1,1,1; -- colour
        };

        table.insert(vertices, leftVertex);
        table.insert(vertices, rightVertex);
    end

    local tipVertex = {
        self.prevXCoords[#self.prevXCoords - 1] + (self.prevXCoords[#self.prevXCoords] - self.prevXCoords[#self.prevXCoords - 1]) * 2; -- x
        self.prevYCoords[#self.prevYCoords - 1] + (self.prevYCoords[#self.prevYCoords] - self.prevYCoords[#self.prevYCoords - 1]) * 2; -- y
        0.5; -- texture coord x
        1; -- texture coord y
        1,1,1,1; -- colour
    };

    table.insert(vertices, tipVertex);
    -- print(#vertices);

    self.mesh:setVertices(vertices);
end
]]

function Trail:draw()
    -- love.graphics.setColor(1,1,1); -- white

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