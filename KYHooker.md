# KYHooker

KYHooker allows you adds block of code before/replace/after the selector,and you can manage the block with the identifer,remove or override the code you adds.

KYHooker extends NSObject with the following methods:

```JS
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

```

Examples:
here is the method we hooked:
```JS
+ (void)logMessage:(NSString *)message {
    NSLog(@"%@",message);
}
```

hook the method:
```JS
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"1" withBlock:^(NSInvocation *invocation){
        NSLog(@"I");
    }];
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"2" withBlock:^(NSInvocation *invocation){
        NSLog(@"Love");
    }];
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"3" withBlock:^(NSInvocation *invocation) {
        NSLog(@"Coding");
    }];
    [ViewController logMessage:@"hello world"];
```
the logs:
```JS
hello world
I
Love
Coding
```
you can override the block you adds by adding:
```JS
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"3" withBlock:^(NSInvocation *invocation) {
        NSLog(@"Girls");
    }];

```
the logs:
```JS
hello world
I
Love
Girls
```
and you can remove the block you adds by adding:
```JS
[ViewController ky_removeHookForSelector:@selector(logMessage:) isInstanceMethod:NO identifier:@"1"];
```
the logs:
```JS
hello world
Love
Girls
```


