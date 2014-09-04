//
//  MMTableView.m
//  KeyboardSwitcher
//
//  Created by Mike Muszynski on 6/14/13.
//  Copyright (c) 2013 Mike Muszynski. All rights reserved.
//

#import "MMTableView.h"

@implementation MMTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

/*
- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}
 */

- (void)keyDown:(NSEvent *)theEvent
{
    
    unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deleteRow" object:nil];
        return;
    }
    
    [super keyDown:theEvent];
    
}

@end
