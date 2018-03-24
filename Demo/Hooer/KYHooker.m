//
//  NSObject+Hooker.m
//  Hooer
//
//  Created by Kyrios_Ark on 2018/3/4.
//  Copyright © 2018年 Kyrios_Ark. All rights reserved.
//

#import "KYHooker.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <pthread.h>

static NSString *const KYHookerPrefix = @"ky_hook";

@interface KYHookRecord : NSObject
@property IMP originalIMP;
@property SEL selector;
@end

@implementation KYHookRecord
@end


@implementation NSObject (KYHooker)

#pragma mark - Public

+ (void)ky_removeHookForSelector:(SEL)selector isInstanceMethod:(BOOL)isInstanceMethod identifier:(NSString *)identifier {
    [self ky_hookSelector:selector isInstanceMethod:isInstanceMethod position:KYHookPositionAfter identifier:identifier withBlock:nil];
}

+ (void)markHookerWithSelector:(SEL)selector newSelector:(SEL)newSelector isInstanceMethod:(BOOL)isInstanceMethod {
    NSMutableDictionary *hookerMap = [self hookerMap];
    NSString *key = [self mapKeyForSelector:newSelector isInstanceMethod:isInstanceMethod];
    KYHookRecord *hooker = hookerMap[key];
    if (!hooker) {
        hooker = [KYHookRecord new];
        hooker.selector = selector;
        hooker.originalIMP = class_getMethodImplementation(self, selector);
        hookerMap[key] = hooker;
    }
}

#pragma mark - Private

+ (NSMutableDictionary *)hookerMap {
    static NSMutableDictionary *hookerMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hookerMap = @{}.mutableCopy;
    });
    return hookerMap;
}


+ (BOOL)ky_hookSelector:(SEL)selector
    isInstanceMethod:(BOOL)isInstanceMethod
        position:(KYHookPosition)position
          identifier:(NSString *)identifier
           withBlock:(void(^ _Nullable )(NSInvocation *invocation))block {
    pthread_mutex_t _lock;
    pthread_mutex_init(&_lock, NULL);
    pthread_mutex_lock(&_lock);
    Class class = isInstanceMethod ? self : [self class];
    IMP blockImp = block ? imp_implementationWithBlock(block) : NULL;
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"%@_%@_%@",KYHookerPrefix,identifier,NSStringFromSelector(selector)]);
    
    BOOL existMethod = NO;
    if (!isInstanceMethod) {
        Class metaClass = object_getClass(class);
        existMethod = [self checkMethodListWithClass:metaClass ForSelector:selector];
        class = metaClass;
    } else {
        existMethod = [self checkMethodListWithClass:class ForSelector:selector];
    }
    if (!existMethod) {
        return NO;
    }
    
    [class markHookerWithSelector:selector newSelector:newSelector isInstanceMethod:isInstanceMethod];
    NSMethodSignature *originalMethodSignature = isInstanceMethod ? [self instanceMethodSignatureForSelector:selector] : [self methodSignatureForSelector:selector];
    if (!originalMethodSignature) {
        NSAssert(false, @"MethodSignature is nil");
        return NO;
    }
    NSInvocation *originalInvocation = [NSInvocation invocationWithMethodSignature:originalMethodSignature];
    id replaceBlock = ^id(id target,...){
        va_list args;
        va_start(args, target);
        SEL sel = selector;
        [originalInvocation setArgument:&target atIndex:0];
        [originalInvocation setArgument:&sel atIndex:1];
        if (target) {
            int i = 2;//start after self && _cmd
            while (1)
            {
                NSInteger count = originalInvocation.methodSignature.numberOfArguments;
                count -= i;
                if (count > 0) {
                    void* argument = va_arg(args, void*);
                    if(argument == NULL)
                        break;
                    else
                        [originalInvocation setArgument:&argument atIndex:i++];
                } else {
                    break;
                }
            }
        }
        va_end(args);
        
        if (position == KYHookPositionBefore) {
            block ? block(originalInvocation) : nil;
        } else if (position == KYHookPositionReplace) {
            block ? block(originalInvocation) : nil;
            return nil;
        }
        id returnValue = [target performSelector:newSelector inInvocation:originalInvocation signature:originalMethodSignature];
        
        if (position == KYHookPositionAfter) {
            block ? block(originalInvocation) : nil;
        }
        return returnValue;
    };
    
    Method hookMethod = class_getInstanceMethod(class, selector);
    IMP replaceImp = imp_implementationWithBlock([replaceBlock copy]);
    if (![class instancesRespondToSelector:newSelector]) {
        class_addMethod(class, newSelector, blockImp, method_getTypeEncoding(hookMethod));
        class_replaceMethod(class, newSelector, replaceImp, method_getTypeEncoding(hookMethod));
        [class swizzleClass:class method:selector with:newSelector];
    } else {
        class_replaceMethod(class, selector, replaceImp, method_getTypeEncoding(hookMethod));
    }
    pthread_mutex_unlock(&_lock);
    pthread_mutex_destroy(&_lock);
    return YES;
}


+ (BOOL)checkMethodListWithClass:(Class)class ForSelector:(SEL)selector {
    u_int count;
    Method *methodList = class_copyMethodList(class, &count);
    for (int i = 0; i < count; i++) {
        Method method = methodList[i];
        SEL sel_name = method_getName(method);
        if ([NSStringFromSelector(sel_name) isEqualToString:NSStringFromSelector(selector)]) {
            return YES;
        }
    }
    free(methodList);
    return NO;
}

+ (NSString *)mapKeyForSelector:(SEL)selector isInstanceMethod:(BOOL)isInstanceMethod {
    NSString *instanceKey = isInstanceMethod ? @"_instance" : @"";
    return [NSString stringWithFormat:@"%@%@_%@",NSStringFromClass([self class]),instanceKey,NSStringFromSelector(selector)];
}

- (id)performSelector:(SEL)aSelector
         inInvocation:(NSInvocation *)originalInvocation
            signature:(NSMethodSignature *)signature {
    
    if (signature == nil) {
        NSAssert(false, @"could not found method");
        return nil;
    }
    
    originalInvocation.target = self;
    originalInvocation.selector = aSelector;
    
    [originalInvocation invoke];
    
    __autoreleasing id returnValue = nil;
    if ([[NSString stringWithCString:signature.methodReturnType encoding:NSUTF8StringEncoding] isEqualToString:@"v"]) {
        return returnValue;
    }
    [originalInvocation getReturnValue:&returnValue];
    return returnValue;
}

+ (void)swizzleClass:(Class)class method:(SEL)originalSelector with:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end

