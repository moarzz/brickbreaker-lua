local Scene = {};
Scene.__index = Scene;

-- args: ([ui element], [ui element], [...])
function Scene.new(...)
    local instance = setmetatable({}, Scene);

    instance.elements = {...}; -- list of ui elements in this scene

    instance.isActive = false; -- if this scene is active

    -- callbacks
    instance.activateCallback = nil;
    instance.deactivateCallback = nil;

    return instance;
end

function Scene:setActivationCallback(func)
    self.activateCallback = func;
end
function Scene:setDeactivationCallback(func)
    self.deactivateCallback = func;
end

-- args: ([ui element], [ui element], [...])
function Scene:addElement(...)
    local args = {...};

    for _, v in ipairs(args) do
        table.insert(self.elements, v);
    end

    -- if scene is active then add new ui to the world
    if self.isActive then
        for _, v in ipairs(args) do
            ComponentHandler.addComponent(v);
        end
    end
end
Scene.addElements = Scene.addElement;

-- args: ([ui element], [ui element], [...])
function Scene:removeElement(...)
    local args = {...};

    if self.isActive then
        local crash = false;

        for i = #args, 1, -1 do
            local v = args[i];

            for j = #self.elements, 1, -1 do
                if self.elements[j] == v then
                    crash = crash or ComponentHandler.removeComponent(v);
                    table.remove(args, i);
                    table.remove(self.elements, j);
                end
            end
        end

        assert(not crash, "unsuccessfully tried to remove an element from the active scene");
    else
        for i = #args, 1, -1 do
            local v = args[i];

            for j = #self.elements, 1, -1 do
                if self.elements[j] == v then
                    table.remove(args, i);
                    table.remove(self.elements, j);
                end
            end
        end
    end
end
Scene.removeElements = Scene.removeElement;

function Scene:activate()
    assert(not self.isActive, "tried to activate a scene that was already active");

    self.isActive = true;

    ComponentHandler.setActiveScene(self);

    for _, v in ipairs(self.elements) do
        ComponentHandler.addComponent(v);
    end

    if self.activateCallback then
        self:activateCallback();
    end

    if self.onActivation then
        self:onActivation();
    end
end

function Scene:deactivate()
    if not self.isActive then
        return;
    end

    self.isActive = false;

    ComponentHandler.unsetActiveScene(self);

    for _, v in ipairs(self.elements) do
        ComponentHandler.removeComponent(v);
    end

    if self.deactivateCallback then
        self:deactivateCallback();
    end
end

return Scene;