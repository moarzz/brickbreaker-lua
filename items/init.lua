--! picky core does not work


local path = (...); -- what is the folder this is located in?
path = string.gsub(path, "%.", "/"); -- prevent issues w/ love.filesystem.getDirectoryItems()

local Items = {};
local self = Items; -- for convenience

local validWeaponTypes = {
    ["ball"] = true;
    ["spell"] = true;
    ["tech"] = true;
    ["gun"] = true;
};

function Items.load()
    _G.ItemBase = require(path .. ".itemBase");
    _G.WeaponBase = require(path .. ".weaponBase");
    _G.Trail = require("trail");
    _G.WeaponEntity = require(path .. ".weaponEntity");
    _G.WeaponHandler = require(path .. ".weaponHandler");

    self.allItems = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    }; -- list always containing all modifiers (table keyed of tables of modifiers as rarities)
    self.allConsumables = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    };
    self.allWeapons = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    };

    self.itemsVisible = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    }; -- list containing all modifiers attainable in the shop (table keyed of tables of modifiers as rarities)
    self.consumablesVisible = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    };
    self.weaponsVisible = {
        ["common"]    = {};
        ["uncommon"]  = {};
        ["rare"]      = {};
        ["legendary"] = {};
    };

    self.itemIndices = {}; -- list of all modifier names with the index of their position in the table and rarity
    self.consumableIndices = {}; -- list of all consumables with the index of their position in the table and rarity
    self.weaponIndices = {}; -- list of all weapons with the index of their position in the table and rarity

    self.itemRarityOdds = { -- applies 2 items and consumables
        ["common"]    = 0.65; -- 65%
        ["uncommon"]  = 0.95; -- 30%
        ["rare"]      = 1.00; -- 5%
        ["legendary"] = 1.00; -- 0%
    }; -- how often should each rarity be chosen for items? (as a perun to be less then the number asigned)

    self.weaponRarityOdds = { -- applies 2 weapons
        ["common"]    = 0.65; -- 65%
        ["uncommon"]  = 0.95; -- 30%
        ["rare"]      = 1.00; -- 5%
        ["legendary"] = 1.00; -- 0%
    }; -- how often should each rarity be chosen for weapons? (as a perun to be less then the number asigned)

    self.typeOdds = {
        consumable = 0.18; -- 18%
        item       = 1.00; -- 82%
    };

    local allItemFiles = love.filesystem.getDirectoryItems(path .. "/items");
    for _, v in ipairs(allItemFiles) do -- load every file inside of the 'items/' directory
        assert(string.find(v, "%.lua$"), "non lua file found in items folder, all files must be .lua");

        self.parseItem(path .. ".items." .. (string.match(v, "(.*)%.lua")));
    end

    local allWeaponFiles = love.filesystem.getDirectoryItems(path .. "/weapons");
    for _, v in ipairs(allWeaponFiles) do -- load every file inside of the 'weapons/' directory
        assert(string.find(v, "%.lua$"), "non lua file found in weapons folder, all files must be .lua");

        self.parseWeapon(path .. ".weapons." .. (string.match(v, "(.*)%.lua")));
    end

    local defFont = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 18);

    FancyText.setDefaultFont(defFont);
    FancyText.setGlobalItem("default", defFont);
    FancyText.setGlobalItem("big", love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 23));
    FancyText.setGlobalItem("bold", love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 25));
    FancyText.setGlobalItem("longTermValue", 0);

    _G.ItemBase = nil; -- remove from globals
end

function Items.parseItem(file)
    print("got new item: " .. file);

    local obj = require(file);

    if type(obj) ~= "table" then -- items that arent ready yet return nil
        return;
    end

    assert(self.allItems[obj.rarity] ~= nil, "tried to add an item of invalid rarity: " .. (obj.rarity or "nil"));

    -- adds item to list
    if obj.consumable then
        table.insert(self.allConsumables[obj.rarity], obj);
        table.insert(self.consumablesVisible[obj.rarity], 0);
    else
        table.insert(self.allItems[obj.rarity], obj);
        table.insert(self.itemsVisible[obj.rarity], 0);
    end

    assert(obj.name and obj.name ~= "", "items MUST be named");
    assert(string.find(obj.name, "[\n|]") == nil, "item names cannot contain the characters: '|' or '\\n'");

    local filteredName = string.gsub(obj.name, "[^%a+]", ""); -- remove everything other the letters (or pluses)
    filteredName = string.gsub(filteredName, "%+", "Plus"); -- kinda jank tbh
    assert(EVENTS.item.purchase[filteredName], "tried to create item that does not have a 'purchase' event: " .. filteredName);
    assert(EVENTS.item.sell[filteredName], "tried to create item that does not have a 'sell' event: " .. filteredName);

    obj.filteredName = filteredName; -- for calling events internally
    obj.id = getNextItemId()
    --if not obj.unique then
        if obj.rarity == "common" then
            obj.instancesLeft = 3
        elseif obj.rarity =="uncommon" then
            obj.instancesLeft = 2
        end
    --end

    if obj.consumable then
        self.consumableIndices[filteredName] = {
            index = #self.allConsumables[obj.rarity];
            rarity = obj.rarity;
        };
    else
        self.itemIndices[filteredName] = {
            index = #self.allItems[obj.rarity];
            rarity = obj.rarity;
        };
    end

    if not obj.descriptionPointers then
        obj.descriptionPointers = {}
    end

    if obj.imageReference then
        obj.image = love.graphics.newImage(obj.imageReference);
    end
end

function Items.parseWeapon(file)
    print("got new weapon: " .. file);

    local obj = require(file);

    if type(obj) ~= "table" then -- items that arent ready yet return nil
        return;
    end

    assert(self.allWeapons[obj.rarity] ~= nil, "tried to add an item of invalid rarity: " .. (obj.rarity or "nil"));

    table.insert(self.allWeapons[obj.rarity], obj);
    table.insert(self.weaponsVisible[obj.rarity], 0);

    assert(obj.name and obj.name ~= "", "weapons MUST be named");
    assert(string.find(obj.name, "[\n|]") == nil, "weapons names cannot contain the characters: '|' or '\\n'");
    assert(validWeaponTypes[obj.type], "tried to create a weapon with an invalid weapon type: " .. (obj.type or "nil"));

    local filteredName = string.gsub(obj.name, "[^%a+]", ""); -- remove everything other the letters (or pluses)
    filteredName = string.gsub(filteredName, "%+", "Plus"); -- kinda jank tbh
    -- assert(EVENTS.item.purchase[filteredName], "tried to create item that does not have a 'purchase' event: " .. filteredName);
    -- assert(EVENTS.item.sell[filteredName], "tried to create item that does not have a 'sell' event: " .. filteredName);

    obj.filteredName = filteredName; -- for calling events internally
    -- obj.id = getNextItemId()

    self.weaponIndices[filteredName] = {
        index = #self.allWeapons[obj.rarity];
        rarity = obj.rarity;
    };
end

function Items.updateitemRarityOdds()
    local level = Player.level;

    if level < 5 then
        Items.setitemRarityOdds(1, 0, 0.0, 0.0);
    elseif level < 8 then
        Items.setitemRarityOdds(0.88, 0.1, 0.02, 0.0);
    elseif level < 13 then
        Items.setitemRarityOdds(0.75, 0.2, 0.05, 0);
    elseif level < 18 then
        Items.setitemRarityOdds(0.625, 0.3, 0.075, 0);
    elseif level < 22 then
        Items.setitemRarityOdds(0.53, 0.35, 0.1, 0.02);
    elseif level < 26 then
        Items.setitemRarityOdds(0.485, 0.35, 0.125, 0.04);
    else
        Items.setitemRarityOdds(0.4, 0.39, 0.15, 0.06);
    end
end

function Items.setitemRarityOdds(common, uncommon, rare, legendary)
    self.itemRarityOdds = {
        ["common"]    =                               common;
        ["uncommon"]  =                    uncommon + common;
        ["rare"]      =             rare + uncommon + common;
        ["legendary"] = legendary + rare + uncommon + common;
    };

    assert(legendary + rare + uncommon + common == 1, "tried tp set rarity odds, but odds do not add up to 1");
end

--* does NOT set returned item as visible
function Items.getItemByName(name)
    local index = self.itemIndices[name];

    if index then
        return self.allItems[index.rarity][index.index];
    end

    -- can be a consumable
    index = self.consumableIndices[name];

    if index then
        return self.allConsumables[index.rarity][index.index];
    end

    -- might be a name instead of a filteredName
    for rarity, v in pairs(self.allItems) do
        for i, w in ipairs(v) do
            if w.name == name then
                return w;
            end
        end
    end

    for rarity, v in pairs(self.allConsumables) do
        for i, w in ipairs(v) do
            if w.name == name then
                return w;
            end
        end
    end

    error("tried to get item using an invalid name");
end

function Items.getWeaponByName(name)
    local index = self.weaponIndices[name];

    if index then
        return self.allWeapons[index.rarity][index.index];
    end

    -- might be a name instead of a filteredName
    for rarity, v in pairs(self.allWeapons) do
        for i, w in ipairs(v) do
            if w.name == name then
                return w;
            end
        end
    end

    error("tried to get weapon using an invalid name");
end

--* does NOT set returned item as visible
function Items.getRandomItem(allowInvisible)
    --? always uses exactly 2 love.math.random calls (one for the rarity and one for the index) consumable

    local lookingInList;
    local visibilityList;

    -- randomly determine item type
    if love.math.random() < self.typeOdds.consumable then
        lookingInList = self.allConsumables;
        visibilityList = self.consumablesVisible;
    else
        lookingInList = self.allItems;
        visibilityList = self.itemsVisible;
    end

    local randRarity = love.math.random(); -- [0-1)
    local rarity = nil;
    -- local dif = 0;
    -- print(randRarity);

    Items.updateitemRarityOdds(); -- inneficient but i wanna go 2 bed

    if randRarity < self.itemRarityOdds.common then
        rarity = "common";
    elseif randRarity < self.itemRarityOdds.uncommon then
        rarity = "uncommon";
    elseif randRarity < self.itemRarityOdds.rare then
        rarity = "rare";
    elseif randRarity < self.itemRarityOdds.legendary then
        rarity = "legendary";
    else
        print("smthn happened");
        rarity = "common";
    end

    print(rarity, randRarity);

    assert(lookingInList[rarity], "somehow a rarity was not chosen, this should be impossible (milo can't write working code apparently)");

    if allowInvisible then
        local index = love.math.random(1, #lookingInList[rarity]);

        return lookingInList[rarity][index];
    end

    -- Build a weighted pool based on instancesLeft for visible items
    -- visible means visibilityList[rarity][i] <= 0
    local totalWeight = 0
    local weights = {}
    for i, v in ipairs(visibilityList[rarity]) do
        if v <= 0 then
            local item = lookingInList[rarity][i]
            local instances = 1
            if item and item.instancesLeft then
                instances = item.instancesLeft
            end
            -- Ensure at least weight 1
            local w = math.max(1, instances)
            weights[i] = w
            totalWeight = totalWeight + w
        else
            weights[i] = 0
        end
    end

    if totalWeight == 0 then
        -- no visible items in this rarity, fallback to first common
        return lookingInList["common"][1]
    end

    local pick = love.math.random(1, totalWeight)
    local acc = 0
    for i, w in ipairs(weights) do
        acc = acc + w
        if pick <= acc and w > 0 then
            return lookingInList[rarity][i]
        end
    end

    error("uh oh, getRandomItem failed to return an item");
end

function Items.addInvisibleItem(name) -- makes an item un-attainable in the shop (calling twice needs 2 'removeInvisibleItem' calls 2 make visible again)
    local index = self.itemIndices[name];

    if index then
        self.itemsVisible[index.rarity][index.index] = self.itemsVisible[index.rarity][index.index] + 1;
        return;
    end

    index = self.consumableIndices[name];

    if index then
        self.consumablesVisible[index.rarity][index.index] = self.consumablesVisible[index.rarity][index.index] + 1;
        return;
    end

    for rarity, v in pairs(self.allItems) do
        for i, w in ipairs(v) do
            if w.name == name then
                self.itemsVisible[rarity][i] = self.itemsVisible[rarity][i] + 1;
                return;
            end
        end
    end

    for rarity, v in pairs(self.allConsumables) do
        for i, w in ipairs(v) do
            if w.name == name then
                self.consumablesVisible[rarity][i] = self.consumablesVisible[rarity][i] + 1;
                return;
            end
        end
    end

    error("couldnt add visible to non existent item: " .. name);
end
function Items.removeInvisibleItem(name) -- makes an invisible item visible again (calling twice needs 2 'addInvisibleItem' calls 2 make invisible again)
    local index = self.itemIndices[name];

    if index then
        self.itemsVisible[index.rarity][index.index] = self.itemsVisible[index.rarity][index.index] - 1;
        return;
    end

    index = self.consumableIndices[name];

    if index then
        self.consumablesVisible[index.rarity][index.index] = self.consumablesVisible[index.rarity][index.index] - 1;
        return;
    end

    for rarity, v in pairs(self.allItems) do
        for i, w in ipairs(v) do
            if w.name == name then
                self.itemsVisible[rarity][i] = self.itemsVisible[rarity][i] - 1;
                return;
            end
        end
    end

    for rarity, v in pairs(self.allConsumables) do
        for i, w in ipairs(v) do
            if w.name == name then
                self.consumablesVisible[rarity][i] = self.consumablesVisible[rarity][i] - 1;
                return;
            end
        end
    end

    error("couldnt remove visible to non existent item: " .. name);
end
function Items.setAllVisible(visible)
    local val = visible and 0 or 1 -- 0 = visible, >0 = hidden
    for rarity, list in pairs(self.itemsVisible) do
        for i = 1, #list do
            self.itemsVisible[rarity][i] = val
            local item = self.allItems[rarity][i]
            --if not item.unique then
                if rarity == "common" then
                    item.instancesLeft = 3
                elseif rarity == "uncommon" then
                    item.instancesLeft = 2
                end
            --end
        end
    end
    for rarity, list in pairs(self.consumablesVisible) do
        for i = 1, #list do
            self.consumablesVisible[rarity][i] = val
        end
    end
end

self.load(); -- load on require();
return Items;