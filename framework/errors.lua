
local M = {}

function M.newError(errorCode, errorMessage)
    local err = {errorCode = errorCode, errorMessage = errorMessage}
    return err
end

function M.invalidActionNameError()
    return M.newError(50001, "invalid action name")
end

function M.redisError(err)
    return M.newError(50002, "redis error: " .. tostring(err))
end

function M.unknownError(err)
    return M.newError(50003, "unknown error: " .. tostring(err))
end

function M.invalidSessionError()
    return M.newError(50004, "invalid session")
end

return M
