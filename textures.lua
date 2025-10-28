local lily = require('lily')

local Textures = {}

local textures = {
    ['no_texture'] = love.graphics.newImage('assets/sprites/no_texture.png')
}

textures['no_texture']:setFilter('nearest', 'nearest')

function Textures.getTexture(name, nearestNeighbor, urgent)
    if urgent then
        if textures[name] and textures[name] ~= 'l' then
            return textures[name]
        end

        if love.filesystem.getInfo(name .. '.png') then
            textures[name] = love.graphics.newImage(name .. '.png')
        else
            textures[name] = love.graphics.newImage(name .. '.png')
        end

        if nearestNeighbor then
            textures[name]:setFilter('nearest', 'nearest')
        end

        return textures[name]
    end

    if textures[name] then
        if textures[name] == 'l' then
            return textures['no_texture'], true
        end

        return textures[name], false
    end

    if love.filesystem.getInfo(name .. '.png') then
        textures[name] = 'l'
        local completed = function(userdata, image)
            textures[name] = image

            if nearestNeighbor then
                image:setFilter('nearest', 'nearest')
            end
        end

        lily.newImage(name .. '.png'):onComplete(completed)

        --textures[name] = love.graphics.newImage(name .. '.png')
    else
        textures[name] = 'l'
        local completed = function(userdata, image)
            textures[name] = image

            if nearestNeighbor then
                image:setFilter('nearest', 'nearest')
            end
        end

        lily.newImage(name .. '.png'):onComplete(completed)
        --textures[name] = love.graphics.newImage(name .. '.png')
    end

    return textures['no_texture'], true
end

function Textures.unloadTextures(...)
    local args = {...}

    for i, v in ipairs(args) do
        if textures[v] and textures[v] ~= 'l' then
            textures[v]:release()
            textures[v] = nil
        end
    end
end

function Textures.loadTextures(...)
    local args = {...}

    for i, v in ipairs(args) do
        if not textures[v] then
            if love.filesystem.getInfo(v .. '.png') then
                textures[v] = love.graphics.newImage(v .. '.png')
            else
                textures[v] = love.graphics.newImage(v .. '.png')
            end
        end
    end
end

function Textures.unloadTexture(name)
    textures[name]:release()
    textures[name] = nil
end

return Textures