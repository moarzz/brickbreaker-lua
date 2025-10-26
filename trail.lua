local Trail = {};
Trail.__index = Trail;

function Trail.new(trailRadius, trailLen)
    local instance = setmetatable({}, Trail);

    instance.prevXCoords = {}; -- list of previous positions (newset to oldest)
    instance.prevYCoords = {}; -- list of previous positions (newset to oldest)
    instance.prevDTs     = {}; -- list of previous dts (newest to oldest)

    instance.trailLen = trailLen; -- amount of time (seconds) that the trail lasts for
    instance.curLen = 0;

    instance.trailRadius = trailRadius; -- radius of the trail

    instance.verticeCount = 20; -- number of 1d vertices (mesh uses 2 2d vertices per 1d vertex)
    instance.mesh = love.graphics.newMesh(instance.verticeCount * 2 + 3, "strip", "stream");

    return instance;
end

function Trail:addPosition(x, y, dt)
    table.insert(self.prevXCoords, x);
    table.insert(self.prevYCoords, y);
    table.insert(self.prevDTs, dt); -- not technically necessary since dt is fixed. but fuck it

    self.curLen = self.curLen + dt;

    while self.curLen > self.trailLen do
        self.curLen = self.curLen - table.remove(self.prevDTs, #self.prevDTs);
        table.remove(self.prevXCoords, #self.prevXCoords);
        table.remove(self.prevYCoords, #self.prevYCoords);
    end
end

function Trail:formMesh()
    if #self.prevDTs <= 1 then -- dont cause issues
        return;
    end

    local vertices = {};

    local prevInd = 0;
    local prevTime = 0;
    for i = 0, self.verticeCount do
        local perun = i / self.verticeCount;
        local time = perun * self.curTime;

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
        };

        local rightVertex = {
            x + yn * curRadius; -- x
            y - xn * curRadius; -- y
            1; -- texture coord x
            perun; -- texture coord y
        };

        table.insert(vertices, leftVertex);
        table.insert(vertices, rightVertex);
    end

    local tipVertex = {
        self.prevXCoords[#self.prevXCoords - 1] + (self.prevXCoords[#self.prevXCoords] - self.prevXCoords[#self.prevXCoords - 1]) * 2; -- x
        self.prevYCoords[#self.prevYCoords - 1] + (self.prevYCoords[#self.prevYCoords] - self.prevYCoords[#self.prevYCoords - 1]) * 2; -- y
        0.5; -- texture coord x
        1; -- texture coord y
    };

    table.insert(vertices, tipVertex);

    self.mesh:setVertices(vertices);
end

return Trail;