--! does not modulo the time value, so if you play for like several days then the visual may get jittery along the time axis

local BackgroundShader = {};
local self = BackgroundShader; -- for redability, doesnt affect anything outside of this script

function BackgroundShader.init()
    -- shader internals
    self.time = 0;
    self.intensity = 0;
    self.brightness = 0;

    self.shaders = {
        love.graphics.newShader("vexel.frag");
        love.graphics.newShader("acid.frag");
        love.graphics.newShader("hexagons.frag");
    };

    self.indices = {
        ["vexel"] = 1;
        ["acid"] = 2;
        ["hexagons"] = 3;
    };

    self.fadeInOutShader = love.graphics.newShader("fadeInOut.frag");

    self.activeShader = 1; -- index to the current shader
    self.prevActiveShader = 0; -- index to the previous shader (for fading)

    self.fadePerun = 1; -- perun from prevActiveShader to activeShader
    self.timePerFade = 3; -- amount of seconds it takes to fade
end

function BackgroundShader.update(dt)
    self.time = self.time + dt;

    if self.fadePerun < 1 then
        self.fadePerun = math.min(1, self.fadePerun + dt / self.timePerFade);
    end
end

function BackgroundShader.setIntensity(newIntensity)
    self.intensity = newIntensity;

    for _, v in ipairs(self.shaders) do
        v:send("intensity", newIntensity);
    end
end
function BackgroundShader.setBrightness(newBrightness)
    self.brightness = newBrightness;

    for _, v in ipairs(self.shaders) do
        v:send("brightness", newBrightness);
    end
end

function BackgroundShader.draw()
    if self.fadePerun < 1 then
        self.shaders[self.prevActiveShader]:send("time", self.time);
        self.shaders[self.activeShader]:send("time", self.time);

        -- all canvases should be blank at this time so it doesnt matter which canvas we use
        -- as long as we clear it afterwards
        -- WindowCorrector.startDrawingToCanvas(1);
        love.graphics.setShader(self.shaders[self.prevActiveShader]);
        WindowCorrector.mergeCanvases(1, 2);
        love.graphics.setShader(self.shaders[self.activeShader]);
        WindowCorrector.mergeCanvases(2, 3);

        love.graphics.setBlendMode("add");
        -- love.graphics.setCanvas(); -- main render target

        self.fadeInOutShader:send("fade", self.fadePerun);

        self.fadeInOutShader:send("fadeIn", true);
        love.graphics.setShader(self.fadeInOutShader);
        WindowCorrector.mergeCanvas(2);

        love.graphics.setShader();

        self.fadeInOutShader:send("fadeIn", false);
        love.graphics.setShader(self.fadeInOutShader);
        WindowCorrector.mergeCanvas(1);

        love.graphics.setBlendMode("alpha"); -- normal blend mode
        love.graphics.setShader();

        WindowCorrector.clearCanvas(1);
        WindowCorrector.clearCanvas(2);
    else
        self.shaders[self.activeShader]:send("time", self.time);

        love.graphics.setShader(self.shaders[self.activeShader]);
        WindowCorrector.mergeCanvas(1);

        love.graphics.setShader();
    end
end

return BackgroundShader;