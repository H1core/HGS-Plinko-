local M = {}

local RUNNING = 0
local YIELDED = 1
local DONE = 2

function M.start_thread(func, ...)
    local main_thread = coroutine.create(func)

    coroutine.resume(main_thread, ...)
    return main_thread
end


---@param fn fun(done: function)
function M.await(fn, ...)
    assert(fn)

    local co = coroutine.running()
    assert(co, 'no async bootstrap ' .. debug.traceback())

    local results = nil
    local state = RUNNING

    fn(function(...)
        results = {...}
        if state == YIELDED then
            local res, err = coroutine.resume(co)

            if not res then
                error(err)
                print(debug.traceback())
            end
        else
            state = DONE
        end
    end, ...)

    if state == RUNNING then
        state = YIELDED
        coroutine.yield()

        state = DONE
    end

    return unpack(results)
end

function M.delay(time)
    M.await(function(done)
        timer.delay(time, false, done)
    end)
end

function M.wait_until(func)
    M.await(function (done)
        while func() do
            M.delay(0)
        end

        done()
    end)
end

setmetatable(M, {
    __call = function(_, ...)
        return M.await(...)
    end,
})

_G.task = {
    thread = M.start_thread,
    await = M.await,
    wait_until = M.wait_until,
    delay = M.delay
}
return M
