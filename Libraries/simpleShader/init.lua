--! this script only works in tandem w/ WindowCorrector.lua

--! this script contains chunks of code used in other scripts; as strings
--! therefore this script looks ass and should not be judged on that aspect of it
--! it is quite well layed out, dynamic, and functional. So it is better than it looks like
--! in addition to this, it's at a state where it is nearly maximally 'never nested'
--! it still reaches quite far but this is because less indentation is not worth linear readability
--! so functions that are kept inside of a call are declared there aswell

local returnStrings = false;
--? true to return a string, false to return a shaderLocater object
--? the difference is that ShaderLocater object is slower but you can call :send() and :hasUniform()
--? on it directly (like with a normal love.graphics.newShader() call)

local path = (...);

local ShaderLocater = returnStrings or require(path .. ".shaderLocater");

local SimpleShader = {}; -- not a class
local self = SimpleShader; -- for readability

function SimpleShader.init()
    self.allShaders = {}; -- list of all shaders, unmodified
    self.allShadersWithVert = {}; -- list of all shaders, modified for the depth tester

    self.targetWidth = 1920;
    self.targetHeight = 1080;

    -- no I did not think to make a variable for it beforehand, this is only after discovering that I commonly misspell
    -- "dimensions" as "dimmensions" about 50% of the time
    self.nameOfVariable = "targetDimensions";

    self.activeShader = nil; -- key or nil

    self.defaultShader = love.graphics.newShader(self.getDefaultPixelCode(), self.getDefaultVertexCode()); -- just the vertex shader
    self.defaultShader:send(self.nameOfVariable, {self.targetWidth, self.targetHeight});

    local function newShaderFunction(name, pixelCode, vertexCode)
        assert(name and pixelCode, "tried to create a shader with invalid info, now you need: name, pixelCode, [vertexCode]");
        assert(love.filesystem.getInfo(name) == nil, "tried to create a shader with the name of a valid file '" .. name .. "' with invalid info, now you need: name, pixelCode, [vertexCode]");
        assert(string.len(name) <= 25, "tried to create a shader with a name longer than 25 characters, this is not allowed, remember that the new arg format is: name, pixelCode, [vertexCode]");
        
        --! does not technically error if providing pixelCode and vertexCode as code and no name
        --! but only if pixelCode has less than 25 character, so very unlikely
        --! (and the outcome is that it only is a vertex shader, so not completely catastrophic)
        --? this is impossible to make a functioing shader in it so the user will have to be a fucking idiot
        --? to have it explode, but also users are known to be this stupid
        --? I have no solution for this :(

        -- no need to check allShadersWithVert since they should be identical
        assert(self.allShaders[name] == nil, "tried to create a shader that already exists: " .. name);

        if love.filesystem.getInfo(pixelCode) then -- it exists as a file, so assume it is
            pixelCode = love.filesystem.read(pixelCode);
        end

        if vertexCode and love.filesystem.getInfo(vertexCode) then -- it exists as a file, so assume it is
            vertexCode = love.filesystem.read(vertexCode);
        end

        --* by here pixelCode and vertexCode is the code itself; as a string, not a filename

        -- keep an unmodified version of the code, for creating the unmodified shader
        local unmodifiedPixelCode  = string.sub(pixelCode, 1, -1);
        local unmodifiedVertexCode = vertexCode and string.sub(vertexCode, 1, -1) or nil; -- ternary op

        local vertexPositionGSub = function(str)
            assert(
                string.match(str, "return .-;"),
                "couldnt fit regex 'return .-;' into the vertex code's 'vec4 position function' :" .. name
            );

            return string.gsub(str, "return (.-);", "return (%1) * vec4(vec2(min(love_ScreenSize.x / " .. self.nameOfVariable .. ".x, love_ScreenSize.y / " .. self.nameOfVariable .. ".y)), 1.0, 1.0) - vec4(0.5, 0.5, 0.0, 0.0);");
        end

        local pixelColourGSub = function(str)
            assert(
                string.match(str, "return .-;"),
                "couldnt fit regex 'return .-;' into the vertex code's 'vec4 effect function' :" .. name
            );

            return string.gsub(str, "return (.-);", "vec4 _ret_colour = %1; return _ret_colour.a == 0 ? _ret_colour : vec4(_ret_colour.rgb, 1.0);");
        end

        -- remove coments but dont change amount of line of code (to not mess up error codes)
        pixelCode = string.gsub(pixelCode, "//.-\n", "\n");
        pixelCode = string.gsub(pixelCode, "/%*.-%*/",
            function(str)
                return string.gsub(str, "[^\n]", ""); -- leave just the "\n"s
            end
        );

        if vertexCode then -- there is definitely vertex code since its specified
            -- remove coments but dont change amount of line of code (to not mess up error codes)
            vertexCode = string.gsub(vertexCode, "//.-\n", "\n");
            vertexCode = string.gsub(vertexCode, "/%*.-%*/",
                function(str)
                    return string.gsub(str, "[^\n]", ""); -- leave just the "\n"s
                end
            );

            assert(
                string.match(vertexCode, self.nameOfVariable) == nil,
                "cannot have vertex code contain the word '" .. self.nameOfVariable .. "' in any way (it interferes with the depth tester) :" .. name
            );

            -- no '\n' as to not mess up the error codes                  \n -> v
            vertexCode = "uniform vec2 " .. self.nameOfVariable .. ";" .. vertexCode;

            assert(
                string.match(vertexCode, "vec4%s*position%(.-%)[%s\n]-%b{}"),
                "couldnt fit regex 'vec4%s*position%(.-%)[%s\n]-%b{}' into vertex code, make sure it will encase your position function :" .. name
            );

            vertexCode = string.gsub(vertexCode, "vec4%s*position%(.-%)[%s\n]-%b{}", vertexPositionGSub);

            assert(
                string.match(pixelCode, "vec4%s*effect%(.-%)[%s\n]-%b{}"),
                "couldnt fit regex 'vec4%s*effect%(.-%)[%s\n]-%b{}' into pixel code, make sure it will encase your position function :" .. name
            );

            pixelCode = string.gsub(pixelCode, "vec4%s*effect%(.-%)[%s\n]-%b{}", pixelColourGSub);
        else -- vertex code may be inside of pixelCode, or not exist at all
            if string.match(pixelCode, "vec4%s*position") then -- if contains an internal vertex code then edit it as such
                assert(
                    string.match(pixelCode, self.nameOfVariable) == nil,
                    "cannot have vertex code contain the word '" .. self.nameOfVariable .. "' in any way (it interferes with the depth tester) :" .. name
                );

                -- no '\n' as to not mess up the error codes                  \n -> v
                pixelCode = "uniform vec2 " .. self.nameOfVariable .. ";" .. pixelCode;

                assert(
                    string.match(pixelCode, "vec4%s*position%(.-%)[%s\n]-%b{}"),
                    "couldnt fit regex 'vec4%s*position%(.-%)[%s\n]-%b{}' into vertex code, make sure it will encase your position function :" .. name
                );

                pixelCode = string.gsub(pixelCode, "vec4%s*position%(.-%)[%s\n]-%b{}", vertexPositionGSub);
            else -- if it doesnt have an internal vertex code, then give it some :3
                print("no vertex internal located for shader: " .. name);

                vertexCode = self.getDefaultVertexCode();
            end

            if string.match(pixelCode, "vec4%s*effect") then
                assert(
                    string.match(pixelCode, "vec4%s*effect%(.-%)[%s\n]-%b{}"),
                    "couldnt fit regex 'vec4%s*effect%(.-%)[%s\n]-%b{}' into pixel code, make sure it will encase your position function :" .. name
                );

                pixelCode = string.gsub(pixelCode, "vec4%s*effect%(.-%)[%s\n]-%b{}", pixelColourGSub);
            else
                pixelCode = pixelCode .. "\n" .. self.getDefaultPixelCode();
            end
        end

        local normalShader = self.newShader(unmodifiedPixelCode, unmodifiedVertexCode);
        local modifiedShader = self.newShader(pixelCode, vertexCode);

        modifiedShader:send(self.nameOfVariable, {self.targetWidth, self.targetHeight});

        self.allShaders[name] = normalShader;
        self.allShadersWithVert[name] = modifiedShader;

        return returnStrings and name or ShaderLocater.new(name);
    end

    local function setShaderInject(name)
        if type(name) == "table" then
            name = name.name;
        end

        assert(name == nil or self.allShaders[name], "tried to set a shader that does not exist: " .. (name or ""));

        self.activeShader = name; -- key or nil

        if name == nil then
            if WindowCorrector.transformOrigin then
                return self.defaultShader; -- default transformation shader
            end

            return; -- returns name (which is nil) so set shader to nothing
        end

        if WindowCorrector.transformOrigin then -- is the dethTester active?
            return self.allShadersWithVert[name]; -- modified shader
        end

        return self.allShaders[name]; -- unmodified shader
    end

    LoveAffix.makeFunctionInjectable("graphics", "newShader");
    LoveAffix.makeFunctionInjectable("graphics", "setShader");

    print("INFO: ensure that no love.graphics.newShader calls are made before here (other than the one utilized within this function itself)");
    self.newShader = LoveAffix.replaceFunctionInLove(newShaderFunction, "graphics", "newShader");
    LoveAffix.injectCodeIntoLove(setShaderInject, "graphics", "setShader");

    return self; -- allow for _G.SimpleShader = require().init();
end

function SimpleShader.getDefaultVertexCode()
    return [[
    uniform vec2 ]] .. self.nameOfVariable .. [[;

    vec4 position(mat4 transform_projection, vec4 vertex_position)
    {
        return (transform_projection * vertex_position) * vec4(vec2(min(love_ScreenSize.x / ]] .. self.nameOfVariable .. [[.x, love_ScreenSize.y / ]] .. self.nameOfVariable .. [[.y)), 1.0, 1.0) - vec4(0.5, 0.5, 0.0, 0.0);
    }]];-- + vec4(0.5, 0.5, 0.0, 0.0);
    -- dont just use a file since we could accidentally mess up the name of the variable (I h8 this too)
end
function SimpleShader.getDefaultPixelCode()
    return [[
    vec4 effect(vec4 colour, Image tex, vec2 textureCoords, vec2 screenCoords)
    {
        vec4 texturecolor = Texel(tex, textureCoords);
        vec4 _ret_colour = texturecolor * colour; return _ret_colour.a == 0 ? _ret_colour : vec4(_ret_colour.rgb, 1.0);
    }]];
    -- dont just use a file since we did this for the vertex code and we should keep it consistent
end

function SimpleShader.setTargetDimensions(w, h)
    -- if the values arent changing then dont do anything (this happens more than you'd think and does save a bunch of time)
    if w == self.targetWidth and h == self.targetHeight then
        return;
    end

    self.targetWidth = w; -- set traget dimmensions for shaders that get created in the future
    self.targetHeight = h;

    -- send the new dimensions to every shader
    for _, v in pairs(self.allShadersWithVert) do
        v:send(self.nameOfVariable, {w, h});
    end

    -- dont forget to change the default 'no shader' shader!
    self.defaultShader:send(self.nameOfVariable, {w, h});
end

function SimpleShader.screenPointToWorldPoint(x, y) -- a given coordinate on the screen
    --? this is what the worldPoint to screenPoint conversion looks like (we want the inverse of this)
    -- local scale = math.min(love.graphics.getWidth() / self.targetWidth, love.graphics.getHeight() / self.targetHeight);
    -- local retX = x * scale + love.graphics.getWidth() / 2;
    -- local retY = y * scale + love.graphics.getHeight() / 2;

    --? this is the inverse of the above formula
    local scale = math.min(love.graphics.getWidth() / self.targetWidth, love.graphics.getHeight() / self.targetHeight);
    local retX = (x - love.graphics.getWidth()  / 2) / scale;
    local retY = (y - love.graphics.getHeight() / 2) / scale;

    return retX, retY;
end
function SimpleShader.worldPointToScreenPoint(x, y)
    local scale = math.min(love.graphics.getWidth() / self.targetWidth, love.graphics.getHeight() / self.targetHeight);
    local retX = x * scale + love.graphics.getWidth() / 2;
    local retY = y * scale + love.graphics.getHeight() / 2;

    return retX, retY;
end

function SimpleShader.screenDeltaToWorldDelta(x, y)
    local scale = math.min(love.graphics.getWidth() / self.targetWidth, love.graphics.getHeight() / self.targetHeight);

    local retX = x / scale;
    local retY = y / scale;

    return retX, retY;
end
function SimpleShader.worldDeltaToScreenDelta(x, y) -- just for completeness (highly doubt this has any actual usage)
    local scale = math.min(love.graphics.getWidth() / self.targetWidth, love.graphics.getHeight() / self.targetHeight);

    local retX = x * scale;
    local retY = y * scale;

    return retX, retY;
end

function SimpleShader.getActiveShader()
    return self.activeShader;
end

function SimpleShader.reapplyShader() -- used for when depthTester enables / disables when a shader is active
    love.graphics.setShader(self.activeShader); -- our injected code will swap if its modified or not
end

function SimpleShader.send(name, uniform, ...)
    if type(name) == "table" then
        name = name.name;
    end

    assert(self.allShaders[name], "tried to send data to a shader that does not exist: " .. name);

    self.allShaders[name]:send(uniform, ...);
    self.allShadersWithVert[name]:send(uniform, ...);
end

function SimpleShader.hasUniform(name, uniform)
    if type(name) == "table" then
        name = name.name;
    end

    assert(self.allShaders[name], "tried to get uniform from a shader that does not exist: " .. name);

    self.allShaders[name]:hasUniform(uniform); -- use unmodified one to prevent problems
end


return SimpleShader;

