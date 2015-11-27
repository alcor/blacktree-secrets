//
//  NSSortDescriptor+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 3/27/05.

//

#import <Cocoa/Cocoa.h>


@interface NSSortDescriptor (QSConvenience)
+ (instancetype)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending;
+ (instancetype)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector;
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending;
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector;
@end
