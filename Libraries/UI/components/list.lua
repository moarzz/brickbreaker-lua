local path = string.match((...), "(.+[./]).-[./]") or "";

local List = Component.new();
List.__index = List;

List._trigger = nil;

List.upTexture   = love.graphics.newImage(path .. "textures/button_up.png"  );
List.downTexture = love.graphics.newImage(path .. "textures/button_down.png");
--List.font = love.graphics.newFont("SpaceMono.ttf", 128);
List.upTexture:setFilter("nearest", "nearest");
List.downTexture:setFilter("nearest", "nearest");


List.edgeScale = 3;


function List.new(x, y, w, h, maxHeight, items, attachedDrawable)
    local instance = setmetatable(Component.new(), List);

    instance.items = items or {};

    instance.scrollbar = instance:addTrigger(Scrollbar(x + w - 30 - instance.edgeScale, y + h, 30, maxHeight - h - 3 * instance.edgeScale, #instance.items * h), "scrollbarMoved");
    instance.needScrollbar = false;
    instance.scroll = 0;

    if #instance.items * h >= maxHeight then
        instance.needScrollbar = true;
    end

    instance.x = x;
    instance.y = y;
    instance.w = w;

    instance.mainBox = instance:addBoundingBox(x, y, w, h);
    instance.itemHeight = h;
    instance.maxHeight = maxHeight;
    instance.scrollHeight = 0; -- the amount of pixels the items have been scrolled upwards
    instance.scrollbarHeight = 0; -- how many pixels tal the scrollbar is
    instance.scrollbarOffset = 0; -- pixels the scrollbar has moved
    instance.scrollbarGrabHeight = 0; -- the y value of the mouse where it grabbed the scrollBar

    instance.isDown = false;
    instance.isHover = false;


    instance.isOpen = false;

    local x1 = x;
    local x2 = x + 5 * List.edgeScale;
    local x3 = x + w - 5 * List.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * List.edgeScale;
    local y3 = y + h - 5 * List.edgeScale;
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

    local arrowVerts = {
        {-1 / 3, -1 / 2};
        {2 / 3, 0};
        {-1 / 3, 1 / 2};
    };

    instance.UpMesh = love.graphics.newMesh(upMeshVerts, "triangles", "static");
    instance.MiddleMesh = love.graphics.newMesh(middleMeshVerts, "triangles", "static");
    instance.BottomMesh = love.graphics.newMesh(bottomMeshVerts, "triangles", "static");
    instance.Middle2Mesh = love.graphics.newMesh(middleMesh2Verts, "triangles", "static");
    instance.Middle3Mesh = love.graphics.newMesh(middleMesh3Verts, "triangles", "static");
    instance.Middle4Mesh = love.graphics.newMesh(middleMesh4Verts, "triangles", "static");
    instance.arrowMesh = love.graphics.newMesh(arrowVerts, "triangles", "static");

    instance.UpMesh:setTexture(List.upTexture);
    instance.MiddleMesh:setTexture(List.upTexture);
    instance.BottomMesh:setTexture(List.upTexture);
    instance.Middle2Mesh:setTexture(List.upTexture);
    instance.Middle3Mesh:setTexture(List.upTexture);
    instance.Middle4Mesh:setTexture(List.upTexture);

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

        local usableX = w - 2 * List.edgeScale;
        local usableY = h - 4 * List.edgeScale;

        instance.attachedDrawableDownShift = List.edgeScale;
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

function List:addItem(item)
    table.insert(self.items, item);

    if #self.items * self.itemHeight >= self.maxHeight then
        self.needScrollbar = true;
        self.scrollbar:setMaxScrollHeight(#self.items * self.itemHeight);
    end

    if self.isOpen then
        self.mainBox:setDimmensions(nil, math.min(self.itemHeight * (1 + #self.items), self.maxHeight));
    end
end

function List:getItems()
    return self.items;
end

function List:getItem(index)
    return self.items[index];
end

function List:changeItem(setTo, index)
    self.items[index] = setTo;
end

function List:removeItem(index)
    return table.remove(self.items, index);
end

function List:scrollbarMoved()
    self.scroll = self.scrollbar:getScrollAmount();
end

function List:onHover()
    self.isHover = true;
end
function List:unHover()
    self.isHover = false;
end

function List:unFocus()
    self.isOpen = false;
    self.mainBox:setDimmensions(nil, self.itemHeight);
end

function List:onPress(x, y)
    self.isDown = true;
end

function List:onRelease(x, y)
    if self.isOpen and self.isHover then
        local rx, ry = self.mainBox:getRelativePosition(x, y);

        local mouseDownOn = math.floor(ry / self.itemHeight);

        if mouseDownOn == 0 then
            self.isDown = false;
            self.isOpen = false;
            self.mainBox:setDimmensions(nil, self.itemHeight);

            return;
        end
    end

    if self.isDown and self.isHover then
        self.isOpen = true;

        self.mainBox:setDimmensions(nil, math.min(self.itemHeight * (1 + #self.items), self.maxHeight));
    end

    self.isDown = false;
end

function List:draw()
    love.graphics.setColor(1,0,0);

    if self.isOpen and #self.items > 0 then
        self.UpMesh:setTexture(self.upTexture);
        self.Middle2Mesh:setTexture(self.upTexture);
        self.Middle3Mesh:setTexture(self.upTexture);
        self.BottomMesh:setTexture(self.upTexture);
        self.Middle4Mesh:setTexture(self.upTexture);

        love.graphics.draw(self.UpMesh);
        love.graphics.draw(self.Middle2Mesh);

        local broke = false;
        for i = 1, #self.items do
            if self.itemHeight * (i + 1) > self.maxHeight then
                broke = true;
                break;
            end

            if i == #self.items or self.itemHeight * (i + 2) > self.maxHeight then
                love.graphics.draw(self.Middle4Mesh, 0, self.itemHeight * i);
                love.graphics.draw(self.BottomMesh, 0, self.itemHeight * i);
            else
                love.graphics.draw(self.Middle3Mesh, 0, self.itemHeight * i);
            end
        end

        love.graphics.push();

        if broke then
            local function drawBorder()
                for i = 1, #self.items do
                    if self.itemHeight * (i + 1) > self.maxHeight then
                        break;
                    end

                    if i == #self.items or self.itemHeight * (i + 2) > self.maxHeight then
                        love.graphics.draw(self.Middle4Mesh, 0, self.itemHeight * i);
                        love.graphics.draw(self.BottomMesh, 0, self.itemHeight * i - 2 * self.edgeScale);
                        -- -2 for the edge pixels on the bottom of the texture
                    else
                        love.graphics.draw(self.Middle3Mesh, 0, self.itemHeight * i);
                    end
                end
            end

            love.graphics.stencil(drawBorder, "replace", 1, false);
            love.graphics.setStencilTest("equal", 1);
        end

        love.graphics.translate(0, -self.scroll);

        love.graphics.setColor(1,1,1); -- white;
        love.graphics.setFont(PIXEL_FONT_128);

        local fontHeight = PIXEL_FONT_128;
        local printScale = (self.itemHeight - 2 * self.edgeScale) / fontHeight;

        for i, v in ipairs(self.items) do
            love.graphics.print(v, self.x + 2 * self.edgeScale, self.y + i * self.itemHeight, 0, printScale);
        end

        love.graphics.setStencilTest();
        love.graphics.pop();

        love.graphics.setColor(1,1,1);
        love.graphics.draw(self.arrowMesh, self.x + self.w - self.itemHeight / 2 - 2 * self.edgeScale, self.y + self.itemHeight / 2 - self.edgeScale, math.pi / 2, self.itemHeight - 6 * self.edgeScale);

        if self.needScrollbar then
            self.scrollbar:draw();
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

        love.graphics.setColor(1,1,1);
        love.graphics.draw(self.arrowMesh, self.x + self.w - self.itemHeight / 2 - 2 * self.edgeScale, self.y + self.itemHeight / 2 - self.edgeScale, 0, self.itemHeight - 6 * self.edgeScale);
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

return List;