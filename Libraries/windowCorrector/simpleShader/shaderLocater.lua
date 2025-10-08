--! this script is used as a faster bridge for moving to this library.
--! instead of returning a string as the name and needing to use the simpleShader's
--! functions to modify the shaders, we are returning this object so that you can
--! directly call :send and :hasUniform on it directly. This only really just
--! saves time on moving an active project to utilize this library, and the
--! SimpleShader main file has a toggleable value to just return a string
--! since its faster to do that.

local ShaderLocater = {}; -- this IS a class
ShaderLocater.__index = ShaderLocater;

function ShaderLocater.new(name)
    local instance = setmetatable({}, ShaderLocater);

    instance.name = name;

    return instance;
end

function ShaderLocater:send(...)
    SimpleShader.send(self.name, ...);
end

-- not adding support for Shader:sendColor because its just :send()

function ShaderLocater:hasUniform(...)
    return SimpleShader.hasUniform(self.name, ...); --! not a function yet
end

return ShaderLocater;
