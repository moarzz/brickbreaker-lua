local WindowCorrector = {}; -- not a class
local self = WindowCorrector; -- for readability, does not affect anything outside of this script

local defaultCanvasCount = 3;

function WindowCorrector.init(canvasCount)
    -- target dimmensions for screen
    self.targetWidth  = 1920;
    self.targetHeight = 1080;

    -- width and height of the window
    local w = love.graphics.getWidth();
    local h = love.graphics.getHeight();

    self.realWidth = w;
    self.realHeight = h;

    print(h);

    SimpleShader.setRealDimensions(w, h);

    self.isActive = false;

    --self.render = love.graphics.newCanvas(w, h); -- final frame

    self.canvases = {};

    for i = 1, (canvasCount or defaultCanvasCount) + 1 do
        self.canvases[i] = love.graphics.newCanvas(w, h);
    end

    self.errorDrawCalls = true;
    self.transformOrigin = false; -- whether or not to apply transformations whenever love.graphics.origin() is called

    local function drawCallErroring() -- cause dra calls to error when we want it to
        if not self.isActive then -- if not enabled then ignore everything related to it
            return;
        end

        --assert(self.errorDrawCalls == false, "tried to call a draw call outside of a WindowCorrector use, call WindowCorrector.startDrawingAtDepth() or use the WindowCorrector. [draw callback] ()");
    end
    local function mouseGetPositionAppend(x, y)
        return SimpleShader.screenPointToWorldPoint(x, y);
    end
    local function mouseGetXAppend(x)
        return (SimpleShader.screenPointToWorldPoint(x, 0));
    end
    local function mouseGetYAppend(y)
        local _, _y = SimpleShader.screenPointToWorldPoint(0, y);

        return _y;
    end
    local function mousemovedInject(x, y, dx, dy, istouch)
        x,  y  = SimpleShader.screenPointToWorldPoint(x,  y);
        dx, dy = SimpleShader.screenDeltaToWorldDelta(dx, dy);

        return x, y, dx, dy, istouch;
    end
    local function mousepressedInject(x, y, button, istouch, presses)
        x, y = SimpleShader.screenPointToWorldPoint(x, y);

        return x, y, button, istouch, presses;
    end
    local function feignScreenWidth()
        return self.targetWidth;
    end
    local function feignScreenHeight()
        return self.targetHeight;
    end
    local function feignScreenDimmensions()
        return self.targetWidth, self.targetHeight;
    end
    local prevFullScreen = love.window.setFullscreen;
    local function setFullscreen(...)
        local canv = love.graphics.getCanvas();
        local prevActive = self.isActive;
        self.isActive = false;
        love.graphics.setCanvas();

        prevFullScreen(...);

        self.isActive = prevActive;
        love.graphics.setCanvas(canv);
    end

    LoveAffix.makeFunctionInjectable("graphics", "setCanvas");

    LoveAffix.injectCodeIntoLove(
        function(canv)
            if self.isActive then
                if canv then
                    self.errorDrawCalls = false;
                else
                    self.errorDrawCalls = true;
                end

                return canv or self.canvases[1];
            end
        end,
        "graphics",
        "setCanvas"
    );

    LoveAffix.makeFunctionInjectable("graphics", "arc");
    LoveAffix.makeFunctionInjectable("graphics", "circle");
    LoveAffix.makeFunctionInjectable("graphics", "draw");
    LoveAffix.makeFunctionInjectable("graphics", "drawInstanced");
    LoveAffix.makeFunctionInjectable("graphics", "drawLayer");
    LoveAffix.makeFunctionInjectable("graphics", "ellipse");
    LoveAffix.makeFunctionInjectable("graphics", "line");
    LoveAffix.makeFunctionInjectable("graphics", "points");
    LoveAffix.makeFunctionInjectable("graphics", "polygon");
    LoveAffix.makeFunctionInjectable("graphics", "print");
    LoveAffix.makeFunctionInjectable("graphics", "printf");
    LoveAffix.makeFunctionInjectable("graphics", "rectangle");
    LoveAffix.makeFunctionInjectable("mouse", "getPosition");
    LoveAffix.makeFunctionInjectable("mouse", "getX");
    LoveAffix.makeFunctionInjectable("mouse", "getY");
    LoveAffix.makeFunctionInjectable("mousemoved");
    LoveAffix.makeFunctionInjectable("mousepressed");
    LoveAffix.makeFunctionInjectable("mousereleased");
    LoveAffix.makeFunctionInjectable("draw");
    LoveAffix.makeFunctionInjectable("graphics", "getWidth");
    LoveAffix.makeFunctionInjectable("graphics", "getHeight");
    LoveAffix.makeFunctionInjectable("graphics", "getDimensions");
    LoveAffix.makeFunctionInjectable("window", "setFullscreen");

    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "arc");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "circle");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "draw");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "drawInstanced");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "drawLayer");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "ellipse");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "line");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "points");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "polygon");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "print");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "printf");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "rectangle");
    LoveAffix.appendCodeIntoLove(mouseGetPositionAppend, "mouse", "getPosition");
    LoveAffix.appendCodeIntoLove(mouseGetXAppend, "mouse", "getX");
    LoveAffix.appendCodeIntoLove(mouseGetYAppend, "mouse", "getY");
    LoveAffix.injectCodeIntoLove(mousemovedInject, "mousemoved");
    LoveAffix.injectCodeIntoLove(mousepressedInject, "mousepressed");
    LoveAffix.injectCodeIntoLove(mousepressedInject, "mousereleased");
    LoveAffix.injectCodeIntoLove(self.startDraw, "draw");
    LoveAffix.appendCodeIntoLove(self.stopDraw, "draw");
    LoveAffix.appendCodeIntoLove(feignScreenWidth, "graphics", "getWidth");
    LoveAffix.appendCodeIntoLove(feignScreenHeight, "graphics", "getHeight");
    LoveAffix.appendCodeIntoLove(feignScreenDimmensions, "graphics", "getDimensions");
    LoveAffix.replaceFunctionInLove(setFullscreen, "window", "setFullscreen");

    -- if an error occurs then dont cause a force quit for the entire application before the error screen can be drawn
    LoveAffix.makeFunctionInjectable("errorhandler");
    LoveAffix.injectCodeIntoLove(
       function()
           self.transformOrigin = false;
           self.errorDrawCalls = false;
       end,
       "errorhandler"
    );

    -- have this script be notified of whenever the window is resized
    LoveAffix.makeFunctionInjectable("resize");
    LoveAffix.injectCodeIntoLove(self.setDimensions, "resize");

    SimpleShader.setTargetDimensions(self.targetWidth, self.targetHeight); -- just to make sure they line up :3

    return self; -- allow: WindowCorrector = require("depthDrawing").init();
end

function WindowCorrector.setCanvasCount(cnt)
    if cnt + 1 < #self.canvases then
        for i = cnt + 1, #self.canvases do
            self.canvases[i]:release();
            self.canvases[i] = nil;
        end
    else
        for i = #self.canvases, cnt + 1 do
            self.canvases[i] = love.graphics.newCanvas(self.realWidth, self.realHeight);
        end
    end
end

function WindowCorrector.setDimensions(w, h) -- update canvases and transformations
    for i, v in ipairs(self.canvases) do
        v:release();

        self.canvases[i] = love.graphics.newCanvas(w, h);
    end

    SimpleShader.setRealDimensions(w, h);

    return self.targetWidth, self.targetHeight; -- fake :3 (aaahhhhh im going fucking crazy)
end

function WindowCorrector.clear()
    for i, v in ipairs(self.canvases) do
        love.graphics.setCanvas(v);
        love.graphics.clear();
    end

    love.graphics.setCanvas();
end

function WindowCorrector.startDrawingToCanvas(index)
    assert(self.isActive, "tried to start drawing to a canvas while the windowCorrector is inactive");

    if not index then
        love.graphics.setCanvas(); -- main render target
        return;
    end

    index = index + 1;

    assert(index <= #self.canvases, "tried to begin drawing to an out of bounds canvas");

    love.graphics.setCanvas(self.canvases[index]);
end

function WindowCorrector.stopDrawingToCanvas()
    assert(self.isActive, "tried to stop drawing to a canvas while the windowCorrector is inactive");

    love.graphics.setCanvas();
end

--? draws canvas:index_2 onto canvas:index_1
function WindowCorrector.mergeCanvases(index_1, index_2)
    assert(self.isActive, "tried to merge a canvas while the windowCorrector is inactive");

    if not index_2 then -- merge one canvas to the main render target
        self.mergeCanvas(index_1);
        return;
    end

    index_1 = index_1 + 1;
    index_2 = index_2 + 1;

    assert(index_1 <= #self.canvases and index_2 <= #self.canvases, "tried to merge an out of bounds canvas");

    local curCanvas = love.graphics.getCanvas();

    love.graphics.setCanvas(self.canvases[index_1]);

    self.transformOrigin = false;
    SimpleShader.reapplyShader();

    love.graphics.push();
    love.graphics.origin();

    love.graphics.draw(self.canvases[index_2]);

    love.graphics.pop();

    self.transformOrigin = true;
    SimpleShader.reapplyShader();

    love.graphics.setCanvas(curCanvas);
end

function WindowCorrector.mergeCanvas(index)
    assert(self.isActive, "tried to merge a canvas while the windowCorrector is inactive");

    index = index + 1;

    assert(index <= #self.canvases, "tried to merge an out of bounds canvas");

    local curCanvas = love.graphics.getCanvas();

    love.graphics.setCanvas();

    self.transformOrigin = false;
    SimpleShader.reapplyShader();

    love.graphics.push();
    love.graphics.origin();

    love.graphics.draw(self.canvases[index]);

    love.graphics.pop();

    self.transformOrigin = true;
    SimpleShader.reapplyShader();

    love.graphics.setCanvas(curCanvas);
end

function WindowCorrector.mergeRenderToCanvas(index)
    assert(self.isActive, "tried to merge a canvas while the windowCorrector is inactive");

    index = index + 1;

    assert(index <= #self.canvases, "tried to merge an out of bounds canvas");

    local curCanvas = love.graphics.getCanvas();

    love.graphics.setCanvas(self.canvases[index]);

    self.transformOrigin = false;
    SimpleShader.reapplyShader();

    love.graphics.push();
    love.graphics.origin();

    love.graphics.draw(self.canvases[1]);

    love.graphics.pop();

    self.transformOrigin = true;
    SimpleShader.reapplyShader();

    love.graphics.setCanvas(curCanvas);
end

function WindowCorrector.swapCanvases(index_1, index_2)
    assert(self.isActive, "tried to swap a canvas while the windowCorrector is inactive");

    if not index_2 then -- merge one canvas to the main render target
        self.swapRenderAndCanvas(index_1);
        return;
    end

    index_1 = index_1 + 1;
    index_2 = index_2 + 1;

    assert(index_1 <= #self.canvases and index_2 <= #self.canvases, "tried to swap an out of bounds canvas");

    self.canvases[index_1], self.canvases[index_2] = self.canvases[index_2], self.canvases[index_1];

    if love.graphics.getCanvas() == self.canvases[index_1] then
        love.graphics.setCanvas(self.canvases[index_2]);
    elseif love.graphics.getCanvas() == self.canvases[index_2] then
        love.graphics.setCanvas(self.canvases[index_1]);
    end
end

function WindowCorrector.swapRenderAndCanvas(index)
    assert(self.isActive, "tried to swap a canvas while the windowCorrector is inactive");

    index = index + 1;

    assert(index <= #self.canvases, "tried to swap an out of bounds canvas");

    self.canvases[index], self.canvases[1] = self.canvases[1], self.canvases[index];

    if love.graphics.getCanvas() == self.canvases[index] then
        love.graphics.setCanvas(self.canvases[1]);
    elseif love.graphics.getCanvas() == self.canvases[1] then
        love.graphics.setCanvas(self.canvases[index]);
    end
end

function WindowCorrector.clearCanvas(index)
    assert(self.isActive, "tried to clear a canvas while the windowCorrector is inactive");

    index = index + 1;

    assert(index <= #self.canvases, "tried to clear an out of bounds canvas");

    local curCanvas = love.graphics.getCanvas();

    love.graphics.setCanvas(self.canvases[index]);
    love.graphics.clear();

    love.graphics.setCanvas(curCanvas);
end

function WindowCorrector.getCanvas(index)
    assert(self.isActive, "tried to clear a canvas while the windowCorrector is inactive");

    index = index + 1;

    assert(index <= #self.canvases, "tried to clear an out of bounds canvas");

    return self.canvases[index];
end

function WindowCorrector.startDraw()
    -- make calling love.graphics.origin() not mess up the desired centering and scaling of the universe
    self.transformOrigin = true;
    self.errorDrawCalls = false;

    SimpleShader.reapplyShader();

    self.isActive = true;

    love.graphics.setCanvas();
    self.clear();
end

function WindowCorrector.stopDraw()
    -- make calling love.graphics.origin() ignore the previous centering and scaling of the universe

    self.transformOrigin = false;

    self.isActive = false;

    -- draw the currentLayer canvas to the final render target with depth
    love.graphics.setCanvas(); -- not active so it is actually window
    love.graphics.setShader();

    love.graphics.origin();
    love.graphics.setColor(1,1,1,1);

    love.graphics.draw(self.canvases[1]);

    self.errorDrawCalls = true; -- error draw calls since theyre not done in the WindowCorrector
end

return WindowCorrector;
