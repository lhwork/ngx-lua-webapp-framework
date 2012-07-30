
--[[--

创建一个新类

**Parameters:**

-   classname: 类名称
-   ctor: 构造函数
-   super: 父类（可选）

**Returns:**

-   class: 新类

]]
function class(classname, ctor, super)
    local cls
    if super then
        cls = clone(super)
    else
        cls = {}
    end

    if super then
        cls.super = super
        for k, v in pairs(super) do cls[k] = v end
    end

    cls.super     = super
    cls.classname = classname
    cls.ctor      = ctor
    cls.__index   = cls

    local function callctor(o, ctor, super, ...)
        if super then callctor(o, super.ctor, super.super, ...) end
        if ctor then ctor(o, ...) end
    end

    cls.new = function(...)
        local o = setmetatable({}, cls)
        -- 创建对象实例时，要按照正确的顺序调用继承层次上所有的 ctor 函数
        callctor(o, ctor, super, ...)
        o.class = cls
        return o
    end

    return cls
end

function clone(object)
    local lookupTable = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookupTable[object] then
            return lookupTable[object]
        end
        local new_table = {}
        lookupTable[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function dump(object, label, nesting, nest)
    if type(nesting) ~= "number" then nesting = 99 end

    local lookupTable = {}
    local result = {}
    local function _dump(object, label, indent, nest)
        label = label or "<var>"
        if type(object) ~= "table" then
            result[#result +1 ] = string.format("%s%s = %s",
                                                indent,
                                                tostring(label),
                                                tostring(object).."")
        elseif lookupTable[object] then
            result[#result +1 ] = string.format("%s%s = *REF*", indent, tostring(label))
        else
            lookupTable[object] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, label)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, tostring(label))
                local indent2 = indent.."    "
                local keys = {}
                for k, v in pairs(object) do
                    keys[#keys + 1] = k
                end
                table.sort(keys)
                for i, k in ipairs(keys) do
                    _dump(object[k], k, indent2, nest + 1)
                end
                result[#result +1 ] = string.format("%s}", indent)
            end
        end
    end
    _dump(object, label, "- ", 1)

    ngx.say("<pre>")
    ngx.say(string.text2html(table.concat(result, "\n")))
    ngx.say("</pre>")
end

function printf(...)
    ngx.say(string.format(select(1, ...)))
end

function export(input, names)
    local args = {}
    for k, def in pairs(names) do
        if type(k) == "number" then
            args[def] = input[def]
        else
            args[k] = input[k] or def
        end
    end
    return args
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

string.htmlspecialchars = function(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

string.nl2br = function(input)
    return string.gsub(input, "\n", "<br />")
end

string.text2html = function(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

string.split = function(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

string.ltrim = function(str)
    return string.gsub(str, "^[ \t]+", "")
end
