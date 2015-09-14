describe 'up.util', ->
  
  describe 'Javascript functions', ->

    describe 'up.util.castedAttr', ->

      it 'returns true if the attribute value is the string "true"', ->
        $element = affix('div').attr('foo', 'true')
        expect(up.util.castedAttr($element, 'foo')).toBe(true)

      it 'returns false if the attribute value is the string "false"', ->
        $element = affix('div').attr('foo', 'false')
        expect(up.util.castedAttr($element, 'foo')).toBe(false)

      it 'returns undefined if the element has no such attribute', ->
        $element = affix('div')
        expect(up.util.castedAttr($element, 'foo')).toBe(undefined)

      it 'returns the attribute value unchanged if the value is some string', ->
        $element = affix('div').attr('foo', 'some text')
        expect(up.util.castedAttr($element, 'foo')).toBe('some text')

    describe 'up.util.isBlank', ->
  
      it 'returns false for false', ->
        expect(up.util.isBlank(false)).toBe(false)
        
      it 'returns false for true', ->
        expect(up.util.isBlank(true)).toBe(false)
  
      it 'returns true for null', ->
        expect(up.util.isBlank(null)).toBe(true)
        
      it 'returns true for undefined', ->
        expect(up.util.isBlank(undefined)).toBe(true)
        
      it 'returns true for an empty String', ->
        expect(up.util.isBlank('')).toBe(true)
        
      it 'returns false for a String with at least one character', ->
        expect(up.util.isBlank('string')).toBe(false)
        
      it 'returns true for an empty array', ->
        expect(up.util.isBlank([])).toBe(true)
        
      it 'returns false for an array with at least one element', ->
        expect(up.util.isBlank(['element'])).toBe(false)

      it 'returns true for an empty object', ->
        expect(up.util.isBlank({})).toBe(true)

      it 'returns true for an object with at least one key', ->
        expect(up.util.isBlank({key: 'value'})).toBe(false)

    describe 'up.util.normalizeUrl', ->

      it 'normalizes a relative path', ->
        expect(up.util.normalizeUrl('foo')).toBe("http://#{location.hostname}:#{location.port}/foo")

      it 'normalizes an absolute path', ->
        expect(up.util.normalizeUrl('/foo')).toBe("http://#{location.hostname}:#{location.port}/foo")

      it 'normalizes a full URL', ->
        expect(up.util.normalizeUrl('http://example.com/foo/bar')).toBe('http://example.com/foo/bar')

    describe 'up.util.detect', ->

      it 'finds the first element in the given array that matches the given tester', ->
        array = ['foo', 'bar', 'baz']
        tester = (element) -> element[0] == 'b'
        expect(up.util.detect(array, tester)).toEqual('bar')

      it "returns null if the given array doesn't contain a matching element", ->
        array = ['foo', 'bar', 'baz']
        tester = (element) -> element[0] == 'z'
        expect(up.util.detect(array, tester)).toBeNull()

    describe 'up.util.config', ->

      it 'creates an object with the given attributes', ->
        object = up.util.config(a: 1, b: 2)
        expect(object.a).toBe(1)
        expect(object.b).toBe(2)

      describe '#update', ->

        it 'merges the given options into the object', ->
          object = up.util.config(a: 1, b: undefined, c: undefined)
          object.update(b: 2, c: 3)
          expect(object.b).toBe(2)
          expect(object.c).toBe(3)

        it 'returns the current hash when called without arguments', ->
          object = up.util.config(a: 1, b: 2)
          result = object.update()
          expect(result.a).toBe(1)
          expect(result.b).toBe(2)

        it 'throws an error when setting a key that was not included in the factory settings', ->
          object = up.util.config(a: 1)
          update = -> object.update(b: 2)
          expect(update).toThrowError(/unknown setting/i)

      describe '#reset', ->

        it 'resets the object to its original state', ->
          object = up.util.config(a: 1)
          expect(object.b).toBeUndefined()
          object.b = 2
          expect(object.b).toBe(2)
          object.reset()
          expect(object.b).toBeUndefined()

        it 'does not remove #reset or #update methods from the object', ->
          object = up.util.config(a: 1)
          object.b = 2
          object.reset()
          expect(object.reset).toBeDefined()
          expect(object.update).toBeDefined()
