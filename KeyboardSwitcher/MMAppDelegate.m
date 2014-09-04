//
//  MMAppDelegate.m
//  KeyboardSwitcher
//
//  Created by Mike Muszynski on 6/13/13.
//  Copyright (c) 2013 Mike Muszynski. All rights reserved.
//

#import "MMAppDelegate.h"
#import "MMTableView.h"
#import "MMTableCellView.h"
#import <CoreFoundation/CoreFoundation.h>

#include <IOKit/hidsystem/event_status_driver.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/IOHIDParameter.h>

#define KEY_APP_ARRAY @"com.mmuszynski.functionKeySwitcher.appArray"

@implementation MMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteSelectedRows:) name:@"deleteRow" object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appSwitch:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    
    CFBooleanRef value = CFPreferencesCopyValue(CFSTR("com.apple.keyboard.fnState"), kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    BOOL currentDefault = (BOOL) value;
    
    [[NSUserDefaults standardUserDefaults] setBool:currentDefault forKey:@"com.mmuszynski.functionKeySwitcher.defaultState"];
    
    [_applicationTableView setDelegate:self];
    [_applicationTableView setDataSource:self];
    
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_APP_ARRAY];
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:KEY_APP_ARRAY]) {
        _applicationList = [[NSArray alloc] init];
    } else {
        _applicationList = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_APP_ARRAY];
    }
    
    if(![[NSUserDefaults standardUserDefaults] integerForKey:@"com.mmuszynski.functionKeySwitcher.globalCheckboxState"])
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"com.mmuszynski.functionKeySwitcher.globalCheckboxState"];
    
    [_globalCheckbox setState:[[[NSUserDefaults standardUserDefaults] objectForKey:@"com.mmuszynski.functionKeySwitcher.globalCheckboxState"] integerValue]];
    
    [_applicationTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    [self checkboxToggled:self];
    [_applicationTableView reloadData];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setTitle:@"Fn"];
    
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
        
    return [_applicationList count];
    
}

-(NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    NSTableRowView *tableRow = [NSTableRowView new];
    
    return tableRow;
    
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
        
    MMTableCellView *cell = [tableView makeViewWithIdentifier:@"defaultCell" owner:self];
    
    NSData *iconData = [[_applicationList objectAtIndex:row] objectForKey:@"iconData"];
    NSImage *icon = [[NSImage alloc] initWithData:iconData];
    
    [cell.applicationIconView setImage:icon];
    [cell.applicationNameTextField setStringValue:[[_applicationList objectAtIndex:row] objectForKey:@"appName"]];
    [cell.applicationBundleNameTextField setStringValue:[[_applicationList objectAtIndex:row] objectForKey:@"bundleIdentifier"]];
    [cell.applicationCheckbox setState:[[[_applicationList objectAtIndex:row] objectForKey:@"checkboxState"] integerValue]];
    
    [cell.applicationCheckbox setTag:row];
    [cell.applicationCheckbox setAction:@selector(rowCheckboxToggled:)];
    
    return cell;
    
}



-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] ) {
                
        NSURL *url = [NSURL URLFromPasteboard:pboard];
       
        if( [url.pathExtension isEqualToString:@"app"] ) {
            return NSDragOperationCopy;
        }
        
    }
    
    return NSDragOperationNone;
    
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSURL *url = [NSURL URLFromPasteboard:pboard];
    
    NSBundle *draggedBundle = [NSBundle bundleWithURL:url];
    
    for (NSDictionary *dictionary in _applicationList) {
        
        if( [draggedBundle.bundleIdentifier isEqualToString:[dictionary objectForKey:@"bundleIdentifier"]] ) {
            return NO;
        }
                
    }
    
    if(!draggedBundle) {
        return NO;
    }
    
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
    NSData *iconData = [icon TIFFRepresentation];
    
    NSString *customAppName = [url lastPathComponent];
    customAppName = [customAppName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [url pathExtension]]
                                                             withString:@""];
    
    NSNumber *currentCheckbox = [NSNumber numberWithInteger:[_globalCheckbox state]];
    
    NSArray *values = [NSArray arrayWithObjects:draggedBundle.bundleIdentifier, customAppName, currentCheckbox, iconData, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"bundleIdentifier", @"appName", @"checkboxState", @"iconData", nil];
    
    NSMutableArray *tempList = [_applicationList mutableCopy];
    
    [tempList addObject:[NSDictionary dictionaryWithObjects:values forKeys:keys]];
    _applicationList = [tempList copy];
    [_applicationTableView reloadData];

    [self saveDefaults];
    
    return YES;
    
}


-(void)appSwitch:(id)sender {
    
    unsigned int enabled = (int)[_globalCheckbox state];
    NSString *bundleIdentifier = [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
    
    for ( NSDictionary *dictionary in _applicationList ) {
        
        if( [[dictionary objectForKey:@"bundleIdentifier"] isEqualToString:bundleIdentifier] )
            enabled = (int)[[dictionary objectForKey:@"checkboxState"] integerValue];
        
    }
    
    int success = 0;
    io_connect_t handle = NXOpenEventStatus();
    if(handle) {
        success = IOHIDSetParameter(handle, CFSTR(kIOHIDFKeyModeKey), &enabled, sizeof enabled) == KERN_SUCCESS;
        NXCloseEventStatus(handle);
    }
    
    if(success) {        
        CFBooleanRef pref = enabled ? kCFBooleanTrue : kCFBooleanFalse;
        
        // Set preference
        CFPreferencesSetAppValue(CFSTR("com.apple.keyboard.fnState"), pref, kCFPreferencesAnyApplication);
        CFPreferencesAppSynchronize(kCFPreferencesAnyApplication);
        
        // Notify globally
        NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
        NSDictionary *info = [NSDictionary dictionaryWithObject:(NSNumber *)CFBridgingRelease(pref) forKey:@"state"];
        [center postNotificationName:@"com.apple.keyboard.fnstatedidchange" object:nil userInfo:info deliverImmediately:YES];
    }

}

- (void)rowCheckboxToggled:(id)sender {
    
    NSInteger row = [(NSButton*)sender tag];
    NSMutableDictionary *currentRowDictionary = [[_applicationList objectAtIndex:row] mutableCopy];
    [currentRowDictionary setObject:[NSNumber numberWithInteger:[(NSButton*)sender state]] forKey:@"checkboxState"];
    
    NSMutableArray *tempArray = [_applicationList mutableCopy];
    
    [tempArray replaceObjectAtIndex:row withObject:[currentRowDictionary copy]];
    _applicationList = [tempArray copy];
    
    [self checkboxToggled:self];
    
}

- (IBAction)checkboxToggled:(id)sender {
    
    if([sender isKindOfClass:[NSMenuItem class]]) {
        
        NSInteger newState = [sender state] == 0 ? 1 : 0;
        
        [sender setState:newState];
        [_globalCheckbox setState:[sender state]];
    }
    
    [self saveDefaults];
    [self appSwitch:self];
    
}

- (IBAction)segmentPress:(id)sender {
    
    NSInteger num = [sender selectedSegment];
    
    if( num == 0)
        [self deleteSelectedRows:self];
    else
        [self addApplication];
    
}

-(BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
    
    NSString *testID = [[NSBundle bundleWithURL:url] bundleIdentifier];
    
    for( NSDictionary *dict in _applicationList ) {
        
        if( [[dict objectForKey:@"bundleIdentifier"] isEqualToString:testID] )
           return NO;
        
    }
    
    return YES;
    
}

-(void)addApplication {
    
    if(!_openPanel) {
        _openPanel = [[NSOpenPanel alloc] init];
        [_openPanel setDelegate:self];
    }
    
    [_openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"app", @"APP", @"App", nil]];
    [_openPanel setCanChooseDirectories:NO];
    [_openPanel setPrompt:@"Select"];
    
    [_openPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
        
        if(result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[_openPanel URLs] lastObject];
            NSBundle *draggedBundle = [NSBundle bundleWithURL:url];
            
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[url path]];
            NSData *iconData = [icon TIFFRepresentation];
            
            NSString *customAppName = [url lastPathComponent];
            customAppName = [customAppName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [url pathExtension]]
                                                                     withString:@""];
            
            NSNumber *currentCheckbox = [NSNumber numberWithInteger:[_globalCheckbox state]];
            
            NSArray *values = [NSArray arrayWithObjects:draggedBundle.bundleIdentifier, customAppName, currentCheckbox, iconData, nil];
            NSArray *keys = [NSArray arrayWithObjects:@"bundleIdentifier", @"appName", @"checkboxState", @"iconData", nil];
            
            NSMutableArray *tempList = [_applicationList mutableCopy];
            
            [tempList addObject:[NSDictionary dictionaryWithObjects:values forKeys:keys]];
            _applicationList = [tempList copy];
            [_applicationTableView reloadData];
            
            [self saveDefaults];
            
        }
        
    }];
    
}



- (IBAction)deleteSelectedRows:(id)sender {    
            
    NSIndexSet *set = [_applicationTableView selectedRowIndexes];
    
    NSMutableArray *tempArray = [_applicationList mutableCopy];
    [tempArray removeObjectsAtIndexes:set];
    
    _applicationList = [tempArray copy];
    [_applicationTableView reloadData];

    [self checkboxToggled:self];
    
}

-(void)saveDefaults {

    [[NSUserDefaults standardUserDefaults] setObject:[_applicationList copy] forKey:KEY_APP_ARRAY];
    [[NSUserDefaults standardUserDefaults] setInteger:[_globalCheckbox state] forKey:@"com.mmuszynski.functionKeySwitcher.globalCheckboxState"];
    
    [[_statusMenu itemAtIndex:0] setState:[_globalCheckbox state]];
    
    if( [_applicationList count] == 0 ) {
        [_addSubtractSegmentedControl setEnabled:NO forSegment:0];
    } else {
        [_addSubtractSegmentedControl setEnabled:YES forSegment:0];
    }
    
}


@end
