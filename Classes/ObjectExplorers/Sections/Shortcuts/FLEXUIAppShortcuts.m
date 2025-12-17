//
//  FLEXUIAppShortcuts.m
//  FLEX
//
//  Created by Tanner on 5/25/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXUIAppShortcuts.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"

@implementation FLEXUIAppShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIApplication *)application {
    return [self forObject:application additionalRows:@[
        [FLEXActionShortcut title:@"Open URL…"
            subtitle:^NSString *(UIViewController *controller) {
                return nil;
            }
            selectionHandler:^void(UIViewController *host, UIApplication *app) {
                [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(@"打开 URL");
                    make.message(
                        @"这将调用 openURL: 或 openURL:options:completion:，使用下面的字符串。'仅在为通用链接时打开' 仅在链接为已注册的通用链接时打开。"
                    );
                    
                    make.textField(@"twitter://user?id=12345");
                    make.button(@"打开").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:NO host:host];
                    });
                    make.button(@"如果是通用链接则打开").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:YES host:host];
                    });
                    make.button(@"取消").cancelStyle();
                } showFrom:host];
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

+ (void)openURL:(NSString *)urlString
          inApp:(UIApplication *)app
 onlyIfUniveral:(BOOL)universalOnly
           host:(UIViewController *)host {
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (url) {
        [app openURL:url options:@{
            UIApplicationOpenURLOptionUniversalLinksOnly: @(universalOnly)
        } completionHandler:^(BOOL success) {
            if (!success) {
                [FLEXAlert showAlert:@"无通用链接处理程序"
                    message:@"没有已安装的应用程序注册来处理此链接。"
                    from:host
                ];
            }
        }];
    } else {
        [FLEXAlert showAlert:@"Error" message:@"Invalid URL" from:host];
    }
}

@end

