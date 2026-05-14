local SuddenMitosis = ItemBase.new();
SuddenMitosis.__index = SuddenMitosis;
SuddenMitosis.name = "Sudden Mitosis";
SuddenMitosis.description = "<font=bold>On Bullet Shot<font=default>\n<mitosisChance>% chance to spawn a small ball that lasts for 6 seconds";
SuddenMitosis.rarity = "uncommon";
SuddenMitosis.shotCount = 0;
SuddenMitosis.unique = true
SuddenMitosis.imageReference = "assets/sprites/UI/ItemIcons/Sudden-Mitosis.png";
SuddenMitosis.count = 0;
SuddenMitosis.maxCount = 50;
function SuddenMitosis.new()
    local instance = setmetatable({}, SuddenMitosis):init();

    instance.descriptionPointers = {
        mitosisChance = hasItem("Four Leafed Clover") and 16 or 8;
    };

    return instance;
end

function SuddenMitosis:increase()
    self.count = self.count + 1;
end

function SuddenMitosis:decrease()
    self.count = math.max(0, self.count - 1);
end

function SuddenMitosis:canIncrease()
    return self.count < self.maxCount;
end

return SuddenMitosis