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
    local maxDequeuePerUpdate = 64
    local dequeued = 0

    while self.timeUntilNextDequeue <= 0 and dequeued < maxDequeuePerUpdate do
        if self:isQueueEmpty() then
            return;
        end

        self:dequeue();
        dequeued = dequeued + 1
    end
end

function EventQueue:dequeue()
    local nextQueuedEvent = table.remove(self.queue, 1);
    if not nextQueuedEvent then
        return
    end
    self.timeUntilNextDequeue = self.timeUntilNextDequeue + (nextQueuedEvent.eventLength or 0);
    -- if a frame causes 2 event to try and dequeue at the same time only let one and delay the next one

    if nextQueuedEvent.callback then
        if type(nextQueuedEvent.callback) == "function" then
            nextQueuedEvent.callback();
        else
            nextQueuedEvent.callback:trigger();
        end
    end
end

function EventQueue:clear()
    self.queue = {}
    self.timeUntilNextDequeue = 0
end

function EventQueue:isQueueEmpty()
    return #self.queue == 0;
end

function EventQueue:isQueueFinished()
    return self:isQueueEmpty() and self.timeUntilNextDequeue <= 0;
end

return EventQueue;
