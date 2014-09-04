//
//  MMTableCellView.h
//  KeyboardSwitcher
//
//  Created by Mike Muszynski on 6/13/13.
//  Copyright (c) 2013 Mike Muszynski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MMTableCellView : NSTableCellView

@property (weak) IBOutlet NSTextField *applicationNameTextField;
@property (weak) IBOutlet NSImageView *applicationIconView;
@property (weak) IBOutlet NSButton *applicationCheckbox;
@property (weak) IBOutlet NSTextField *applicationBundleNameTextField;

@end
