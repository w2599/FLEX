//
//  FLEXWindowManagerController.m
//  FLEX
//
//  Created by Tanner on 2/6/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXWindowManagerController.h"
#import "FLEXManager+Private.h"
#import "FLEXUtility.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXWindowManagerController ()
@property (nonatomic) UIWindow *keyWindow;
@property (nonatomic, copy) NSString *keyWindowSubtitle;
@property (nonatomic, copy) NSArray<UIWindow *> *windows;
@property (nonatomic, copy) NSArray<NSString *> *windowSubtitles;
@property (nonatomic, copy) NSArray<UIScene *> *scenes API_AVAILABLE(ios(13));
@property (nonatomic, copy) NSArray<NSString *> *sceneSubtitles;
@property (nonatomic, copy) NSArray<NSArray *> *sections;
@end

@implementation FLEXWindowManagerController

#pragma mark - Initialization

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"窗口";
    if (@available(iOS 13, *)) {
        self.title = @"窗口与场景";
    }
    
    [self disableToolbar];
    [self reloadData];
}


#pragma mark - Private

- (void)reloadData {
    self.keyWindow = UIApplication.sharedApplication.keyWindow;
    self.windows = UIApplication.sharedApplication.windows;
    self.keyWindowSubtitle = self.windowSubtitles[[self.windows indexOfObject:self.keyWindow]];
    self.windowSubtitles = [self.windows flex_mapped:^id(UIWindow *window, NSUInteger idx) {
        return [NSString stringWithFormat:@"Level: %@ — Root: %@",
            @(window.windowLevel), window.rootViewController
        ];
    }];
    
    if (@available(iOS 13, *)) {
        self.scenes = UIApplication.sharedApplication.connectedScenes.allObjects;
        self.sceneSubtitles = [self.scenes flex_mapped:^id(UIScene *scene, NSUInteger idx) {
            return [self sceneDescription:scene];
        }];
        
        self.sections = @[@[self.keyWindow], self.windows, self.scenes];
    } else {
        self.sections = @[@[self.keyWindow], self.windows];
    }
    
    [self.tableView reloadData];
}

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showRevertOrDismissAlert:(void(^)(void))revertBlock {
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self reloadData];
    [self.tableView reloadData];
    
    UIWindow *highestWindow = UIApplication.sharedApplication.keyWindow;
    UIWindowLevel maxLevel = 0;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.windowLevel > maxLevel) {
            maxLevel = window.windowLevel;
            highestWindow = window;
        }
    }
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(@"保留更改？");
        make.message(@"如果你不想保留这些设置，请在下面选择“恢复更改”。");
        
        make.button(@"保留更改").destructiveStyle();
        make.button(@"保留更改并关闭").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [self dismissAnimated];
        });
        make.button(@"恢复更改").cancelStyle().handler(^(NSArray<NSString *> *strings) {
            revertBlock();
            [self reloadData];
            [self.tableView reloadData];
        });
    } showFrom:[FLEXUtility topViewControllerInWindow:highestWindow]];
}

- (NSString *)sceneDescription:(UIScene *)scene API_AVAILABLE(ios(13)) {
    NSString *state = [self stringFromSceneState:scene.activationState];
    NSString *title = scene.title.length ? scene.title : nil;
    NSString *suffix = nil;
    
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (id)scene;
        suffix = FLEXPluralString(windowScene.windows.count, @"windows", @"window");
    }
    
    NSMutableString *description = state.mutableCopy;
    if (title) {
        [description appendFormat:@" — %@", title];
    }
    if (suffix) {
        [description appendFormat:@" — %@", suffix];
    }
    
    return description.copy;
}

- (NSString *)stringFromSceneState:(UISceneActivationState)state API_AVAILABLE(ios(13)) {
    switch (state) {
        case UISceneActivationStateUnattached:
            return @"Unattached";
        case UISceneActivationStateForegroundActive:
            return @"Active";
        case UISceneActivationStateForegroundInactive:
            return @"Inactive";
        case UISceneActivationStateBackground:
            return @"Backgrounded";
    }
    
    return [NSString stringWithFormat:@"Unknown state: %@", @(state)];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Key Window";
        case 1: return @"Windows";
        case 2: return @"Connected Scenes";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFLEXDetailCell forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    UIWindow *window = nil;
    NSString *subtitle = nil;
    
    switch (indexPath.section) {
        case 0:
            window = self.keyWindow;
            subtitle = self.keyWindowSubtitle;
            break;
        case 1:
            window = self.windows[indexPath.row];
            subtitle = self.windowSubtitles[indexPath.row];
            break;
        case 2:
            if (@available(iOS 13, *)) {
                UIScene *scene = self.scenes[indexPath.row];
                cell.textLabel.text = scene.description;
                cell.detailTextLabel.text = self.sceneSubtitles[indexPath.row];
                return cell;
            }
    }
    
    cell.textLabel.text = window.description;
    cell.detailTextLabel.text = [NSString
        stringWithFormat:@"Level: %@ — Root: %@",
        @((NSInteger)window.windowLevel), window.rootViewController.class
    ];
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIWindow *window = nil;
    NSString *subtitle = nil;
    FLEXWindow *flex = FLEXManager.sharedManager.explorerWindow;
    
    id cancelHandler = ^{
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    };
    
    switch (indexPath.section) {
        case 0:
            window = self.keyWindow;
            subtitle = self.keyWindowSubtitle;
            break;
        case 1:
            window = self.windows[indexPath.row];
            subtitle = self.windowSubtitles[indexPath.row];
            break;
        case 2:
            if (@available(iOS 13, *)) {
                UIScene *scene = self.scenes[indexPath.row];
                UIWindowScene *oldScene = flex.windowScene;
                BOOL isWindowScene = [scene isKindOfClass:[UIWindowScene class]];
                BOOL isFLEXScene = isWindowScene ? flex.windowScene == scene : NO;
                
                [FLEXAlert makeAlert:^(FLEXAlert *make) {
                    make.title(NSStringFromClass(scene.class));
                    
                    if (isWindowScene) {
                        if (isFLEXScene) {
                            make.message(@"已是 FLEX 窗口场景");
                        }
                        
                        make.button(@"设为 FLEX 窗口场景")
                        .handler(^(NSArray<NSString *> *strings) {
                            flex.windowScene = (id)scene;
                            [self showRevertOrDismissAlert:^{
                                flex.windowScene = oldScene;
                            }];
                        }).enabled(!isFLEXScene);
                        make.button(@"取消").cancelStyle();
                    } else {
                        make.message(@"不是 UIWindowScene");
                        make.button(@"关闭").cancelStyle().handler(cancelHandler);
                    }
                } showFrom:self];
            }
    }

    __block UIWindow *targetWindow = nil, *oldKeyWindow = nil;
    __block UIWindowLevel oldLevel;
    __block BOOL wasVisible;
    
    subtitle = [subtitle stringByAppendingString:@"\n\n1) 调整 FLEX 窗口相对于此窗口的层级,\n2) 调整此窗口相对于 FLEX 窗口的层级,\n3) 将此窗口层级设置为特定值, 或\n4) 如果不是主窗口则将其设为主窗口。"]; 
    
    [FLEXAlert makeAlert:^(FLEXAlert *make) {
        make.title(NSStringFromClass(window.class)).message(subtitle);
        make.button(@"调整 FLEX 窗口层级").handler(^(NSArray<NSString *> *strings) {
            targetWindow = flex; oldLevel = flex.windowLevel;
            flex.windowLevel = window.windowLevel + strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"调整此窗口的层级").handler(^(NSArray<NSString *> *strings) {
            targetWindow = window; oldLevel = window.windowLevel;
            window.windowLevel = flex.windowLevel + strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"设置此窗口的层级").handler(^(NSArray<NSString *> *strings) {
            targetWindow = window; oldLevel = window.windowLevel;
            window.windowLevel = strings.firstObject.integerValue;
            
            [self showRevertOrDismissAlert:^{ targetWindow.windowLevel = oldLevel; }];
        });
        make.button(@"设为主窗口并可见").handler(^(NSArray<NSString *> *strings) {
            oldKeyWindow = UIApplication.sharedApplication.keyWindow;
            wasVisible = window.hidden;
            [window makeKeyAndVisible];
            
            [self showRevertOrDismissAlert:^{
                window.hidden = wasVisible;
                [oldKeyWindow makeKeyWindow];
            }];
        }).enabled(!window.isKeyWindow && !window.hidden);
        make.button(@"取消").cancelStyle().handler(cancelHandler);
        
        make.textField(@"+/- 窗口层级，例如 5 或 -10");
    } showFrom:self];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)ip {
    [self.navigationController pushViewController:
        [FLEXObjectExplorerFactory explorerViewControllerForObject:self.sections[ip.section][ip.row]]
    animated:YES];
}

@end
