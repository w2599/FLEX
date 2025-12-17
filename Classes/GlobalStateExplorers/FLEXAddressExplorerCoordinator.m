//
//  FLEXAddressExplorerCoordinator.m
//  FLEX
//
//  Created by Tanner Bennett on 7/10/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXAddressExplorerCoordinator.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXUtility.h"

@interface UITableViewController (FLEXAddressExploration)
- (void)deselectSelectedRow;
- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely;
@end

@implementation FLEXAddressExplorerCoordinator

#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"🔎  地址探索器";
}

+ (FLEXGlobalsEntryRowAction)globalsEntryRowAction:(FLEXGlobalsRow)row {
    return ^(UITableViewController *host) {

        NSString *title = @"按地址探索对象";
        NSString *message = @"在下方粘贴十六进制地址，需以 '0x' 开头。\n如果需要绕过指针校验可使用“不安全探索”，但地址无效可能导致应用崩溃。";

        [FLEXAlert makeAlert:^(FLEXAlert *make) {
            make.title(title).message(message);
            make.configuredTextField(^(UITextField *textField) {
                NSString *copied = UIPasteboard.generalPasteboard.string;
                textField.placeholder = @"0x00000070deadbeef";
                // Go ahead and paste our clipboard if we have an address copied
                if ([copied hasPrefix:@"0x"]) {
                    textField.text = copied;
                    [textField selectAll:nil];
                }
            });
            make.button(@"探索").handler(^(NSArray<NSString *> *strings) {
                [host tryExploreAddress:strings.firstObject safely:YES];
            });
            make.button(@"不安全探索").destructiveStyle().handler(^(NSArray *strings) {
                [host tryExploreAddress:strings.firstObject safely:NO];
            });
            make.button(@"取消").cancelStyle();
        } showFrom:host];

    };
}

@end

@implementation UITableViewController (FLEXAddressExploration)

- (void)deselectSelectedRow {
    NSIndexPath *selected = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:selected animated:YES];
}

- (void)tryExploreAddress:(NSString *)addressString safely:(BOOL)safely {
    NSScanner *scanner = [NSScanner scannerWithString:addressString];
    unsigned long long hexValue = 0;
    BOOL didParseAddress = [scanner scanHexLongLong:&hexValue];
    const void *pointerValue = (void *)hexValue;

    NSString *error = nil;

    if (didParseAddress) {
        if (safely && ![FLEXRuntimeUtility pointerIsValidObjcObject:pointerValue]) {
            error = @"该地址不太可能是有效的对象。";
        }
    } else {
        error = @"地址格式不正确。请确保以 '0x' 开头并且长度合适。";
    }

    if (!error) {
        id object = (__bridge id)pointerValue;
        FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:object];
        [self.navigationController pushViewController:explorer animated:YES];
    } else {
        [FLEXAlert showAlert:@"出错了" message:error from:self];
        [self deselectSelectedRow];
    }
}

@end
