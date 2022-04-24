local utils = require("kong.timer.utils")
local super_thread_module = require("kong.timer.thread.super")
local mover_thread_module = require("kong.timer.thread.mover")
local worker_thread_module = require("kong.timer.thread.worker")

-- luacheck: push ignore
local ngx_log = ngx.log
local ngx_STDERR = ngx.STDERR
local ngx_EMERG = ngx.EMERG
local ngx_ALERT = ngx.ALERT
local ngx_CRIT = ngx.CRIT
local ngx_ERR = ngx.ERR
local ngx_WARN = ngx.WARN
local ngx_NOTICE = ngx.NOTICE
local ngx_INFO = ngx.INFO
local ngx_DEBUG = ngx.DEBUG
-- luacheck: pop

-- luacheck: push ignore
local assert = utils.assert
-- luacheck: pop

local setmetatable = setmetatable

local _M = {}

local meta_table = {
    __index = _M,
}


function _M:wake_up_super_thread()
    self.super_thread:wake_up()
end


function _M:woke_up_mover_thread()
    self.mover_thread:wake_up()
end


function _M:wake_up_worker_thread()
    self.worker_thread:wake_up()
end


function _M:spawn()
    self.super_thread:spawn()
    self.mover_thread:spawn()
    self.worker_thread:spawn()
end


function _M:kill()
    self.super_thread:kill()
    self.mover_thread:kill()
    self.worker_thread:kill()
end


function _M.new(timer_sys)
    local super_thread = super_thread_module.new(timer_sys)
    local mover_thread = mover_thread_module.new(timer_sys)
    local worker_thread = worker_thread_module.new(timer_sys,
                                                   timer_sys.opt.threads)

    local self = {
        super_thread = super_thread,
        mover_thread = mover_thread,
        worker_thread = worker_thread,
    }

    super_thread:set_wake_up_mover_thread_callback(function ()
        mover_thread:wake_up()
    end)

    mover_thread:set_wake_up_worker_thread_callback(function ()
        worker_thread:wake_up()
    end)

    worker_thread:set_wake_up_super_thread_callback(function ()
        super_thread:wake_up()
    end)

    worker_thread:set_wake_up_mover_thread_callback(function ()
        mover_thread:wake_up()
    end)

    return setmetatable(self, meta_table)
end

return _M