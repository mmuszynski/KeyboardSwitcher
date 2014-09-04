//
//  MMAppDelegate.h
//  KeyboardSwitcher
//
//  Created by Mike Muszynski on 6/13/13.
//  Copyright (c) 2013 Mike Muszynski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MMTableCellView;
@class MMTableView;

@interface MMAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSOpenSavePanelDelegate> {
    
    NSStatusItem *_statusItem;
    NSOpenPanel *_openPanel;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet MMTableView *applicationTableView;

@property (nonatomic, retain) NSArray *applicationList;
@property (weak) IBOutlet NSButton *globalCheckbox;
- (IBAction)checkboxToggled:(id)sender;
- (IBAction)segmentPress:(id)sender;


@property (weak) IBOutlet NSSegmentedControl *addSubtractSegmentedControl;

//stats menu items
@property (weak) IBOutlet NSMenu *statusMenu;


@end
