//
//  FLEXBundleShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 12/12/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXBundleShortcuts.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"
#import "FLEXRuntimeExporter.h"
#import "FLEXTableListViewController.h"
#import "FLEXFileBrowserController.h"

#pragma mark -
@implementation FLEXBundleShortcuts
#pragma mark Overrides

+ (instancetype)forObject:(NSBundle *)bundle { weakify(self)
    return [self forObject:bundle additionalRows:@[
        [FLEXActionShortcut
            title:@"浏览 Bundle 目录" subtitle:nil
            viewer:^UIViewController *(NSBundle *bundle) {
                return [FLEXFileBrowserController path:bundle.bundlePath];
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"将 Bundle 作为数据库浏览…" subtitle:nil
            selectionHandler:^(UIViewController *host, NSBundle *bundle) { strongify(self)
                [self promptToExportBundleAsDatabase:bundle host:host];
            }
            accessoryType:^UITableViewCellAccessoryType(NSBundle *bundle) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
    ]];
}

+ (void)promptToExportBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"另存为…").message(
            @"数据库将保存在 Library 文件夹中。根据类的数量，导出可能需要 10 分钟或更长时间。20000 个类大约需要 7 分钟。"
        );
        make.configuredTextField(^(UITextField *field) {
            field.placeholder = @"FLEXRuntimeExport.objc.db";
            field.text = [NSString stringWithFormat:
                @"%@.objc.db", bundle.executablePath.lastPathComponent
            ];
        });
        make.button(@"开始").handler(^(NSArray<NSString *> *strings) {
            [self browseBundleAsDatabase:bundle host:host name:strings[0]];
        });
        make.button(@"取消").cancelStyle();
    } showFrom:host];
}

+ (void)browseBundleAsDatabase:(NSBundle *)bundle host:(UIViewController *)host name:(NSString *)name {
    NSParameterAssert(name.length);

    UIAlertController *progress = [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"正在生成数据库");
        // Some iOS version glitch out of there is
        // no initial message and you add one later
        make.message(@"…");
    }];

    [host presentViewController:progress animated:YES completion:^{
        // Generate path to store db
        NSString *path = [NSSearchPathForDirectoriesInDomains(
            NSLibraryDirectory, NSUserDomainMask, YES
        )[0] stringByAppendingPathComponent:name];

        progress.message = [path stringByAppendingString:@"\n\n正在创建数据库…"];

        // Generate db and show progress
        [FLEXRuntimeExporter createRuntimeDatabaseAtPath:path
            forImages:@[bundle.executablePath]
            progressHandler:^(NSString *status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress.message = [progress.message
                        stringByAppendingFormat:@"\n%@", status
                    ];
                    [progress.view setNeedsLayout];
                    [progress.view layoutIfNeeded];
                });
            } completion:^(NSString *error) {
                // Display error if any
                if (error) {
                    progress.title = @"错误";
                    progress.message = error;
                    [progress addAction:[UIAlertAction
                        actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]
                    ];
                }
                // Browse database
                else {
                    [progress dismissViewControllerAnimated:YES completion:nil];
                    [host.navigationController pushViewController:[
                        [FLEXTableListViewController alloc] initWithPath:path
                    ] animated:YES];
                }
            }
        ];
    }];
}

@end
