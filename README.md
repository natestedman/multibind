# multibind
Objective-C category on `NSObject` for binding to multiple sources. For example, a cell displays an attributed string that depends on both the object represented by the cell and some global font settings. Or anything that takes varying inputs and combines them into one.

## Usage
The first function is `MBPair(id object, NSString* keyPath)`. These represent the objects and key paths that will trigger your binding.

Build an array of objects returned from `MBPair`:

```
NSArray* pairs = @[MBPair(foo, @"something"), MBPair(bar, @"another.thing"];
```

The `object` parameter is not retained, because that would make this entire thing broken.

Multibind uses a block to consolidate your observered parameters into one returned value. It receives an `MBArray` instance, which implements only `-(id)objectAtIndexedSubscript:(NSUInteger)subscript`. `nil` values will be returned as `nil`, not `[NSNull null]` (although `[NSNull null]` could, of course, be included if one of your observed key paths is set to it).

Now, since I just mentioned retain cycles and not strongly retaining things, don't do that in the block either.

    [self mb_bind:@"stream" toObjectAndKeyPathPairs:pairs withBlock:^id(MBArray* values) {
        id something = values[0];
        id anotherThing = values[1];
        
        // return a value...
        return [something stringByAppendingFormat:@"%@", anotherThing];
    }];

## Cleanup
Do this so that your program doesn't crash: in `dealloc`, call `mb_unbind:` or `mb_unbindAll`. Or whenever you want to unbind something for another reason.

## Including
Usually I'd make a proper project and static library/framework targets, but it's two files.

## License
Copyright (c) 2012, Nate Stedman <natesm@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
