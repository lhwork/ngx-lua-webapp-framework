
--[[--

Session 用于在服务端保持一个会话状态。

在调用 session:start() 和 session:save() 之后，服务端会保存一组键值。
在处理客户端的后续请求时，只要客户端提供了 SessionId，服务端就可以通过 SessionId 获得这一组键值。

会话状态可以用来保存跨越多个请求的状态，减少客户端和服务端之间需要传递的数据，并且更好的保护用户的敏感信息。


### 关于 SessionId

SessionId 用于唯一标示一个存储在服务端的会话数据。

**创建 SessionId 的算法**

-   取服务器当前时间
-   取 4 位随机数
-   取当前用户 ID
-   时间 + 随机数 + 种子，求 MD5 得到 SessionId

**Session 的存储和有效期**

-   首次使用新 SessionId 调用 session:start() 及 session:save() 后，
    一组以 SessionId 为键名的键值会被保存在服务端，并设定一个有效期；
-   在下一次使用已有 SessionId 调用 session:start() 时，这组键值会被读取出来放入 session 对象；
-   再次调用 session:save() 或 session:refresh() 会自动更新 session 的有效期。
-   如果调用 session:destroy()，session 对象中的值和存储在服务端的键值会被立即删除。

**SessionId 的安全性**

-   目前简化实现，SessionId 的传输和存储没有进行加密操作。

]]
local M = {}

local ok, json = pcall(function() require("cjson") end)
if not ok then
    json = require("framework.simplejson")
end

M.PREFIX    = "sess:"
M.LIFETIME  = 60 * 60   -- 1 hour

--[[--


]]
function M.new(app)
    local session = {}
    session.keys = {}
    session.sid_ = nil

    ----

    local function key()
        return M.PREFIX .. session.sid_
    end

    ----


    --[[--

    生成 SessionId

    **Parameters:**

    -   seed: 用于生成 SessionId 的种子

    **Returns:**

    -   新生成的 SessionId

    ]]
    function session:makeSessionId(seed)
        local time = ngx.time()
        math.randomseed(time)
        local rand = math.random(1000, 9999)
        return ngx.md5(string.format("%d%s%d", time, tostring(seed), rand))
    end

    --[[--

    验证 SessionId 是否是有效

    **Parameters:**

    -   sid: 要验证的 SessionId

    **Returns:**

    -   验证通过: true
    -   验证失败: false

    ]]
    function session:validateSessionId(sid)
        if (string.len(sid) ~= 16) then return false end
        if (ngx.re.match(sid, "[^a-f0-9]")) then return false end
        return true
    end

    --[[--

    启动 session，如果失败返回 APIError

    **Parameters:**

    -   sid: SessionId，如果未提供将自动生成一个

    **Returns:**

    -   成功: 无
    -   失败: 返回 APIError

    ]]
    function session:start(sid)
        if type(sid) ~= "string" then
            sid = session:makeSessionId(math.random(100000, 999999))
        elseif not session:validateSessionId(sid) then
            return app.errors.invalidSessionError()
        end

        session.sid_ = sid

        local redis = app:redis()
        local value, err = redis:get(key())
        if not err then
            session.keys = json.decode(value)
            if type(session.keys) ~= "table" then
                session.keys = {}
            end
        end
    end

    --[[--

    获得 SessionId

    **Returns:**

    -   SessionId

    ]]
    function session:sid()
        return session.sid_
    end

    --[[--

    获取指定的键值

    **Parameters:**

    -   key: 键名

    **Returns:**

    -   键值

    ]]
    function session:get(key)
        return clone(session.keys[key])
    end

    --[[--

    获取所有键值

    **Returns:**

    -   包含所有键值的数组

    ]]
    function session:getAll()
        return clone(session.keys)
    end

    --[[--

    设定键值

    **Parameters:**

    -   key: 键名
    -   value: 键值

    ]]
    function session:set(key, value)
        session.keys[key] = clone(value)
    end

    --[[--

    删除 session

    ]]
    function session:destroy()
        if session.sid_ then
            app:redis():del(key())
        end
        session.keys = {}
        session.sid_ = nil
    end

    --[[--

    刷新 session 过期时间

    ]]
    function session:refresh()
        if not session.sid_ then return end
        app:redis():expire(key(), M.LIFETIME)
    end

    --[[--

    保存 session

    **Returns:**

    -   成功: true
    -   失败: false

    ]]
    function session:save()
        if not session.sid_ then return end
        local ok = app:redis():setex(key(), M.LIFETIME, json.encode(session.keys))
        ngx.say("session:save() return " .. tostring(err))
        return ok == "OK"
    end

    ----

    return session
end

return M
