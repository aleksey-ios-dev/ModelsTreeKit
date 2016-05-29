//
//  ProxyWrapper.h
//  ModelsTreeKit
//
//  Created by aleksey on 28.05.16.
//  Copyright © 2016 aleksey chernish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ControlTarget : NSObject

- (void)someMethod;

@end

@interface ControlProxy : NSProxy

- (instancetype)initWithObject: (id)object;
- (void)registerBlock: (void (^)(void))block forKey: (NSString *)key;

@end
