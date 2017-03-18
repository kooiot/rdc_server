local skynet = require 'skynet'
local queue = require 'skynet.queue'
local coroutine = require 'skynet.coroutine'
local xpcall = xpcall
local traceback = debug.traceback
local table = table

function skynet.event_queue()
    local current_thread
    local push_queue = queue()
    local wait_queue = queue()

    local function call_ret(...)
        current_thread = nil
        return ...
    end

    return {
        push = function(timeout, ...)
            return push_queue(function(...)
                return coroutine.resume(current_thread, ...)
            end, ...)
        end,
        pop = function(timeout, ...)
            return wait_queue(function(...)
                thread = coroutine.running()
                current_thread = thread
                return call_ret(coroutine.yield(thread, ...))
            end, ...)
        end,
        abort = function()
            while current_thread do
                coroutine.resume(current_thread)
                skynet.yield()
            end
        end
    }
end

return skynet.event_queue
