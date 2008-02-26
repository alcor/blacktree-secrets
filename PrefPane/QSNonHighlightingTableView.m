//
//  QSNonHighlightingTableView.m
//  Secrets
//
//  Created by Nicholas Jitkoff on 9/10/06.
//  Copyright 2006 Blacktree. All rights reserved.
//

#import "QSNonHighlightingTableView.h"


@implementation QSNonHighlightingTableView
//- (void)highlightSelectionInClipRect:(NSRect)clipRect{
//  return;
//}

// make return and tab only end editing, and not cause other cells to edit

- (void) textDidEndEditing: (NSNotification *) notification
{
  NSDictionary *userInfo = [notification userInfo];
  
  int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];
  
  if (textMovement == NSReturnTextMovement
      || textMovement == NSTabTextMovement
      || textMovement == NSBacktabTextMovement) {
    
    NSMutableDictionary *newInfo;
    newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];
    
    [newInfo setObject: [NSNumber numberWithInt: NSIllegalTextMovement]
                forKey: @"NSTextMovement"];
    
    notification =
      [NSNotification notificationWithName: [notification name]
                                    object: [notification object]
                                  userInfo: newInfo];
    
  }
  
  [super textDidEndEditing: notification];
  [[self window] makeFirstResponder:self];
  
} // textDidEndEditing


@end
