local DepthDrawing = {}; -- not a class
local self = DepthDrawing; -- for readability, does not affect anything outside of this script

function DepthDrawing.init()
    -- target dimmensions for screen
    self.targetWidth  = 1920;
    self.targetHeight = 1080;

    -- width and height of the window
    local w = love.graphics.getWidth();
    local h = love.graphics.getHeight();

    print(h);

    SimpleShader.setRealDimensions(w, h);

    self.isActive = false;

    self.render = love.graphics.newCanvas(w, h); -- final frame

    self.errorDrawCalls = true;
    self.transformOrigin = false; -- whether or not to apply transformations whenever love.graphics.origin() is called

    local function drawCallErroring() -- cause dra calls to error when we want it to
        if not self.isActive then -- if not enabled then ignore everything related to it
            return;
        end

        --assert(self.errorDrawCalls == false, "tried to call a draw call outside of a DepthDrawing use, call DepthDrawing.startDrawingAtDepth() or use the DepthDrawing. [draw callback] ()");
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

    LoveAffix.makeFunctionInjectable("graphics", "setCanvas");

    LoveAffix.injectCodeIntoLove(
        function(canv)
            if self.isActive then
                if canv then
                    self.errorDrawCalls = false;
                else
                    self.errorDrawCalls = true;
                end

                return canv or self.render;
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

    return self; -- allow: DepthDrawing = require("depthDrawing").init();
end

function DepthDrawing.setDimensions(w, h) -- update canvases and transformations
    self.render = love.graphics.newCanvas(w, h);

    SimpleShader.setRealDimensions(w, h);

    return self.targetWidth, self.targetHeight; -- fake :3 (aaahhhhh im going fucking crazy)
end

function DepthDrawing.clear()
    love.graphics.setCanvas(self.render);
    love.graphics.clear();
    love.graphics.setCanvas();
end

function DepthDrawing.startDraw()
    -- make calling love.graphics.origin() not mess up the desired centering and scaling of the universe
    self.transformOrigin = true;
    self.errorDrawCalls = false;

    SimpleShader.reapplyShader();

    self.isActive = true;

    love.graphics.setCanvas(self.currentLayer);
    love.graphics.clear();
end

function DepthDrawing.stopDraw()
    -- make calling love.graphics.origin() ignore the previous centering and scaling of the universe

    self.transformOrigin = false;

    self.isActive = false;

    -- draw the currentLayer canvas to the final render target with depth
    love.graphics.setCanvas(); -- not active so it is actually window
    love.graphics.setShader();

    love.graphics.origin();
    love.graphics.setColor(1,1,1,1);

    love.graphics.draw(self.render);

    self.errorDrawCalls = true; -- error draw calls since theyre not done in the DepthDrawing
end

return DepthDrawing;
