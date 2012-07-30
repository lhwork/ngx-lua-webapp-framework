
local M = {}

function M.new(config)
    local app = {}

    if type(config) ~= "table" then config = {} end
    if type(config.appModuleName) ~= "string" then config.appModuleName = "app" end
    app.config = config
    app.currentActionModuleName = nil

    app.session = require("framework.session").new(app)
    app.errors = require("voyage.errors")

    ----

    local function init()
    end

    ----

    function app:run(actionName)
        local actionName = actionName or (GET.action or "index")
        actionName = string.lower(actionName)
        actionName = ngx.re.gsub(actionName, "[^a-z\\.]", "")
        actionName = ngx.re.gsub(actionName, "\\.+", ".")
        actionName = ngx.re.gsub(actionName, "^\\.+", "")
        actionName = ngx.re.gsub(actionName, "\\.+$", "")
        local parts = string.split(actionName, ".")
        if #parts == 1 then
            parts[2] = 'index'
        elseif #parts ~= 2 then
            if app.config.debug then
                app:error("invalid action name",
                          string.format("invalid action name: %s", actionName))
            else
                return app.errors.invalidActionNameError()
            end
        end

        local actionMethodName = parts[2]
        local actionName = parts[1]

        app.currentActionModuleName = string.format("%s.actions.%sAction",
                                                    app.config.appModuleName,
                                                    parts[1])

        local actionModule
        if app.config.debug then
            local ok
            ok, actionModule = pcall(function()
                return require(app.currentActionModuleName)
            end)

            if not ok then
                app:error("load action", actionModule)
            end
        else
            actionModule = require(app.currentActionModuleName)
        end

        local action, err = actionModule.new(app)
        if err then return err end
        local method = action[actionMethodName]
        if not method then
            if app.config.debug then
                app:error("invalid action method name",
                          string.format("invalid action method name: %s.%s",
                                        tostring(actionName), tostring(actionMethodName)))
            else
                return app.errors.invalidActionNameError()
            end
        end

        if app.config.debug then
            local ok, result = pcall(method)
            if not ok then
                app:error("execute action", result)
            else
                return result
            end
        else
            return method()
        end
    end

    function app:require(moduleName)
        moduleName = app.config.appModuleName .. "." .. moduleName
        return require(moduleName)
    end

    function app:redis(config)
        if app.redis_ then return app.redis_ end

        config = config or app.config.redis
        if type(config) ~= "table" then config = {} end
        local timeout = config.timeout or 1000 -- 1 second
        local host = config.host or "127.0.0.1"
        local port = config.port or 6379

        local redis = require("framework.redis.redis")
        local red = redis:new()
        red:set_timeout(timeout)

        local ok, err = red:connect(host, port)
        if not ok then
            return false, app.errors.redisError(err)
        end

        app.redis_ = red
        return red
    end

    function app:error(reason, errorMessage, moduleName)
        if not moduleName then moduleName = app.currentActionModuleName end
        ngx.say("<p><strong>ERROR: " .. string.upper(reason) .. "</strong></p>")
        if moduleName then
            ngx.say("<p><strong>MODULE</strong>: " .. moduleName .. "</p>")
        end
        ngx.say("<p><strong>MESSAGE:</strong></p>")
        ngx.say("<pre>")
        ngx.say(string.text2html(errorMessage))
        ngx.say("</pre>")
        ngx.say("<p><strong>DEBUG STACK TRACEBACK:</strong></p>")
        ngx.say("<pre>")
        local trace = debug.traceback("", 2)
        trace = string.split(trace, "\n")
        table.remove(trace, 1)
        for i, line in ipairs(trace) do
            line = string.ltrim(line)
            ngx.say(string.text2html(string.format("    %d: %s", #trace - i + 1, line)))
        end
        ngx.say("</pre>")
        ngx.exit(ngx.HTTP_OK)
    end

    ----

    init()
    return app
end

return M
