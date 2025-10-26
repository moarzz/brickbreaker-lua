--! picky core does not work


local path = (...); -- what is the folder this is located in?
path = string.gsub(path, "%.", "/"); -- prevent issues w/ love.filesystem.getDirectoryItems()

local Items = {};
local self = Items; -- for convenience

function Items.load()
    _G.ItemBase = require(path .. ".itemBase");

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

    self.itemIndices = {}; -- list of all modifier names with the index of their position in the table and rarity
    self.consumableIndices = {}; -- list of all consumables with the index of their position in the table and rarity

    self.rarityOdds = { -- applies 2 items and consumables
        ["common"]    = 0.65; -- 65%
        ["uncommon"]  = 0.95; -- 30%
        ["rare"]      = 1.00; -- 5%
        ["legendary"] = 1.00; -- 0%
    }; -- how often should each rarity be chosen? (as a perun to be less then the number asigned)

    self.typeOdds = {
        consumable = 0.15; -- 15%
        item       = 1.00; -- 85%
    };

    local allFiles = love.filesystem.getDirectoryItems(path .. "/items");
    for _, v in ipairs(allFiles) do -- load every file inside of the 'items/' directory
        assert(string.find(v, "%.lua$"), "non lua file found in items folder, all files must be .lua");

        self.parseItem(path .. ".items." .. (string.match(v, "(.*)%.lua")));
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

    if obj.consumable then
        self.consumableIndices[obj.name] = {
            index = #self.allConsumables[obj.rarity];
            rarity = obj.rarity;
        };
    else
        self.itemIndices[obj.name] = {
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

function Items.setRarityOdds(common, uncommon, rare, legendary)
    self.rarityOdds = {
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

    if index == nil then
        index = self.consumableIndices[name];
        assert(index ~= nil, "tried to get item using an invalid name");

        return self.allConsumables[index.rarity][index.index];
    end

    return self.allItems[index.rarity][index.index];
end

--* does NOT set returned item as visible
function Items.getRandomItem(allowVisible)
    --? always uses exactly 2 love.math.random calls (one for the rarity and one for the index)

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
    local dif = 1;
    -- print(randRarity);

    for k, v in pairs(self.rarityOdds) do
        if randRarity < v and v - randRarity < dif then -- if the random number is less then a rarity: it is possible 2 be chosen. choose the largest rarity that fits this
            dif = v - randRarity;
            rarity = k;
        end
    end
    -- print(rarity);

    assert(lookingInList[rarity], "somehow a rarity was not chosen, this should be impossible (milo can't write working code apparently)");

    if allowVisible then
        local index = love.math.random(1, #lookingInList[rarity]);

        return lookingInList[rarity][index];
    end

    local visibleCount = 0;
    for _, v in ipairs(visibilityList[rarity]) do -- check if there are ANY visible modifiers left
        if v <= 0 then -- if v == 0 then modifier IS visible
            visibleCount = visibleCount + 1;
        end
    end

    if visibleCount == 0 then -- if no modifiers are visible
        print("ran out of items, returning a default");
        return lookingInList["common"][1]; -- return the 1st item in the common list as a safety measure
    end

    local index = love.math.random(1, visibleCount);

    local modifSeen = 0;
    for i, v in ipairs(visibilityList[rarity]) do -- check if there are ANY visible modifiers left
        if v <= 0 then -- if v == 0 then modifier IS visible
            modifSeen = modifSeen + 1;

            if modifSeen == index then
                return lookingInList[rarity][i];
            end
        end
    end

    -- shouldnt be possible to get here
    error("milo cant write a working rng function apparently");
end

function Items.addVisibleItem(name) -- makes an item un-attainable in the shop (calling twice needs 2 'removeVisibleItem' calls 2 make visible again)
    local index = self.itemIndices[name];

    if not index then
        error("couldnt add visible to non existent item: " .. name);
    end

    self.itemsVisible[index.rarity][index.index] = self.itemsVisible[index.rarity][index.index] + 1;
end
function Items.removeVisibleItem(name) -- makes an invisible item visible again (calling twice needs 2 'addVisibleItem' calls 2 make invisible again)
    local index = self.itemIndices[name];

    if not index then
        error("couldnt remove visible to non existent item: " .. name);
    end

    self.itemsVisible[index.rarity][index.index] = self.itemsVisible[index.rarity][index.index] - 1;
end

self.load(); -- load on require();
return Items;