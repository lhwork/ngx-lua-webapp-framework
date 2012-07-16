
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function printf(...)
    ngx.say(string.format(select(1, ...)))
end

_htmlspecialchars_set = {}
_htmlspecialchars_set["&"] = "&amp;"
_htmlspecialchars_set["\""] = "&quot;"
_htmlspecialchars_set["'"] = "&#039;"
_htmlspecialchars_set["<"] = "&lt;"
_htmlspecialchars_set[">"] = "&gt;"

function htmlspecialchars(input)
    for k, v in pairs(_htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end
