local path = string.match((...), "(.+[./]).-[./]") or "";

local Dropdown = Component.new();
Dropdown.__index = Dropdown;

Dropdown._trigger = "isSelected";

Dropdown.upTexture   = love.graphics.newImage(path .. "textures/button_up.png"  );
Dropdown.downTexture = love.graphics.newImage(path .. "textures/button_down.png");
Dropdown.upTexture:setFilter("nearest", "nearest");
Dropdown.downTexture:setFilter("nearest", "nearest");

Dropdown.edgeScale = 3;

function Dropdown.new(x, y, w, h, defaultState, options, attachedDrawable)
    local instance = setmetatable(Component.new(), Dropdown);

    instance.mainBox = instance:addBoundingBox(x, y, w, h);
    instance.optionHeight = h;

    instance.isDown = false;
    instance.isHover = false;
    instance.hoveringOption = nil;
    instance.downOnOption = nil;

    instance.options = options or {};

    instance.selected = nil;
    instance.newSelected = 0;

    instance.isOpen = false;

    local x1 = x;
    local x2 = x + 5 * Dropdown.edgeScale;
    local x3 = x + w - 5 * Dropdown.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Dropdown.edgeScale;
    local y3 = y + h - 5 * Dropdown.edgeScale;
    local y4 = y + h;

    local upMeshVerts = {
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

    local middleMeshVerts = {
        {x3,y2, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y2, 1  ,0.5};
        {x4,y2, 1  ,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y3, 1  ,0.5};

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

    local bottomMeshVerts = {
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
    };

    local middleMesh2Verts = {
        {x3,y2, 0.5,0.5};
        {x3,y4, 0.5,0.5};
        {x4,y2, 1  ,0.5};
        {x4,y2, 1  ,0.5};
        {x3,y4, 0.5,0.5};
        {x4,y4, 1  ,0.5};

        {x1,y2, 0  ,0.5};
        {x1,y4, 0  ,0.5};
        {x2,y2, 0.5,0.5};
        {x2,y2, 0.5,0.5};
        {x1,y4, 0  ,0.5};
        {x2,y4, 0.5,0.5};

        {x2,y2, 0.5,0.5};
        {x2,y4, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x3,y2, 0.5,0.5};
        {x2,y4, 0.5,0.5};
        {x3,y4, 0.5,0.5};
    };

    local middleMesh3Verts = {
        {x3,y1, 0.5,0.5};
        {x3,y4, 0.5,0.5};
        {x4,y1, 1  ,0.5};
        {x4,y1, 1  ,0.5};
        {x3,y4, 0.5,0.5};
        {x4,y4, 1  ,0.5};

        {x1,y1, 0  ,0.5};
        {x1,y4, 0  ,0.5};
        {x2,y1, 0.5,0.5};
        {x2,y1, 0.5,0.5};
        {x1,y4, 0  ,0.5};
        {x2,y4, 0.5,0.5};

        {x2,y1, 0.5,0.5};
        {x2,y4, 0.5,0.5};
        {x3,y1, 0.5,0.5};
        {x3,y1, 0.5,0.5};
        {x2,y4, 0.5,0.5};
        {x3,y4, 0.5,0.5};
    };

    local middleMesh4Verts = {
        {x3,y1, 0.5,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y1, 1  ,0.5};
        {x4,y1, 1  ,0.5};
        {x3,y3, 0.5,0.5};
        {x4,y3, 1  ,0.5};

        {x1,y1, 0  ,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y1, 0.5,0.5};
        {x2,y1, 0.5,0.5};
        {x1,y3, 0  ,0.5};
        {x2,y3, 0.5,0.5};

        {x2,y1, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y1, 0.5,0.5};
        {x3,y1, 0.5,0.5};
        {x2,y3, 0.5,0.5};
        {x3,y3, 0.5,0.5};
    };

    instance.UpMesh = love.graphics.newMesh(upMeshVerts, "triangles", "static");
    instance.MiddleMesh = love.graphics.newMesh(middleMeshVerts, "triangles", "static");
    instance.BottomMesh = love.graphics.newMesh(bottomMeshVerts, "triangles", "static");
    instance.Middle2Mesh = love.graphics.newMesh(middleMesh2Verts, "triangles", "static");
    instance.Middle3Mesh = love.graphics.newMesh(middleMesh3Verts, "triangles", "static");
    instance.Middle4Mesh = love.graphics.newMesh(middleMesh4Verts, "triangles", "static");

    instance.UpMesh:setTexture(Dropdown.upTexture);
    instance.MiddleMesh:setTexture(Dropdown.upTexture);
    instance.BottomMesh:setTexture(Dropdown.upTexture);
    instance.Middle2Mesh:setTexture(Dropdown.upTexture);
    instance.Middle3Mesh:setTexture(Dropdown.upTexture);
    instance.Middle4Mesh:setTexture(Dropdown.upTexture);

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

        local usableX = w - 2 * Dropdown.edgeScale;
        local usableY = h - 4 * Dropdown.edgeScale;

        instance.attachedDrawableDownShift = Dropdown.edgeScale;
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

function Dropdown:onHover()
    self.isHover = true;
end
function Dropdown:unHover()
    self.isHover = false;
end

function Dropdown:unFocus()
    self.isOpen = false;
    self.mainBox:setDimmensions(nil, self.optionHeight);
end

function Dropdown:onPress(x, y)
    self.isDown = true;

    if self.isOpen then
        local rx, ry = self.mainBox:getRelativePosition(x, y);

        local mouseDownOn = math.floor(ry / self.optionHeight);

        if mouseDownOn > 0 and mouseDownOn <= #self.options then
            self.downOnOption = mouseDownOn;
        else
            self.downOnOption = nil;
        end
    end
end

function Dropdown:onRelease(x, y)
    if self.isOpen then
        if self.isHover then
            local rx, ry = self.mainBox:getRelativePosition(x, y);

            local mouseDownOn = math.floor(ry / self.optionHeight);

            if mouseDownOn == self.downOnOption then
                self.newSelected = 2;
                self.selected = mouseDownOn;
            elseif mouseDownOn == 0 then
                self.isDown = false;
                self.isOpen = false;
                self.mainBox:setDimmensions(nil, self.optionHeight);

                return;
            end

            self.downOnOption = nil;
        else
            self.downOnOption = nil;
        end
    end

    if self.isDown and self.isHover then
        self.isOpen = true;

        self.mainBox:setDimmensions(nil, self.optionHeight * (1 + #self.options));
    end

    self.isDown = false;
end

function Dropdown:isSelected()
    return self.newSelected ~= 0;
end

function Dropdown:update()
    if self:isSelected() then
        self.newSelected = self.newSelected - 1;
    end
end

function Dropdown:draw()
    love.graphics.setColor(1,0,0);

    if self.isOpen and #self.options > 0 then
        self.UpMesh:setTexture(self.upTexture);
        self.Middle2Mesh:setTexture(self.upTexture);
        self.Middle3Mesh:setTexture(self.upTexture);

        love.graphics.draw(self.UpMesh);
        love.graphics.draw(self.Middle2Mesh);

        for i, v in ipairs(self.options) do
            if i == #self.options then
                if i == self.downOnOption then
                    love.graphics.setColor(0.8, 0, 0);
                    self.BottomMesh:setTexture(self.downTexture);
                    self.Middle4Mesh:setTexture(self.downTexture);
                else
                    love.graphics.setColor(1, 0, 0);
                    self.BottomMesh:setTexture(self.upTexture);
                    self.Middle4Mesh:setTexture(self.upTexture);
                end

                love.graphics.draw(self.Middle4Mesh, 0, self.optionHeight * i);
                love.graphics.draw(self.BottomMesh, 0, self.optionHeight * i);
            else
                if i == self.downOnOption then
                    love.graphics.setColor(0.8, 0, 0);
                    self.Middle3Mesh:setTexture(self.downTexture);
                else
                    love.graphics.setColor(1, 0, 0);
                    self.Middle3Mesh:setTexture(self.upTexture);
                end

                love.graphics.draw(self.Middle3Mesh, 0, self.optionHeight * i);
            end
        end
    else
        if self.isDown then
            love.graphics.draw(self.UpMesh);
            love.graphics.draw(self.MiddleMesh);
            love.graphics.draw(self.BottomMesh);
        else
            love.graphics.draw(self.UpMesh);
            love.graphics.draw(self.MiddleMesh);
            love.graphics.draw(self.BottomMesh);
        end
    end

    if self.attachedDrawable then
        love.graphics.setColor(1,1,1); -- white

        if self.isDown and not self.isOpen then
            love.graphics.draw(self.attachedDrawable, self.attachedDrawableXOffset, self.attachedDrawableYOffset, 0, self.attachedDrawableScale);
        else
            love.graphics.draw(self.attachedDrawable, self.attachedDrawableXOffset, self.attachedDrawableYOffset - self.attachedDrawableDownShift, 0, self.attachedDrawableScale);
        end
    end
end

return Dropdown;