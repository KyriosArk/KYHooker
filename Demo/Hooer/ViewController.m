//
//  ViewController.m
//  Hooer
//
//  Created by Aaron_Ren on 2018/3/4.
//  Copyright © 2018年 Aaron_Ren. All rights reserved.
//

#import "ViewController.h"
#import "KYHooker.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"1" withBlock:^(NSInvocation *invocation){
        NSLog(@"I");
    }];
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"2" withBlock:^(NSInvocation *invocation){
        NSLog(@"Love");
    }];
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"3" withBlock:^(NSInvocation *invocation) {
        NSLog(@"Coding");
    }];
    [ViewController ky_hookSelector:@selector(logMessage:) isInstanceMethod:NO position:KYHookPositionAfter identifier:@"3" withBlock:^(NSInvocation *invocation) {
        NSLog(@"Girls");
    }];
    [ViewController ky_removeHookForSelector:@selector(logMessage:) isInstanceMethod:NO identifier:@"1"];
}

+ (void)logMessage:(NSString *)message {
    NSLog(@"%@",message);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [ViewController logMessage:@"hello world"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
