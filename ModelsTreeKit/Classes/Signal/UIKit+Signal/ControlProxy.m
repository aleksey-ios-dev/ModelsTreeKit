//
//  ProxyWrapper.m
//  ModelsTreeKit
//
//  Created by aleksey on 28.05.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

#import "ControlProxy.h"

@interface ControlTarget()

@property (nonatomic, strong) NSMutableDictionary *blocks;


@end

@implementation ControlTarget

- (instancetype)init {
  if (self = [super init]) {
    _blocks = [NSMutableDictionary new];
  }
  
  return self;
}

- (void)someMethod {
  
}


- (void)registerBlock: (void (^)(void))block forKey: (NSString *)key {
  _blocks[key] = block;
}

- (void)fireBlockforKey: (NSString *)key {
  void (^block)(void) = _blocks[key];
  if  (block) {
    block();
  }
  
}


@end

@interface ControlProxy()

@property (nonatomic, strong) ControlTarget *target;

@end

@implementation ControlProxy

- (instancetype)initWithObject: (id)object  {
  _target = [ControlTarget new];
  
  return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  NSString *key = NSStringFromSelector(invocation.selector);
  [_target fireBlockforKey:key];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
  return [_target methodSignatureForSelector:@selector(someMethod)];
}

- (void)registerBlock: (void (^)(void)) block forKey: (NSString *)key {
  [_target registerBlock:block forKey:key];
}

@end
