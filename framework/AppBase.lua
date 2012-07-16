
local M = {}

function M.new(config)
    local app = {}

    if type(config) ~= "table" then config = {} end
    if type(config.appModuleName) ~= "string" then config.appModuleName = "app" end
    app.config = config

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
        local moduleName = string.format("%s.actions.%s", app.config.appModuleName, actionName)

        local b, actionModule = pcall(function() return require(moduleName) end)
        if b == false then
            app:error("load action", moduleName, actionModule)
        else
            actionModule.run(app)
        end
    end

    function app:error(reason, moduleName, errorMessage)
        ngx.say("<p><strong>ERROR: " .. string.upper(reason) .. "</strong></p>")
        ngx.say("<p><strong>MODULE_NAME</strong>: " .. moduleName .. "</p>")
        ngx.say("<p><pre>")
        ngx.say(htmlspecialchars(errorMessage))
        ngx.say("</pre></p>")
    end

    ----

    init()
    return app
end

return M
