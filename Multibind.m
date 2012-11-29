/*
 * Copyright (c) 2012, Nate Stedman <natesm@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby
 * granted, provided that the above copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#import <objc/runtime.h>
#import "Multibind.h"

@implementation MBArray

+(id)arrayWithValues:(id*)values count:(NSUInteger)count
{
    MBArray* array = [MBArray new];
    
    if (array)
    {
        array->count = count;
        array->values = (__strong id*)calloc(count, sizeof(id));
        
        for (NSUInteger i = 0; i < count; i++)
        {
            array->values[i] = values[i];
        }
    }
    
    return array;
}

-(void)dealloc
{
    for (NSUInteger i = 0; i < count; i++)
    {
        values[i] = nil;
    }
    
    free(values);
}

-(id)objectAtIndexedSubscript:(NSUInteger)subscript
{
    return values[subscript];
}

@end

@interface MBBindingPair : NSObject
@property (readwrite, unsafe_unretained) id object;
@property (readwrite, strong) NSString* keyPath;
@end

@implementation MBBindingPair

-(NSString*)description
{
    return [[super description] stringByAppendingFormat:@" (%@ -> %@)", _object, _keyPath];
}

@end

id MBPair(id object, NSString* keyPath)
{
    MBBindingPair* pair = [MBBindingPair new];
    pair.object = object;
    pair.keyPath = [keyPath copy];
    return pair;
}

@interface MBBinding : NSObject
{
@private
    __unsafe_unretained id object;
    NSString* keyPath;
    NSArray* pairs;
    MBBlock block;
}

-(id)initWithTargetObject:(id)object keyPath:(NSString*)keyPath pairs:(NSArray*)pairs block:(MBBlock)block;

@end

@implementation MBBinding

-(id)initWithTargetObject:(id)_object keyPath:(NSString*)_keyPath pairs:(NSArray*)_pairs block:(MBBlock)_block
{
    self = [self init];
    
    if (self)
    {
        pairs = _pairs;
        object = _object;
        keyPath = [_keyPath copy];
        block = [_block copy];
        
        for (MBBindingPair* pair in pairs)
        {
            [pair.object addObserver:self forKeyPath:pair.keyPath options:0 context:NULL];
        }
        
        [self observeValueForKeyPath:nil ofObject:nil change:nil context:NULL];
    }
    
    return self;
}

-(void)dealloc
{
    for (MBBindingPair* pair in pairs)
    {
        [pair.object removeObserver:self forKeyPath:pair.keyPath];
    }
}

-(void)observeValueForKeyPath:(NSString*)path ofObject:(id)obj change:(NSDictionary*)change context:(void*)context
{
    NSUInteger count = pairs.count;
    __autoreleasing id values[count];
    
    for (NSUInteger i = 0; i < count; i++)
    {
        MBBindingPair* pair = [pairs objectAtIndex:i];
        values[i] = [pair.object valueForKeyPath:pair.keyPath];
    }
    
    MBArray* array = [MBArray arrayWithValues:values count:count];
    [object setValue:block(array) forKeyPath:keyPath];
}

@end

@implementation NSObject (Multibind)

static char MBAssociatedKey;

-(void)mb_bind:(NSString*)keyPath toObjectAndKeyPathPairs:(NSArray*)pairs withBlock:(MBBlock)block
{
    NSMutableDictionary* bindings = objc_getAssociatedObject(self, &MBAssociatedKey);
    if (!bindings)
    {
        bindings = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(self, &MBAssociatedKey, bindings, OBJC_ASSOCIATION_RETAIN);
    }
    
    MBBinding* binding = [[MBBinding alloc] initWithTargetObject:self keyPath:keyPath pairs:pairs block:block];
    [bindings setObject:binding forKey:keyPath];
}

-(void)mb_unbind:(NSString*)keyPath
{
    NSMutableDictionary* bindings = objc_getAssociatedObject(self, &MBAssociatedKey);
    [bindings removeObjectForKey:keyPath];
    
    if (bindings.count == 0)
    {
        objc_setAssociatedObject(self, &MBAssociatedKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

@end
