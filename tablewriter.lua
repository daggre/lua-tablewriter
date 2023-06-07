TableWriter = {}

function TableWriter:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj.level = 0
    obj.tabsize = 4
    obj.file = nil
    obj.inline_table = {}
    return obj
end

function TableWriter:setInline(level, enable)
    enable = enable or true
    if enable then
        self.inline_table[level] = 0
    else
        self.inline_table[level] = nil
    end
end

function TableWriter:writeTable(k, v, filename, tabsize)
    if type(k) ~= "string" then error("tableName is not type 'string'"); end
    if type(v) ~= "table" then error("inputTable is not type 'table'"); end
    if type(filename) ~= "string" then error("filename is not type 'string'"); end

    self.level = 0
    self.tabsize = tabsize or self.tabsize 
    self.file = io.open(filename, "w")
    if not self.file then error("Failed to open file for writing: ", filename) end
    self:serialize(k,v)
    print("Writing "..filename)
end

function TableWriter:indent()
    if self.lastInLevel then return ''; end
    if self.firstInLevel then return string.rep(' ', (self.level-1)*self.tabsize); end
    if self.inline_table[self.level] then
        self.inline_table[self.level] = self.inline_table[self.level] + 1
        return ''
    end
    return string.rep(' ', self.level*self.tabsize)
end

function TableWriter:newline()
    return string.format('%s', self.inline_table[self.level] and not self.lastInLevel and ' ' or '\n')
end

function TableWriter:formatNumber(num)
    num = tonumber(num) or nil
    if num == nil then return ""; end
    if num > 0xBEEF then
        return '0x'..string.upper(string.format('%08x', num))
    end
    return tostring(num)
end

function TableWriter:prefixKey(key, isArray, str)
    if not key or (type(key) == "number" and isArray) then return str; end
    if type(key) == "number" and not isArray then
        return string.format('%s%s', '['..self:formatNumber(key)..'] = ', str)
    elseif type(key) == "table" then
        print("Warn: key is table (currently-unsupported)")
        return "?"
    elseif type(key) ~= "string" then
        return string.format('%s%s', '["'..key..'"] = ', str)
    else
        return string.format('%s%s', key..' = ', str)
    end
end

function TableWriter:write(str)
    self.file:write(self:indent()..str..self:newline())
    self.lastInLevel = false
    self.firstInLevel = false
end

function TableWriter:isArray(tbl)
    if #tbl == 0 then return false; end
    local len = 0
    for _ in pairs(tbl) do
        len = len + 1
        if len > #tbl then return false; end
    end
    return true
end

function TableWriter:setLevel(n)
    if n > self.level then
        self.firstInLevel = true
    end
    if self.inline_table[self.level] then
        self.inline_table[self.level] = 1
        if n < self.level then
            self.lastInLevel = true
        end
    end
    self.level = n
end

function TableWriter:serialize(key, value, isArray)
    if type(value) == nil then self:write(self:prefixKey(key, isArray, "nil,"))
    elseif type(value) == "string" then self:write(self:prefixKey(key, isArray, string.format('"%s",', value)))
    elseif type(value) == "boolean" then self:write(self:prefixKey(key, isArray, value and "true," or "false,"))
    elseif type(value) == "number" then self:write(self:prefixKey(key, isArray, self:formatNumber(value)..","))
    elseif type(value) == "table" then
        local tableIsArray = self:isArray(value)
        self:setLevel(self.level + 1)
        self:write(self:prefixKey(key, isArray, '{'))
        if tableIsArray then
            for k, v in ipairs(value) do
                self:serialize(k, v, true)
            end
        else
            local sortedTable = {}
            for k in pairs(value) do
                table.insert(sortedTable, k)
            end
            table.sort(sortedTable, function(a,b) return tostring(a) < tostring(b) end)
            for _, v in ipairs(sortedTable) do
                self:serialize(v, value[v])
            end
        end
        self:setLevel(self.level - 1)
        self:write(string.format('}%s', self.level and self.level > 0 and ',' or ''))
    end
end

local writer = TableWriter:new()
return writer