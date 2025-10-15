local path = string.match((...), "(.+[./]).-[./]") or "";

local Accordion = Component.new();
Accordion.__index = Accordion;

Accordion._trigger = "isSelected";

Accordion.edgeScale = 3;

--Accordion.font = love.graphics.newFont("SpaceMono.ttf", 128);
Accordion.texture = love.graphics.newImage(path .. "textures/button_up.png");
Accordion.texture:setFilter("nearest", "nearest");

Accordion.darkeningMag = 0.85;

function Accordion.new(x, y, w, h, map)
    local instance = setmetatable(Component.new(), Accordion);

    instance.boundingbox = instance:addBoundingBox(x, y, w, h);

    local recurseFunc = nil;
    recurseFunc = function(tbl)
        for i, v in ipairs(tbl) do
            if type(v) == "table" then
                tbl[i] = {open = false, canOpen = true, data = recurseFunc(v)};
            else
                tbl[i] = {open = false, canOpen = false, data = v};
            end
        end

        return tbl;
    end

    instance.selectedNew = 0; -- timer for isSelected
    instance.selected = nil;  -- which item was selected

    instance.isDown = false; -- if an item is being pressed
    instance.downOn = nil;   -- which item height is being pressed

    instance.map = recurseFunc(map);

    instance.x = x;
    instance.y = y;
    instance.w = w;
    instance.h = h;

    local x1 = x;
    local x2 = x + 5 * Accordion.edgeScale;
    local x3 = x + w - 5 * Accordion.edgeScale;
    local x4 = x + w;
    local y1 = y;
    local y2 = y + 5 * Accordion.edgeScale;
    local y3 = y + h - 5 * Accordion.edgeScale;
    local y4 = y + h;

    local topMeshVerts = {
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

        {x1,y2, 0  ,0.5};
        {x4,y2, 1  ,0.5};
        {x1,y4, 0  ,0.5};
        {x1,y4, 0  ,0.5};
        {x4,y2, 1  ,0.5};
        {x4,y4, 1  ,0.5};
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

        {x1,y1, 0  ,0.5};
        {x4,y1, 1  ,0.5};
        {x1,y3, 0  ,0.5};
        {x1,y3, 0  ,0.5};
        {x4,y1, 1  ,0.5};
        {x4,y3, 1  ,0.5};
    };

    local arrowVerts = {
        {-1 / 3, -1 / 2};
        {2 / 3, 0};
        {-1 / 3, 1 / 2};
    };

    instance.arrowMesh = love.graphics.newMesh(arrowVerts, "triangles", "static");
    instance.topMesh = love.graphics.newMesh(topMeshVerts, "triangles", "static");
    instance.bottomMesh = love.graphics.newMesh(bottomMeshVerts, "triangles", "static");
    instance.topMesh:setTexture(Accordion.texture);
    instance.bottomMesh:setTexture(Accordion.texture);

    instance:updateHeight();

    return instance;
end

function Accordion:onPress(x, y)
    if not self.boundingbox:isPointInside(x, y) then
        return;
    end

    self.downOn = math.floor((y - self.y) / self.h) + 1;
    self.isDown = true;
end

function Accordion:onRelease(x, y)
    self.isDown = false;

    if not self.boundingbox:isPointInside(x, y) then
        return;
    end

    local curRelease = math.floor((y - self.y) / self.h) + 1;

    if curRelease ~= self.downOn then
        return;
    end

    local newActivate = self:getItemFromIndex(curRelease);

    if newActivate.canOpen then
        newActivate.open = not newActivate.open;
        self:updateHeight();
    else
        self.selectedNew = 2;
        self.select = newActivate;
    end
end

function Accordion:isSelected()
    return self.selectedNew ~= 0;
end

function Accordion:getItemFromIndex(ind, curInd, curTbl)
    curInd = curInd or 0;
    curTbl = curTbl or self.map;

    for i, v in ipairs(curTbl) do
        curInd = curInd + 1;

        if curInd == ind then
            return v, curInd;
        elseif v.open then
            local ret, newCurInd = self:getItemFromIndex(ind, curInd, v.data);
            curInd = newCurInd;

            if ret then
                return ret, curInd;
            end
        end
    end

    return nil, curInd;
end

function Accordion:updateHeight(curTbl, retInd)
    curTbl = curTbl or self.map;

    local ind = 0;

    for i, v in ipairs(curTbl) do
        ind = ind + 1;

        if v.open then
            ind = ind + self:updateHeight(v.data, true);
        end
    end

    if retInd then
        return ind;
    end

    self.boundingbox:setDimmensions(self.w, self.h * ind);
end

function Accordion:update()
    if self:isSelected() then
        self.selectedNew = self.selectedNew - 1;
    end
end

function Accordion:drawMap(isFirst, isLast, curTbl, darkening, yMag)
    curTbl = curTbl or self.map;
    darkening = darkening or 0;
    yMag = yMag or 0;

    local textScale = (self.h - 2 * self.edgeScale) / PIXEL_FONT_HEIGHT;

    --* very long and kinda messy code, trying to clean it only results in more potential bugs
    --? so is the way of coding ui
    for i, v in ipairs(curTbl) do
        yMag = yMag + 1;

        if v.open then
            darkening = darkening + 1;
            love.graphics.setColor(1 * self.darkeningMag ^ darkening, 0, 0);

            if i == 1 and isFirst then
                love.graphics.draw(self.topMesh, 0, self.h * (yMag - 1));
            else
                love.graphics.rectangle("fill", self.x, self.y + self.h * (yMag - 1), self.w, self.h);
            end

            love.graphics.setColor(1,1,1); -- white
            love.graphics.print(v.data.name or "", self.x + 2 * self.edgeScale, self.y + self.h * (yMag - 1) + self.edgeScale, 0, textScale);
            love.graphics.draw(self.arrowMesh, self.x + self.w - self.h / 2 - 2 * self.edgeScale, self.y + self.h * (yMag - 0.5) - self.edgeScale, math.pi / 2, self.h - 6 * self.edgeScale);

            yMag = self:drawMap(false, isLast and i == #curTbl, v.data, darkening, yMag);
            darkening = darkening - 1;
        elseif v.canOpen then
            love.graphics.setColor(1 * self.darkeningMag ^ darkening, 0, 0);

            if i == 1 and isFirst then
                love.graphics.draw(self.topMesh, 0, self.h * (yMag - 1));
            elseif i == #curTbl and isLast then
                love.graphics.draw(self.bottomMesh, 0, self.h * (yMag - 1));
            else
                love.graphics.rectangle("fill", self.x, self.y + self.h * (yMag - 1), self.w, self.h);
            end

            love.graphics.setColor(1,1,1); -- white
            love.graphics.print(v.data.name or "", self.x + 2 * self.edgeScale, self.y + self.h * (yMag - 1) + self.edgeScale, 0, textScale);
            love.graphics.draw(self.arrowMesh, self.x + self.w - self.h / 2 - 2 * self.edgeScale, self.y + self.h * (yMag - 0.5) - self.edgeScale, 0, self.h - 6 * self.edgeScale);
        else
            love.graphics.setColor(1 * self.darkeningMag ^ darkening, 0, 0);

            if i == 1 and isFirst then
                love.graphics.draw(self.topMesh, 0, self.h * (yMag - 1));
            elseif i == #curTbl and isLast then
                love.graphics.draw(self.bottomMesh, 0, self.h * (yMag - 1));
            else
                love.graphics.rectangle("fill", self.x, self.y + self.h * (yMag - 1), self.w, self.h);
            end

            love.graphics.setColor(1,1,1); -- white
            love.graphics.print(v.data or "", self.x + 2 * self.edgeScale, self.y + self.h * (yMag - 1) + self.edgeScale, 0, textScale);
        end
    end

    return yMag;
end

function Accordion:draw()
    love.graphics.setColor(1,0,0); -- red
    love.graphics.setFont(PIXEL_FONT_128);
    self:drawMap(true, true);
end

return Accordion;