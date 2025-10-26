local eventLocatorMeta = {};
function eventLocatorMeta:__index(key)
    if eventLocatorMeta[key] then
        return eventLocatorMeta[key];
    end

    local cur = self;

    for str, _ in string.gmatch(key .. "_", "(.-)_") do
        if cur[str] then
            cur = cur[str];
        else
            error("cannot find event from event pointer: '" .. key .. "'");
        end
    end

    assert(cur ~= self, "cannot find event from event pointer: '" .. key .. "'");

    return cur;
end

function eventLocatorMeta.contains(objToCheck, check)
    local match = string.match(objToCheck, "^" .. check);

    return match ~= nil;
end

_G.EVENTS = setmetatable({
    empty = true; -- nil
    money = {
        lose = true;
        gain = true;
    };

    upgradeStat = {
        item1 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item2 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item3 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item4 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item5 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
        item6 = {
            amount = true,
            damage = true,
            speed = true,
            fireRate = true,
            range = true,
            ammo = true,
            cooldown = true
        },
    },
    item = {
        purchase = {
            ArcaneMissiles        = true;
            ArcheologistHat       = true;
            AssassinsDagger       = true;
            BirthdayHat           = true;
            BouncyWalls           = true;
            Brickbreaker          = true;
            BuytheDip             = true;
            CouponCollector       = true;
            DegenerateGambling    = true;
            ElonsShmuck           = true;
            FinancialPlan         = true;
            FlashSale             = true;
            FourLeafedClover      = true;
            GrowCube              = true;
            HomingBullets         = true;
            HugePaddle            = true;
            InsiderTrading        = true;
            InvestmentGuru        = true;
            JackOfAllTrades       = true;
            LoadedDice            = true;
            LongTermInvestment    = true;
            Mechanic              = true;
            Nirvana               = true;
            Omnipotence           = true;
            Overclock             = true;
            PaddleDefenseSystem   = true;
            PhantomBullets        = true;
            PlusThreeBuff         = true;
            PlusSixBuff           = true;
            PlusNineBuff          = true;
            PowerDrill            = true;
            Recession             = true;
            RichGetRicher         = true;
            SacredGift            = true;
            Sommelier             = true;
            SplitShooter          = true;
            SprayandPray          = true;
            SwissArmyKnife        = true;
            TeslaBullets          = true;
            TeslaCoil             = true;
            TotalAnihilation      = true;
            TotalEconomicCollapse = true;
            TripleTrouble         = true;
            TripleTroublePlus     = true;
            TripleTroublePlusPlus = true;
        };

        sell = {
            ArcaneMissiles        = true;
            ArcheologistHat       = true;
            AssassinsDagger       = true;
            BirthdayHat           = true;
            BouncyWalls           = true;
            Brickbreaker          = true;
            BuytheDip             = true;
            CouponCollector       = true;
            DegenerateGambling    = true;
            ElonsShmuck           = true;
            FinancialPlan         = true;
            FlashSale             = true;
            FourLeafedClover      = true;
            GrowCube              = true;
            HomingBullets         = true;
            HugePaddle            = true;
            InsiderTrading        = true;
            InvestmentGuru        = true;
            JackOfAllTrades       = true;
            LoadedDice            = true;
            LongTermInvestment    = true;
            Mechanic              = true;
            Nirvana               = true;
            Omnipotence           = true;
            Overclock             = true;
            PaddleDefenseSystem   = true;
            PhantomBullets        = true;
            PlusThreeBuff         = true;
            PlusSixBuff           = true;
            PlusNineBuff          = true;
            PowerDrill            = true;
            Recession             = true;
            RichGetRicher         = true;
            SacredGift            = true;
            Sommelier             = true;
            SplitShooter          = true;
            SprayandPray          = true;
            SwissArmyKnife        = true;
            TeslaBullets          = true;
            TeslaCoil             = true;
            TotalAnihilation      = true;
            TotalEconomicCollapse = true;
            TripleTrouble         = true;
            TripleTroublePlus     = true;
            TripleTroublePlusPlus = true;
        }
    };
    levelUp = true;
}, eventLocatorMeta); -- list of all possible modifier triggers

_G.ANIMATION_EVENTS = setmetatable({
    block = {
        trigger = true;
        clear = true;
        score = {
            points = true;
            mult = true;
        };
    };
    line = {
        trigger = true;
        clear = true;
        score = {
            points = true;
            mult = true;
        };
    };
    modifier = {
        trigger = true;
        score = {
            points = true;
            mult = true;
        };
    };
}, eventLocatorMeta); -- list of all possible animation events

local function recurseFill(tbl, fill, cur)
    fill = fill or {};
    cur = cur or "";

    for k, v in pairs(tbl) do
        assert(string.find(k, "_") == nil, "cannot make an event with subcontents containing the '_' character");

        if type(v) == "table" then
            fill[cur .. k] = cur .. k;

            recurseFill(v, fill, cur .. k .. "_");
        else
            fill[cur .. k] = cur .. k;
        end
    end

    return fill;
end

_G.EVENT_POINTERS = recurseFill(EVENTS);
_G.ANIMATION_EVENT_POINTERS = recurseFill(ANIMATION_EVENTS);
