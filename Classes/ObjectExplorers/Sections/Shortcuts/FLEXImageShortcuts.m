//
//  FLEXImageShortcuts.m
//  FLEX
//
//  Created by Tanner Bennett on 8/29/19.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXImageShortcuts.h"
#import "FLEXImagePreviewViewController.h"
#import "FLEXShortcut.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface UIAlertController (FLEXImageShortcuts)
- (void)flex_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context;
@end

@implementation FLEXImageShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIImage *)image {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:image additionalRows:@[
        [FLEXActionShortcut title:@"查看图片" subtitle:nil
            viewer:^UIViewController *(id image) {
                return [FLEXImagePreviewViewController forImage:image];
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [FLEXActionShortcut title:@"保存图片" subtitle:nil
            selectionHandler:^(UIViewController *host, id image) {
                // Present modal alerting user about saving
                UIAlertController *alert = [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(@"正在保存图片…");
                }];
                [host presentViewController:alert animated:YES completion:nil];
            
                // Save the image
                UIImageWriteToSavedPhotosAlbum(
                    image, alert, @selector(flex_image:disSaveWithError::), nil
                );
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end


@implementation UIAlertController (FLEXImageShortcuts)

- (void)flex_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context {
    self.title = @"图片已保存";
    flex_dispatch_after(1, dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
