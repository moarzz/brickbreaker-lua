local ActiveGameState = {};
local self = ActiveGameState; -- for readability

_G.GameState = {
    MENU         = "menu";
    START_SELECT = "start_select";
    PLAYING      = "playing";
    PAUSED       = "paused";
    SETTINGS     = "settings";
    UPGRADES     = "upgrades";
    TUTORIAL     = "tutorial";
    VICTORY      = "victory";
};

function ActiveGameState.init()
    self.state = GameState.MENU;

    self.stateCallbacks = {}; -- list of callbacks for when a state is selected

    return self; -- allow for require(...).init()
end

function ActiveGameState.addCallbackToState(callback, state)
    local section = self.stateCallbacks[state];

    if section then
        if type(section) == "table" then
            table.insert(section, callback);
        else
            self.stateCallbacks[state] = {section, callback};
        end
    else
        self.stateCallbacks[state] = callback;
    end
end
function ActiveGameState.removeCallbackFromState(callback, state)
    local section = self.stateCallbacks[state];

    if not section then
        return; -- callback section was already empty
    end

    if type(section) == "table" then
        for i, v in ipairs(section) do
            if v == callback then
                table.remove(section, i);
                break;
            end
        end

        if #section == 1 then
            self.stateCallbacks[state] = section[1];
        end
    else
        if section == callback then
            self.stateCallbacks[state] = nil;
        end
    end
end

function ActiveGameState.getCurrentState(compare)
    if not compare then
        return self.state;
    end

    return compare == self.state;
end

function ActiveGameState.setGameState(state)
    local section = self.stateCallbacks[state];

    if section then
        if type(section) == "table" then
            for _, v in ipairs(section) do
                v();
            end
        else
            section();
        end
    end

    self.state = state;
end

-- global functions
_G.GET_STATE = ActiveGameState.getCurrentState;
_G.SET_STATE = ActiveGameState.setGameState;
_G.AddCallbackToState = ActiveGameState.addCallbackToState;
_G.RemoveCallbackFromState = ActiveGameState.removeCallbackFromState;

return ActiveGameState;