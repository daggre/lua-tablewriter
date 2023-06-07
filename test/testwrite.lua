local Writer = require("tablewriter")

local inputTable = {
    name = "John Doe",
    age = 30,
    hobbies = {"reading", "gaming", "traveling"},
    address = {
        street = "123 Main St",
        city = "New York",
        country = "USA"
    }
}

inputTable.id = "inputTable"
table.insert(inputTable, "hmm an array?")
inputTable[0x1234569] = "testHash"

Writer:setInline(2)
Writer:writeTable("MyTable", inputTable, "test/testoutput.lua")

assert(Writer:formatNumber(0) == "0")
assert(Writer:formatNumber(0.0) == "0.0")
assert(Writer:formatNumber(0.1) == "0.1")
assert(Writer:formatNumber(0x12345678) == "0x12345678")
assert(Writer:formatNumber(305419896) == "0x12345678")
assert(Writer:formatNumber(123.1) == "123.1")
