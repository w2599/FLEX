//
//  FLEXObjcRuntimeViewController.m
//  FLEX
//
//  Created by Tanner on 3/23/17.
//  Copyright © 2017 Tanner Bennett. All rights reserved.
//

#import "FLEXObjcRuntimeViewController.h"
#import "FLEXKeyPathSearchController.h"
#import "FLEXRuntimeBrowserToolbar.h"
#import "UIGestureRecognizer+Blocks.h"
#import "UIBarButtonItem+FLEX.h"
#import "FLEXTableView.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXAlert.h"
#import "FLEXRuntimeClient.h"
#import <dlfcn.h>

@interface FLEXObjcRuntimeViewController () <FLEXKeyPathSearchControllerDelegate>

@property (nonatomic, readonly ) FLEXKeyPathSearchController *keyPathController;
@property (nonatomic, readonly ) UIView *promptView;

@end

@implementation FLEXObjcRuntimeViewController

#pragma mark - Setup, view events

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Long press on navigation bar to initialize webkit legacy
    //
    // We call initializeWebKitLegacy automatically before you search
    // all bundles just to be safe (since touching some classes before
    // WebKit is initialized will initialize it on a thread other than
    // the main thread), but sometimes you can encounter this crash
    // without searching through all bundles, of course.
    [self.navigationController.navigationBar addGestureRecognizer:[
        [UILongPressGestureRecognizer alloc]
            initWithTarget:[FLEXRuntimeClient class]
            action:@selector(initializeWebKitLegacy)
        ]
    ];
    
    [self addToolbarItems:@[FLEXBarButtonItem(@"dlopen()", self, @selector(dlopenPressed:))]];
    
    // Search bar stuff, must be first because this creates self.searchController
    self.showsSearchBar = YES;
    self.showSearchBarInitially = YES;
    self.activatesSearchBarAutomatically = YES;
    // Using pinSearchBar on this screen causes a weird visual
    // thing on the next view controller that gets pushed.
    //
    // self.pinSearchBar = YES;
    self.searchController.searchBar.placeholder = @"UIKit*.UIView.-setFrame:";

    // Search controller stuff
    // key path controller automatically assigns itself as the delegate of the search bar
    // To avoid a retain cycle below, use local variables
    UISearchBar *searchBar = self.searchController.searchBar;
    FLEXKeyPathSearchController *keyPathController = [FLEXKeyPathSearchController delegate:self];
    _keyPathController = keyPathController;
    _keyPathController.toolbar = [FLEXRuntimeBrowserToolbar toolbarWithHandler:^(NSString *text, BOOL suggestion) {
        if (suggestion) {
            [keyPathController didSelectKeyPathOption:text];
        } else {
            [keyPathController didPressButton:text insertInto:searchBar];
        }
    } suggestions:keyPathController.suggestions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


#pragma mark dlopen

/// Prompt user for dlopen shortcuts to choose from
- (void)dlopenPressed:(id)sender {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"动态打开库");
        make.message(@"使用给定路径调用 dlopen()。请选择下面的一个选项。");
        
        make.button(@"系统框架").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:@"/System/Library/Frameworks/%@.framework/%@"];
        });
        make.button(@"系统私有框架").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:@"/System/Library/PrivateFrameworks/%@.framework/%@"];
        });
        make.button(@"任意二进制").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:nil];
        });
        
        make.button(@"取消").cancelStyle();
    } showFrom:self];
}

/// Prompt user for input and dlopen
- (void)dlopenWithFormat:(NSString *)format {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"动态打开库");
        if (format) {
            make.message(@"输入框架名称，例如 CarKit 或 FrontBoard。");
        } else {
            make.message(@"输入指向二进制文件的绝对路径。");
        }
        
        make.textField(format ? @"ARKit" : @"/System/Library/Frameworks/ARKit.framework/ARKit");
        
        make.button(@"取消").cancelStyle();
        make.button(@"打开").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            NSString *path = strings[0];
            
            if (path.length < 2) {
                [self dlopenInvalidPath];
            } else if (format) {
                path = [NSString stringWithFormat:format, path, path];
            }
            
            if (!dlopen(path.UTF8String, RTLD_NOW)) {
                [FLEXAlert makeAlert:^(FLEXAlert *make) {
                        make.title(@"错误").message(@(dlerror()));
                        make.button(@"关闭").cancelStyle();
                }];
            }
        });
    } showFrom:self];
}

- (void)dlopenInvalidPath {
    [FLEXAlert makeAlert:^(FLEXAlert * _Nonnull make) {
        make.title(@"路径或名称过短");
        make.button(@"关闭").cancelStyle();
    } showFrom:self];
}


#pragma mark Delegate stuff

- (void)didSelectImagePath:(NSString *)path shortName:(NSString *)shortName {
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(shortName);
        make.message(@"此路径未关联任何 NSBundle：\\n\\n");
        make.message(path);

        make.button(@"复制路径").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = path;
        });
        make.button(@"关闭").cancelStyle();
    } showFrom:self];
}

- (void)didSelectBundle:(NSBundle *)bundle {
    NSParameterAssert(bundle);
    FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:bundle];
    [self.navigationController pushViewController:explorer animated:YES];
}

- (void)didSelectClass:(Class)cls {
    NSParameterAssert(cls);
    FLEXObjectExplorerViewController *explorer = [FLEXObjectExplorerFactory explorerViewControllerForObject:cls];
    [self.navigationController pushViewController:explorer animated:YES];
}


#pragma mark - FLEXGlobalsEntry

+ (NSString *)globalsEntryTitle:(FLEXGlobalsRow)row {
    return @"📚  运行时浏览器";
}

+ (UIViewController *)globalsEntryViewController:(FLEXGlobalsRow)row {
    UIViewController *controller = [self new];
    controller.title = [self globalsEntryTitle:row];
    return controller;
}

@end
