local lily = require("lily");

local Textures = {};
local self = Textures; -- for readability

local LOADING = "l"; -- enum

local function insertTexture(name, nearestNeighbor)
    self.textures[name] = LOADING;

    return function(userdata, image)
        if self.textures[name] ~= LOADING then
            image:release();
            return;
        end

        self.textures[name] = image;

        if nearestNeighbor then
            image:setFilter("nearest", "nearest");
        end
    end
end

function Textures.init()
    self.textures = {};

    insertTexture("no_texture", true)(nil, love.graphics.newImage("assets/sprites/no_texture.png"));
end

function Textures.getTexture(name, nearestNeighbor, urgent)
    if urgent then
        if self.textures[name] and self.textures[name] ~= LOADING then
            return self.textures[name];
        end

        insertTexture(name, nearestNeighbor)(nil, love.graphics.newImage(name .. ".png"));

        return self.textures[name];
    end

    if self.textures[name] then
        if self.textures[name] == LOADING then
            return self.textures["no_texture"], true;
        end

        return self.textures[name];
    end

    lily.newImage(name .. ".png"):onComplete(insertTexture(name, nearestNeighbor));

    return self.textures["no_texture"], true;
end

function Textures.unloadTextures(...)
    local args = {...};

    for _, v in ipairs(args) do
        if self.textures[v] then
            if self.textures[v] == LOADING then
                self.textures[v] = nil;
            else
                self.textures[v]:release();
                self.textures[v] = nil;
            end
        end
    end
end

-- [nearest neighbor], tex1, tex2, ...
function Textures.loadTextures(...)
    local args = {...};
    local nearestNeighbor = type(args[1]) == "bool" and table.remove(args, 1);

    for _, v in ipairs(args) do
        if not self.textures[v] then
            lily.newImage(v .. ".png"):onComplete(insertTexture(v, nearestNeighbor));
        end
    end
end

function Textures.unloadTexture(name)
    if not self.textures[name] then
        return;
    end

    if self.textures[name] == LOADING then
        self.textures[name] = nil;
        return;
    end

    self.textures[name]:release();
    self.textures[name] = nil;
end

Textures.init(); -- call init on require
return Textures;