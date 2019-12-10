local Queue = require('lib.queue')

_G['unpack'] = table.unpack

describe("Queue testing", function()
    it("Should be created as a function call", function()
        local q = Queue()
        assert.truthy(q)
    end)

    it("Should be appendable", function()
        local q = Queue()
        q:push(1)
        q:push(2)
        q:push(3)
        assert.are.equal(3, q:size())
        assert.are.equal(1, q:peek())
        assert.are.equal(1, q:shift())
        assert.are.equal(2, q:peek())
        assert.are.equal(3, q:last())
        assert.are.equal(2, q:shift())
        assert.are.equal(3, q:shift())
        assert.are.equal(nil, q:shift())
        assert.are.equal(true, q:isEmpty())
    end)

    it("Can be created from an array", function()
        local q = Queue.fromArray({100, 2, 3, 54})
        assert.truthy(q)
        assert.are.equal(100, q:peek())
        assert.are.equal(54, q:last())
    end)
end)