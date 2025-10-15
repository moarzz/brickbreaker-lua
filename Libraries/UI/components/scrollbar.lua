local path = string.match((...), "(.+[./]).-[./]") or "";

local Scrollbar = Component.new();
Scrollbar.__index = Scrollbar;

Scrollbar._trigger = "isMoved";

Scrollbar.bowlTexture = love.graphics.newImage(path .. "textures/scrollbar.png"    );
Scrollbar.barTexture  = love.graphics.newImage(path .. "textures/scrollbar_bar.png");
Scrollbar.bowlTexture:setFilter("nearest", "nearest");
Scrollbar.barTexture:setFilter("nearest", "nearest");

Scrollbar.edgeScale = 3;

function Scrollbar.new(x, y, w, h, maxScrollHeight)
    local instance = setmetatable(Component.new(), Scrollbar);

    instance.totalHeight = maxScrollHeight;
    instance.barHeight = h * h / maxScrollHeight;
    instance.bowlHeight = h - instance.barHeight;
    instance.grabHeight = 0;
    instance.grabPerun = 0;
    instance.curPerun = 0;
    instance.y = y;
    instance.x = x;
    instance.h = h;
    instance.w = w;
    instance.isGrabbing = false;
    instance.moved = 0;

    instance:addBoundingBox(x, y, w, h);

    local x1 = x;
    local x2 = x + 5 * Scrollbar.edgeScale;
    local x3 = x + w - 5 * Scrollbar.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Scrollbar.edgeScale;
    local y3 = y + h - 5 * Scrollbar.edgeScale;
    local y4 = y + h;

    local bowlVertices = {
        {x1,y1, 0  ,0  };
        {x1,y2, 0  ,0.5};
        {x2,y1, 0.5,0  };
        {x2,y1, 0.5,0  };
        {x1,y2, 0  ,0.5};
        {x2,y2, 0.5,0.5};

        {x2,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y1, 0.5,0  };
        {x3,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};

        {x3,y1, 0.5,0  };
        {x3,y2, 0.5,0.5};
        {x4,y1, 1  ,0  };
        {x4,y1, 1  ,0  };
        {x3,y2, 0.5,0.5};
        {x4,y2, 1  ,0.5};

        {x3,y2, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y2, 1  ,0.5};
        {x4,y2, 1  ,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y3, 1  ,0.5};

        {x3,y3, 0.5,0.5};
        {x3,y4, 0.5,1  };
        {x4,y3, 1  ,0.5};
        {x4,y3, 1  ,0.5};
        {x3,y4, 0.5,1  };
        {x4,y4, 1  ,1  };

        {x1,y3, 0  ,0.5};
        {x1,y4, 0  ,1  };
        {x2,y3, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x1,y4, 0  ,1  };
        {x2,y4, 0.5,1  };

        {x2,y3, 0.5,0.5};
        {x2,y4, 0.5,1  };
        {x3,y3, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x2,y4, 0.5,1  };
        {x3,y4, 0.5,1  };

        {x1,y2, 0  ,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y2, 0.5,0.5};
        {x2,y2, 0.5,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y3, 0.5,0.5};

        {x2,y2, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y3, 0.5,0.5};
    };

    local topBarVertices = {
        {x1,y1, 0  ,0  };
        {x1,y2, 0  ,0.5};
        {x2,y1, 0.5,0  };
        {x2,y1, 0.5,0  };
        {x1,y2, 0  ,0.5};
        {x2,y2, 0.5,0.5};

        {x2,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y1, 0.5,0  };
        {x3,y1, 0.5,0  };
        {x2,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};

        {x3,y1, 0.5,0  };
        {x3,y2, 0.5,0.5};
        {x4,y1, 1  ,0  };
        {x4,y1, 1  ,0  };
        {x3,y2, 0.5,0.5};
        {x4,y2, 1  ,0.5};
    };

    local bottomBarVertices = {
        {x3,y1, 0.5,0.5};
        {x3,y2, 0.5,1  };
        {x4,y1, 1  ,0.5};
        {x4,y1, 1  ,0.5};
        {x3,y2, 0.5,1  };
        {x4,y2, 1  ,1  };

        {x1,y1, 0  ,0.5};
        {x1,y2, 0  ,1  };
        {x2,y1, 0.5,0.5};
        {x2,y1, 0.5,0.5};
        {x1,y2, 0  ,1  };
        {x2,y2, 0.5,1  };

        {x2,y1, 0.5,0.5};
        {x2,y2, 0.5,1  };
        {x3,y1, 0.5,0.5};
        {x3,y1, 0.5,0.5};
        {x2,y2, 0.5,1  };
        {x3,y2, 0.5,1  };
    };

    local middleBarVertices = {
        {x3,0, 0.5,0.5};
        {x3,1, 0.5,0.5};
        {x4,0, 1  ,0.5};
        {x4,0, 1  ,0.5};
        {x3,1, 0.5,0.5};
        {x4,1, 1  ,0.5};

        {x1,0, 0  ,0.5};
        {x1,1, 0  ,0.5};
        {x2,0, 0.5,0.5};
        {x2,0, 0.5,0.5};
        {x1,1, 0  ,0.5};
        {x2,1, 0.5,0.5};

        {x2,0, 0.5,0.5};
        {x2,1, 0.5,0.5};
        {x3,0, 0.5,0.5};
        {x3,0, 0.5,0.5};
        {x2,1, 0.5,0.5};
        {x3,1, 0.5,0.5};
    };

    instance.bowlMesh = love.graphics.newMesh(bowlVertices, "triangles", "static");
    instance.topBarMesh = love.graphics.newMesh(topBarVertices, "triangles", "static");
    instance.middleBarMesh = love.graphics.newMesh(middleBarVertices, "triangles", "static");
    instance.bottomBarMesh = love.graphics.newMesh(bottomBarVertices, "triangles", "static");
    instance.bowlMesh:setTexture(Scrollbar.bowlTexture);
    instance.topBarMesh:setTexture(Scrollbar.barTexture);
    instance.middleBarMesh:setTexture(Scrollbar.barTexture);
    instance.bottomBarMesh:setTexture(Scrollbar.barTexture);

    return instance;
end

function Scrollbar:setMaxScrollHeight(newMaxScrollHeight)
    self.totalHeight = newMaxScrollHeight;
    self.barHeight = self.h * self.h / newMaxScrollHeight;
    self.bowlHeight = self.h - self.barHeight;
end

function Scrollbar:onMousemoved(x, y)
    if not self.isGrabbing then
        return;
    end

    local ty = y - self.y;

    local movedY = ty - self.grabHeight;
    local movedPerun = movedY / self.bowlHeight;

    local wantPerun = self.grabPerun + movedPerun;

    self.curPerun = math.max(math.min(1, wantPerun), 0);

    self.moved = 2;
end

function Scrollbar:onPress(x, y)
    local ty = y - self.y;
    local tx = x - self.x;

    if tx < 3 * self.edgeScale or tx >= self.w - 3 * self.edgeScale then
        return;
    end

    local barLow = self.bowlHeight * self.curPerun + 4 * self.edgeScale;
    local barHi  = self.bowlHeight * self.curPerun + self.barHeight - 4 * self.edgeScale;

    if ty >= barLow and ty < barHi then
        self.isGrabbing = true;
        self.grabHeight = ty;
        self.grabPerun = self.curPerun;

        self.moved = 2;

        return;
    end

    local wantPerun = (ty - self.barHeight / 2) / self.bowlHeight;

    self.curPerun = math.max(math.min(1, wantPerun), 0);
    self.grabHeight = ty;
    self.grabPerun = self.curPerun;
    self.isGrabbing = true;

    self.moved = 2;
end

function Scrollbar:onWheel(x, y)
    self.curPerun = math.max(math.min(1, self.curPerun - y * 10 / self.totalHeight), 0);
    self.moved = 2;
end

function Scrollbar:onRelease()
    self.isGrabbing = false;
end

function Scrollbar:isMoved()
    return self.moved ~= 0;
end

function Scrollbar:getScrollAmount()
    return self.curPerun * (self.totalHeight - self.h);
end

function Scrollbar:update()
    if self:isMoved() then
        self.moved = self.moved - 1;
    end
end

function Scrollbar:draw()
    love.graphics.setColor(1,1,1); -- white
    love.graphics.draw(self.bowlMesh); -- draw scrollbar bowl

    -- dont allow visual bugs when bar starts to get too small and fold inwards
    local minBarHeight = math.max(self.barHeight, 10 * self.edgeScale);
    local yOff = self.curPerun * self.bowlHeight - (minBarHeight - self.barHeight) / 2;

    love.graphics.draw(self.topBarMesh   , 0, yOff);
    love.graphics.draw(self.middleBarMesh, 0, yOff + 5 * self.edgeScale + self.y, 0, 1, minBarHeight - 10 * self.edgeScale);
    love.graphics.draw(self.bottomBarMesh, 0, yOff - 5 * self.edgeScale + minBarHeight);
end

return Scrollbar;