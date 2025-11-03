--! does not modulo the time value, so if you play for like several days then the visual may get jittery along the time axis

local BackgroundShader = {};
local self = BackgroundShader; -- for redability, doesnt affect anything outside of this script

function BackgroundShader.init()
    -- shader internals
    self.time = 0;
    self.intensity = 0;
    self.brightness = 0;

    self.shaders = {
        love.graphics.newShader("vexel", "Shaders/vexel.frag");
        love.graphics.newShader("acid", "Shaders/acid.frag");
        love.graphics.newShader("hexagons", "Shaders/hexagons.frag");
        love.graphics.newShader("blackhole", "Shaders/blackhole.frag");
    };

    self.indices = {
        ["vexel"] = 1;
        ["acid"] = 2;
        ["hexagons"] = 3;
        ["blackhole"] = 4;
    };

    self.fadeInOutShader = love.graphics.newShader("fadeInOut", "Shaders/fadeInOut.frag");

    self.activeShader = 4; -- index to the current shader
    self.prevActiveShader = 0; -- index to the previous shader (for fading)

    self.fadePerun = 1; -- perun from prevActiveShader to activeShader
    self.timePerFade = 3; -- amount of seconds it takes to fade
end

function BackgroundShader.update(dt)
    self.time = self.time + dt;

    -- gotta love the non dt based timing functions
    local reductionRate = 0.01 * (self.brightness * 2); -- Scales from 0.01 to 0.03 based on intensity
    self.setBrightness(math.max(0, self.brightness - reductionRate));

    self.setIntensity(Player.score <= 100 and mapRangeClamped(Player.score,1,100, 0.0, 0.15) or (Player.score <= 5000 and mapRangeClamped(Player.score, 100, 5000, 0.15, 0.5) or mapRangeClamped(Player.score, 5000, 100000, 0.5, 1.0)));

    if self.fadePerun < 1 then
        self.fadePerun = math.min(1, self.fadePerun + dt / self.timePerFade);
    end
end

function BackgroundShader.changeShader(toShader)
    if self.fadePerun < 1 then
        return;
    end

    if toShader == self.activeShader then
        return;
    end

    if toShader < 1 or toShader > 3 then
        return;
    end

    self.prevActiveShader = self.activeShader;
    self.activeShader = toShader;
    self.fadePerun = 0;
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
function BackgroundShader.setFinalMult(newFinalMult)
    self.finalMult = newFinalMult;

    for _, v in ipairs(self.shaders) do
        v:send("finalMult", newFinalMult);
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

        self.fadeInOutShader:send("fade", self.fadePerun);
        self.fadeInOutShader:send("fadeOut", WindowCorrector.getCanvas(1));

        love.graphics.setShader(self.fadeInOutShader);
        WindowCorrector.mergeCanvas(2);

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

BackgroundShader.init();
return BackgroundShader;