local Trail = {};
Trail.__index = Trail;

function Trail.new(trailLen)
    local instance = setmetatable({}, Trail);

    instance.prevXCoords = {}; -- list of previous positions (newset to oldest)
    instance.prevYCoords = {}; -- list of previous positions (newset to oldest)
    instance.prevDTs     = {}; -- list of previous dts (newest to oldest)
    instance.trailLen = trailLen; -- amount of time (seconds) that the trail lasts for
    instance.curLen = 0;

    return instance;
end

function Trail:addPosition(x, y, dt)
    table.insert(self.prevXCoords, x);
    table.insert(self.prevYCoords, y);

    self.curLen = self.curLen + dt;
end

return Trail;