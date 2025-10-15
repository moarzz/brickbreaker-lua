local path = string.match((...), "(.+[./]).-[./]") or "";

local Tickbox = Component.new();
Tickbox.__index = Tickbox;

Tickbox._trigger = "isChanged";

Tickbox.texture = love.graphics.newImage(path .. "textures/tickbox.png");
Tickbox.texture:setFilter("nearest", "nearest");

Tickbox.edgeScale = 3;

function Tickbox.new(x, y, w, h)
    local instance = setmetatable(Component.new(), Tickbox);

    instance.boundingbox = instance:addBoundingBox(x, y, w, h);
    instance.isDown = false;
    instance.isHover = false;

    instance.active = false;

    instance.isRelease = 0;

    instance.x = x;
    instance.y = y;
    instance.w = w;
    instance.h = h;

    local x1 = x;
    local x2 = x + 5 * Tickbox.edgeScale;
    local x3 = x + w - 5 * Tickbox.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Tickbox.edgeScale;
    local y3 = y + h - 5 * Tickbox.edgeScale;
    local y4 = y + h;

    local meshVertices = {
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

    instance.mesh = love.graphics.newMesh(meshVertices, "triangles", "dynamic");
    instance.mesh:setTexture(Tickbox.texture);

    return instance;
end

function Tickbox:onMousemoved(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
    else
        self.isHover = false;
    end
end

function Tickbox:onPress(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
        self.isDown = true;
    end
end

function Tickbox:onRelease()
    if self.isDown and self.isHover then
        self.isRelease = 2;
        self.active = not self.active;
    end

    self.isDown = false;
end

-- check for button pressed
function Tickbox:isChanged()
    return self.isRelease ~= 0;
end

function Tickbox:isActive()
    return self.active;
end

function Tickbox:update()
    if self:isChanged() then
        self.isRelease = self.isRelease - 1;
    end
end

function Tickbox:draw()
    love.graphics.setColor(1,0,0); -- red
    love.graphics.draw(self.mesh); -- draw button

    if self.active then
        love.graphics.setColor(1,1,1,0.7); -- white, slightly transparent
        love.graphics.rectangle("fill", self.x + 3 * self.edgeScale, self.y + 3 * self.edgeScale, self.w - 6 * self.edgeScale, self.h - 7 * self.edgeScale, 4,4,3);
    end
end

return Tickbox;