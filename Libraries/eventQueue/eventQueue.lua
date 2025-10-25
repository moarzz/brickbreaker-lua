local EventQueue = {};
EventQueue.__index = EventQueue;

function EventQueue.new()
    local instance = setmetatable({}, EventQueue);

    instance.queue = {};

    instance.timeUntilNextDequeue = 0;

    return instance;
end

function EventQueue:addEventToQueue(event, length, obj)
    local item = {
        event = event or EVENT_POINTERS.empty;
        callback = obj;
        eventLength = length or 0;
    };

    table.insert(self.queue, item);
end
function EventQueue:addEventToFrontOfQueue(event, length, obj)
    local item = {
        event = event or EVENT_POINTERS.empty;
        callback = obj;
        eventLength = length or 0;
    }

    table.insert(self.queue, 1, item);
end

function EventQueue:update(dt)
    if self:isQueueFinished() then
        return;
    end

    self.timeUntilNextDequeue = self.timeUntilNextDequeue - dt;

    if self.timeUntilNextDequeue > 0 then
        return;
    end

    -- safety: don't dequeue infinitely many events in one frame
    --* Milo:3 formally disagrees w/ this, she intentionally allowed recursion since it would be an issue either way
    --* and having the while loop go infinitely would be a more noticeable effect. and sometimes a shit tonne
    --* of dequeues in a single frame is wanted (so as a comprimize she changed 'maxDequeuePerUpdate' from 64 to 1024)
    local maxDequeuePerUpdate = 1024;
    local dequeued = 0;

    while self.timeUntilNextDequeue <= 0 and dequeued < maxDequeuePerUpdate do
        if self:isQueueEmpty() then
            return;
        end

        self:dequeue();
        dequeued = dequeued + 1;
    end
end

function EventQueue:dequeue()
    local nextQueuedEvent = table.remove(self.queue, 1);
    if not nextQueuedEvent then
        return;
    end

    self.timeUntilNextDequeue = self.timeUntilNextDequeue + nextQueuedEvent.eventLength;
    -- if a frame causes 2 event to try and dequeue at the same time only let one and delay the next one

    if nextQueuedEvent.callback then
        if type(nextQueuedEvent.callback) == "function" then
            nextQueuedEvent.callback();
        else
            nextQueuedEvent.callback:trigger();
        end
    end

    if nextQueuedEvent.event == EVENT_POINTERS.empty then
        return;
    end

    -- trigger all items in the roster
    for _, item in pairs(Player.items) do
        local construct = "";

        for str, _ in string.gmatch(nextQueuedEvent.event .. "_", "(.-)_") do
            construct = construct .. str;

            if type(item.events[construct]) == "function" then
                item.events[construct](item);
            end

            construct = construct .. "_";
        end
    end
end

--* Milo:3 disagrees w/ this function out of prinicple that the event queue should be use din a manner of togglability
--* and that code should not be running while the eventQueue is dequeueing (or just make a new eventQueue object)
function EventQueue:clear()
    self.queue = {};
    self.timeUntilNextDequeue = 0;
end

function EventQueue:isQueueEmpty()
    return #self.queue == 0;
end

function EventQueue:isQueueFinished()
    return self:isQueueEmpty() and self.timeUntilNextDequeue <= 0;
end

return EventQueue;