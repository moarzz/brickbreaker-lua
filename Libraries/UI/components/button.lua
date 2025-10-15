local path = string.match((...), "(.+[./]).-[./]") or "";

local Button = Component.new();
Button.__index = Button;

Button._trigger = "isReleased";
Button._label = "button";

Button.upTexture   = love.graphics.newImage(path .. "textures/button_up.png"  );
Button.downTexture = love.graphics.newImage(path .. "textures/button_down.png");
Button.upTexture:setFilter("nearest", "nearest");
Button.downTexture:setFilter("nearest", "nearest");

Button.edgeScale = 6;

function Button.new(x, y, w, h, attachedDrawable)
    local instance = setmetatable(Component.new(), Button);

    instance.boundingbox = instance:addBoundingBox(x, y, w, h);
    instance.isDown = false;
    instance.isHover = false;

    instance.isRelease = 0;

    local x1 = x;
    local x2 = x + 5 * Button.edgeScale;
    local x3 = x + w - 5 * Button.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Button.edgeScale;
    local y3 = y + h - 5 * Button.edgeScale;
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
    instance.mesh:setTexture(Button.upTexture);

    if attachedDrawable then
        if not attachedDrawable.typeOf or not attachedDrawable:typeOf("Drawable") then
            error("cannot attach a non drawable to button");
        end

        if  attachedDrawable:typeOf("Mesh") or
            attachedDrawable:typeOf("ParticleSystem") or
            attachedDrawable:typeOf("SpriteBatch")
        then
            error("cannot attach drawable of type: 'Mesh', 'ParticleSystem', 'SpriteBatch'");
        end

        instance.attachedDrawable = attachedDrawable;

        local usableX = w - 2 * Button.edgeScale;
        local usableY = h - 4 * Button.edgeScale;

        instance.attachedDrawableDownShift = Button.edgeScale;
        local scaleX = usableX / attachedDrawable:getWidth();
        local scaleY = usableY / attachedDrawable:getHeight();

        instance.attachedDrawableScale = math.min(scaleX, scaleY);
        instance.attachedDrawableXOffset = x + w / 2 - attachedDrawable:getWidth() / 2 * instance.attachedDrawableScale;
        instance.attachedDrawableYOffset = y + h / 2 - attachedDrawable:getHeight() / 2 * instance.attachedDrawableScale;

        --Canvas         : getWidth(), getHeight()
        --Image          : getWidth(), getHeight()
        --Mesh           : cannot restrict
        --ParticleSystem : cannot restrict
        --SpriteBatch    : cannot restrict
        --Text           : getWidth(), getHeight()
        --Texture        : getWidth(), getHeight()
        --Video          : getWidth(), getHeight()
    end

    return instance;
end

function Button:onMousemoved(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
    else
        self.isHover = false;
    end
end

function Button:onPress(x, y)
    if self.boundingbox:isPointInside(x, y) then
        self.isHover = true;
        self.isDown = true;
        self.mesh:setTexture(self.downTexture);
    end
end

function Button:onRelease()
    if self.isDown and self.isHover then
        self.isRelease = 2;
    end

    self.isDown = false;
    self.mesh:setTexture(self.upTexture);
end

-- check for button pressed
function Button:isReleased()
    return self.isRelease ~= 0;
end

function Button:update()
    if self:isReleased() then
        self.isRelease = self.isRelease - 1;
    end
end

function Button:draw()
    love.graphics.setColor(1,0,0); -- red
    love.graphics.draw(self.mesh); -- draw button

    if self.attachedDrawable then
        love.graphics.setColor(1,1,1); -- white

        if self.isDown then
            love.graphics.draw(self.attachedDrawable, self.attachedDrawableXOffset, self.attachedDrawableYOffset, 0, self.attachedDrawableScale);
        else
            love.graphics.draw(self.attachedDrawable, self.attachedDrawableXOffset, self.attachedDrawableYOffset - self.attachedDrawableDownShift, 0, self.attachedDrawableScale);
        end
    end
end

return Button;