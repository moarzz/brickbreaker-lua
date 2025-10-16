local path = string.match((...), "(.+[./]).-[./]") or "";

local Slider = Component.new();
Slider.__index = Slider;

Slider._trigger = "getNewValue";
Slider._label = "button";

Slider.upTexture   = love.graphics.newImage(path .. "textures/button_up.png"  );
Slider.downTexture = love.graphics.newImage(path .. "textures/button_down.png");
Slider.upTexture:setFilter("nearest", "nearest");
Slider.downTexture:setFilter("nearest", "nearest");

Slider.edgeScale = 6;

function Slider.new(x, y, w)
    local instance = setmetatable(Component.new(), Slider);

    instance.boundingbox = instance:addBoundingBox(x - 5 * Slider.edgeScale, y - 5 * Slider.edgeScale, w + 10 * Slider.edgeScale, 10 * Slider.edgeScale);
    instance.isDown = false;
    instance.isHover = false;
    instance.perun = 0.5; -- start at half for *some* reason :3c
    instance.isChanged = 0;

    instance.x = x;
    instance.y = y;
    instance.w = w;

    -- instance.isRelease = 0;

    local x1 = x - 5 * Slider.edgeScale;
    local x2 = x;
    local x3 = x + w;
    local x4 = x + w + 5 * Slider.edgeScale;
    local y1 = y - 5 * Slider.edgeScale;
    local y2 = y;
    local y3 = y + 5 * Slider.edgeScale;

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
        {x3,y3, 0.5,1  };
        {x4,y2, 1  ,0.5};
        {x4,y2, 1  ,0.5};
        {x3,y3, 0.5,1  };
        {x4,y3, 1  ,1  };

        {x1,y2, 0  ,0.5};
        {x1,y3, 0  ,1  };
        {x2,y2, 0.5,0.5};
        {x2,y2, 0.5,0.5};
        {x1,y3, 0  ,1  };
        {x2,y3, 0.5,1  };

        {x2,y2, 0.5,0.5};
        {x2,y3, 0.5,1  };
        {x3,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x2,y3, 0.5,1  };
        {x3,y3, 0.5,1  };
    };

    instance.mesh = love.graphics.newMesh(meshVertices, "triangles", "dynamic");
    instance.mesh:setTexture(Slider.upTexture);

    return instance;
end

function Slider:onMousemoved(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
    else
        self.isHover = false;
    end

    if self.isDown then
        local mx = math.min(math.max(x, self.x) - self.x, self.w);
        mx = mx / self.w;

        if self.perun ~= mx then
            self.perun = mx;
            self.isChanged = 2;
        end
    end
end

function Slider:onPress(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
        self.isDown = true;
        self.mesh:setTexture(self.downTexture);
    end
end

function Slider:onRelease()
    -- if self.isDown and self.isHover then
        -- self.isRelease = 2;
    -- end

    self.isDown = false;
    self.mesh:setTexture(self.upTexture);
end

function Slider:getNewValue()
    return self.isChanged ~= 0 and self.perun;
end

-- check for button pressed
--[[function Slider:isReleased()
    return self.isRelease ~= 0;
end]]

function Slider:update()
    if self:getNewValue() then
        self.isChanged = self.isChanged - 1;
    end
end

function Slider:draw()
    love.graphics.setColor(1,0,0); -- red
    love.graphics.draw(self.mesh); -- draw button

    love.graphics.setColor(1,1,1); -- white
    love.graphics.circle("fill", self.x + self.w * self.perun, self.y, 80);
end

return Slider;