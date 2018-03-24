//
//  NSObject+KYHooker.h
//  Hooer
//
//  Created by Kyrios_Ark on 2018/3/4.
//  Copyright © 2018年 Kyrios_Ark. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KYHookPosition) {
    KYHookPositionBefore,
    KYHookPositionReplace,
    KYHookPositionAfter,
};

@interface NSObject (KYHooker)
/**
 Adds a block of code before/replace/after the selector for a specific class with an identifer.
 You can remove or override the block of code for a specific hook with the identifer.
 
 @param isInstanceMethod the selector you want to hook is instance method or not
 @param block the code you wan to adds,block will return an invocation ,you can get the original method params from invocation
 - (void)getArgument:(void *)argumentLocation atIndex:(NSInteger)idx;
 @note the first argument of the invocation is the object which calling the method,and the second argument is _cmd

 @return Hook success or not
 */

+ (BOOL)ky_hookSelector:(SEL)selector
    isInstanceMethod:(BOOL)isInstanceMethod
        position:(KYHookPosition)position
          identifier:(NSString *)identifier
              withBlock:(void(^ _Nullable )(NSInvocation *invocation))block;
/**
 Remove the block of code which added before/replace/after the selector for a specific class with an identifer.
 
 @param isInstanceMethod the selector you want to hook is instance method or not
 */

+ (void)ky_removeHookForSelector:(SEL)selector
                isInstanceMethod:(BOOL)isInstanceMethod
                      identifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END


