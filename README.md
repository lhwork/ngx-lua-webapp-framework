ngx-lua-webapp-framework
========================

Lua webapp framework for Nginx-Lua


### nginx config

All source files in /to/path:

    http {
        lua_package_path '/to/path/?.lua;;';
    
        ....
    
        server {
    
            ....
    
            location /test {
                lua_code_cache off;
                default_type 'text/html';
                content_by_lua_file /to/path/main.lua;
            }
        }
    }


### Example

**/to/path/main.lua**
    
    local function main()
        require("framework.init")
        local config = {appModuleName = "app"}
        local app = require("framework.AppBase").new(config)
        app:run()
    end
    
    local b, msg = pcall(main)
    if b == false then
        ngx.say("<p><strong>LUA ERROR</strong></p>")
        ngx.say(msg)
    end


**/to/path/app/actions/index.lua**

    local M = {}
    
    function M.run(app)
        ngx.say("app.actions.index")
    end
    
    return M

### Test

curl http://localhost/test/?action=index
