local path = string.match((...), "^.+[./]") or ""; -- get file path
path = string.gsub(path, "%.", "/"); -- prevent periods from fucking up getDirectoryItems()

local ComponentHandler = {};
local self = ComponentHandler; -- for ease of coding (no effect on anything outside of this script)

-- a nice font I like, monospace for easier coding with it, sized to 128 so it doesnt look blurry at larger scales
--_G.MONOSPACE_128 = love.graphics.newFont(path .. "SpaceMono.ttf", 128);
--_G.MONOSPACE_HEIGHT = MONOSPACE_128:getHeight("|");

-- gets called at end of this script, keeps users code slightly cleaner
function ComponentHandler.init()
    self.components = {}; -- list of all active components

    self.activeScene = nil; -- pointer to the active scene; nil if no scene is active
    self.activeComponent = nil; -- pointer to the active component; nil if no component is active
    self.hovering = nil; -- pointer to component being hovered over; nil if no component is being hovered over
    self.hoverTimer = 0; -- how long the hovered component has been hovered over without moving the cursor, in seconds

    self.hoverWait = 1.3; -- amount of seconds cursor needs to be idle hovering a component for a label to display
    --self.font = love.graphics.newFont(path .. "SpaceMono.ttf", 128);

    _G.Component = require(path .. "component"); -- globalize the "Component" script

    -- globalize callbacks to component creation
    print("-----------------------------------------------------------------------------------------------------------");
    print("**ALL** code in this ui library is written by me (any borrowed code is credited in comments surrounding it)\n");
    print("loading ui elements:");
    for i, v in ipairs(love.filesystem.getDirectoryItems(path .. "components")) do
        if string.find(v, "%.lua$") then
            local globalName = string.upper(string.sub(v, 1, 1)) .. string.sub(v, 2, -5);
            local scriptPath = path .. "components/" .. string.sub(v, 1, -5);

            print("\t" .. globalName);

            -- create callable of name to create a new object of that type in global space
            _G[globalName] = require(scriptPath).new;
        end
    end
    print("\nall ui elements loaded!");
    print("-----------------------------------------------------------------------------------------------------------\n\n\n");

    LoveAffix.makeFunctionInjectable("mousemoved");
    LoveAffix.makeFunctionInjectable("mousepressed");
    LoveAffix.makeFunctionInjectable("mousereleased");
    LoveAffix.makeFunctionInjectable("wheelmoved");
    LoveAffix.makeFunctionInjectable("keypressed");
    LoveAffix.makeFunctionInjectable("keyreleased");
    LoveAffix.makeFunctionInjectable("textinput");

    LoveAffix.appendCodeIntoLove(self.mousemoved, "mousemoved");
    LoveAffix.appendCodeIntoLove(self.mousepressed, "mousepressed");
    LoveAffix.appendCodeIntoLove(self.mousereleased, "mousereleased");
    LoveAffix.appendCodeIntoLove(self.wheelmoved, "wheelmoved");
    LoveAffix.appendCodeIntoLove(self.keypressed, "keypressed");
    LoveAffix.appendCodeIntoLove(self.keyreleased, "keyreleased");
    LoveAffix.appendCodeIntoLove(self.textinput, "textinput");
end

-- adds component to the active components, returns the component
function ComponentHandler.addComponent(component)
    table.insert(self.components, component);

    return component; -- ease of coding outside of this script
end

-- love callbacks of user inputs
function ComponentHandler.mousemoved(x, y, dx, dy, istouch)
    --x,  y  = DepthTester.getWorldPointFromScreenPoint(x,  y);
    --dx, dy = DepthTester.getWorldDeltaFromScreenDelta(dx, dy);
    --love.mouse.setCursor(love.mouse.getSystemCursor("arrow"));

    self.hoverTimer = 0; -- reset hovering timer

    local skip = false;

    if self.activeComponent then
        self.recurseTriggerCall(self.activeComponent, "onMousemoved", x, y, dx, dy);

        if self.activeComponent:isInAnyBoundingBox(x, y) then
            --love.mouse.setCursor(love.mouse.getSystemCursor("hand"));

            if not self.activeComponent.isHovering then
                self.recurseTriggerCall(self.activeComponent, "onHover", x, y);
            end

            self.recurseTriggerCall(self.activeComponent, "setIsHovering", true);

            self.hovering = self.activeComponent; -- set hovering component

            skip = true;
        else
            if self.activeComponent.isHovering then
                self.recurseTriggerCall(self.activeComponent, "unHover", x, y);
            end

            self.recurseTriggerCall(self.activeComponent, "setIsHovering", false);
        end
    end

    for _, v in ipairs(self.components) do
        if v ~= self.activeComponent then
            if skip then
                if v.isHovering then
                    self.recurseTriggerCall(v, "unHover", x, y);
                end

                self.recurseTriggerCall(v, "setIsHovering", false);
            else
                if v:isInAnyBoundingBox(x, y) then
                    --love.mouse.setCursor(love.mouse.getSystemCursor("hand"));

                    if not v.isHovering then
                        self.recurseTriggerCall(v, "onHover", x, y);
                    end

                    self.hovering = v; -- set hovering component

                    skip = true;
                else
                    if v.isHovering then
                        self.recurseTriggerCall(v, "unHover", x, y);
                    end

                    self.recurseTriggerCall(v, "setIsHovering", false);
                end
            end
        end
    end
end
function ComponentHandler.mousepressed(x, y, button, istouch, presses)
    --x, y = DepthTester.getWorldPointFromScreenPoint(x, y);

    if self.activeComponent then
        if self.activeComponent:isInAnyBoundingBox(x, y) then
            self.recurseTriggerCall(self.activeComponent, "onPress", x, y, button, presses);

            return;
        else
            self.recurseTriggerCall(self.activeComponent, "unFocus");

            self.activeComponent = nil;
        end
    end

    for _, v in ipairs(self.components) do
        if v ~= self.activeComponent then
            if v:isInAnyBoundingBox(x, y) then
                self.recurseTriggerCall(v, "onPress", x, y, button, presses);
                self.recurseTriggerCall(v, "onFocus")

                self.activeComponent = v;

                return;
            end
        end
    end
end
function ComponentHandler.mousereleased(x, y, button, istouch, presses)
    --x, y = DepthTester.getWorldPointFromScreenPoint(x, y);

    if not self.activeComponent then
        return;
    end

    self.recurseTriggerCall(self.activeComponent, "onRelease", x, y, button, presses);
end
function ComponentHandler.wheelmoved(x, y)
    -- do not perform the transformation done in other input functions here (transformation viewable in comment bellow)
    -- x, y = DepthTester.getWorldPointFromScreenPoint(x, y);
    -- because this is movement of the wheel which is not visible on the screen

    if self.activeComponent then
        if self.activeComponent.isHovering then
            self.recurseTriggerCall(self.activeComponent, "onWheel", x, y);
        end
    end

    for _, v in ipairs(self.components) do
        if v ~= self.activeComponent then
            if v.isHovering then
                self.recurseTriggerCall(v, "onWheel", x, y);
            end
        end
    end
end
function ComponentHandler.keypressed(key, scancode, isrepeat)
    if not self.activeComponent then
        return;
    end

    self.recurseTriggerCall(self.activeComponent, "onKeypress", key, scancode, isrepeat);
end
function ComponentHandler.keyreleased(key, scancode)
    if not self.activeComponent then
        return;
    end

    self.recurseTriggerCall(self.activeComponent, "onKeyrelease", key, scancode, isrepeat);
end
function ComponentHandler.textinput(text)
    if not self.activeComponent then
        return;
    end

    self.recurseTriggerCall(self.activeComponent, "onTextInput", text);
end

-- recursively call a given function within a component; and its triggers; and its triggers' triggers; and .etc
function ComponentHandler.recurseTriggerCall(component, callKey, ...) -- ellipses represents an unknown amount of inputs
    -- (this is a confusing and obscure lua thing see: https://www.lua.org/pil/5.2.html)

    if component[callKey] then
        component[callKey](component, ...); -- ellipses used as unknown amount of variables
    end

    for k, v in pairs(component.triggers) do
        if v[callKey] then
            self.recurseTriggerCall(v, callKey, ...);
        end
    end
end

-- returns true if the component was succesfully removed; otherwise false
function ComponentHandler.removeComponent(pointer_index)
    -- if removing component by index
    if type(pointer_index) == "number" then
        local removed = table.remove(self.components, pointer_index);

        if self.activeComponent == removed then
            self.activeComponent = nil;
        end

        return true;
    end

    for i, v in ipairs(self.components) do
        if v == pointer_index then
            table.remove(self.components, i);

            if self.activeComponent == pointer_index then
                self.activeComponent = nil;
            end

            return true;
        end
    end

    return false;
end

function ComponentHandler.removeAllComponents()
    self.components = {}; -- empty table
    self.activeComponent = nil;
end

function ComponentHandler.setActiveScene(scene)
    local prevScene = self.activeScene;

    if prevScene and prevScene ~= scene then
        prevScene:deactivate();
    end

    self.activeScene = scene;
end
function ComponentHandler.unsetActiveScene(scene)
    if scene then
        if self.activeScene ~= scene then
            return;
        end
    end

    local prevScene = self.activeScene;
    self.activeScene = nil;

    if prevScene then
        prevScene:deactivate();
    end
end

function ComponentHandler.update(dt)
    for i, v in ipairs(self.components) do
        self.recurseTriggerCall(v, "tick", dt);

        self.recurseTriggerCheck(v);
    end

    if self.hovering then
        self.hoverTimer = self.hoverTimer + dt;
    end

    if self.activeScene then
        if self.activeScene.update then
            self.activeScene:update(dt);
        end
    end
end

-- recursively check a component for its _trigger keyed function to return true; and its triggers; and its triggers' triggers; and .etc
function ComponentHandler.recurseTriggerCheck(component)
    for k, v in pairs(component.triggers) do
        self.recurseTriggerCheck(v);

        if v._trigger and component[k] then
            if v[v._trigger](v) then
                component[k](component, v);
            end
        end
    end
end

-- draw all interactible components
function ComponentHandler.draw()
    for i = #self.components, 1, -1 do
        if self.components[i] ~= self.activeComponent then
            self.components[i]:draw();
        end
    end

    if self.activeComponent then
        -- self.activeComponent:drawOutline(); -- draw the outline of all of the component's bounding boxes
        self.activeComponent:draw();
    end

    --[[if self.hovering and self.hoverTimer >= self.hoverWait and self.hovering._label then
        local textScale = 20 / PIXEL_FONT_HEIGHT;
        local mx, my = love.mouse.getPosition();

        love.graphics.setColor(0,0,0.15, 0.6); -- dark blue, slightly transparent
        love.graphics.rectangle("fill", mx, my - 20 - 2, PIXEL_FONT_128:getWidth(self.hovering._label) * textScale + 10, 22, 3,3);
        -- round corners a bit

        love.graphics.setFont(PIXEL_FONT_128);
        love.graphics.setColor(1,1,1); -- white
        love.graphics.print(self.hovering._label, mx + 5, my - 20 - 1, 0, textScale);
    end]]

    if self.activeScene then
        if self.activeScene.draw then
            self.activeScene:draw();
        end
    end
end

ComponentHandler.init(); -- load on require() to avoid needing to call .init in love.load
return ComponentHandler;