//
//  SecretsPref.m
//  Secrets
//
//  Created by Nicholas Jitkoff on 9/9/06.
//  Copyright (c) 2006 Blacktree. All rights reserved.
//

#import "SecretsPref.h"
#import "NSSortDescriptor+BLTRExtensions.h"
#import "NSImage_BLTRExtensions.h"

#define foreach(x, y) id x; NSEnumerator *rwEnum = [y objectEnumerator]; while(x = [rwEnum nextObject])
#define kSecretsURL [NSURL URLWithString:@"http://secrets.textdriven.com/info/list"]
//#define kSecretsURL [NSURL URLWithString:@"http://www/~alcor/projects/mac/"]


@interface SecretsPref (Private)
- (NSData *)downloadData;
@end

@implementation SecretsPref
@synthesize fetchConnection, fetchData, entries, categories, currentEntry, showInfo;

- (void)openEntry:(id)sender {
  
  NSTableColumn *column = [[sender tableColumns] objectAtIndex:[sender clickedColumn]];
  
  if ([[column identifier] isEqualToString:@"value"]) {
    if ([[sender preparedCellAtColumn:[sender clickedColumn] row:[sender clickedRow]] isKindOfClass:[NSTextFieldCell class]]) {
      [sender editColumn:[sender clickedColumn] row:[sender clickedRow] withEvent:[NSApp currentEvent] select:YES];
      NSLog(@"editable %@", [column dataCellForRow:[sender clickedRow]]);
    }
    return;
  }
  id thisInfo = [[entriesController arrangedObjects] objectAtIndex: [sender clickedRow]]; 	
  NSString *idNumber = [thisInfo objectForKey:@"id"];
  NSString *urlString = [NSString stringWithFormat:@"http://secrets.textdriven.com/preferences/edit/%@", idNumber];
  NSURL *url = [NSURL URLWithString:urlString];
  [[NSWorkspace sharedWorkspace] openURL:url];
  
}
- (NSView *)loadMainView {
  
	NSView *oldMainView = [super loadMainView]; 	
  return oldMainView;
}
- (void)willUnselect {
  [[[self mainView] window] setContentBorderThickness:0 forEdge:NSMinYEdge];
}


- (void) willSelect {
  [self loadInfo:nil];
}
- (void)didSelect {
  [[[self mainView] window] setContentBorderThickness:32 forEdge:NSMinYEdge];
//  [self performSelector:@selector(loadInfo:) withObject:nil afterDelay:0.0];
}


- (void)mainViewDidLoad
{
}

- (void)awakeFromNib {
	[categoriesController addObserver:self
                         forKeyPath:@"selectedObjects"
                            options:nil
                            context:nil];
  
	
	[entriesTable setSortDescriptors:
   [NSSortDescriptor descriptorArrayWithKey:@"title"
                                  ascending:YES
                                   selector:@selector(caseInsensitiveCompare:)]];
  [categoriesTable setSortDescriptors:
   [NSSortDescriptor descriptorArrayWithKey:@"text"
                                  ascending:YES
                                   selector:@selector(caseInsensitiveCompare:)]];
  [entriesTable setDoubleAction:@selector(openEntry:)];
  [entriesTable setTarget:self];
  
  [entriesTable setIntercellSpacing:NSMakeSize(6
                                               , 6)];
	NSTableColumn *titleColumn = [entriesTable tableColumnWithIdentifier:@"title"];
	NSTableColumn *iconColumn = [entriesTable tableColumnWithIdentifier:@"icon"];
  [[iconColumn dataCell] setImageAlignment:NSImageAlignTop];
  //	[[titleColumn dataCell] setImageSize:NSMakeSize(16, 16)];
	
	[[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(columnResized)
   name:NSTableViewColumnDidResizeNotification
   object:entriesTable];
  
  
}


- (NSArray *)secretsArray {
  
  NSString *path = [@"~/Library/Caches/Secrets.plist" stringByStandardizingPath];
  NSData *data = [NSData dataWithContentsOfFile:path];
  
  if (!data) data = [self downloadData];
  
  NSArray *array = [NSPropertyListSerialization 
                    propertyListFromData:data
                    mutabilityOption:NSPropertyListMutableContainers
                    format:nil errorDescription:nil];
  
  return array;
}

- (NSData *)downloadData {
  downloading = YES;
  [progressField setStringValue:@"Loading Data"];
  [progressField display];
  
  NSString *path = [@"~/Library/Caches/Secrets.plist" stringByStandardizingPath];
  NSArray *array = nil;
  
//  int i;
//  for (i = 187; i < 500; i++) {
//    NSURL *debugURL =  [NSURL URLWithString:[@"http://secrets.textdriven.com/info/list/" stringByAppendingFormat:@"%d", i]];
//    
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:debugURL
//                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
//                                         timeoutInterval:10.0];
//    
//    NSData * data = [NSURLConnection sendSynchronousRequest:request
//                                           returningResponse:nil
//                                                       error:nil];
//    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//    
//    NSString *error = nil;
//    array = [NSPropertyListSerialization 
//             propertyListFromData:data
//             mutabilityOption:NSPropertyListMutableContainers
//             format:nil errorDescription:&error];
//    NSLog(@" %i error %@ data %d %d %d", i, error, [data length], [string length], [array count]);
//
//    if (!array) {
//       [data writeToFile:@"/Volumes/Lore/test.plist" atomically:NO]; 
//      return nil;
//    }
//  }

  
  
  
  
  NSURLRequest *request = [NSURLRequest requestWithURL:kSecretsURL
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:10.0];
  
  if (!self.fetchConnection) {
    self.fetchConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    self.fetchData = [NSMutableData data];
    [progressIndicator startAnimation:nil];
    return nil;
  }
  
  NSURLResponse *response = nil;
  NSData *data = nil;
  //[NSURLConnection sendSynchronousRequest:request
  //                                       returningResponse:&response
  //                                                   error:nil];
  
  //NSLog(@"string %@", [NSString stringWithContentsOfURL:kSecretsURL]);
  
  data = [[NSString stringWithContentsOfURL:kSecretsURL] dataUsingEncoding:NSUTF8StringEncoding];
  if (data) {
    array = [NSPropertyListSerialization 
             propertyListFromData:data
             mutabilityOption:NSPropertyListMutableContainers
             format:nil errorDescription:nil];
    [array writeToFile:path atomically:YES];  
    
  }
  
  
  downloading = NO;
  [progressField setStringValue:@""];
  return data;
}

- (IBAction)reloadInfo:(id)sender {
  [self downloadData];
}

- (IBAction)loadInfo:(id)sender {
  
  
  NSMutableArray *array = [NSMutableArray array]; ;
  
  [array addObjectsFromArray:[self secretsArray]];
  
  
  //NSLog(@"array %@", array);
  NSString *extensionsPath=
  [@"~/Library/Application Support/Secrets/" stringByStandardizingPath];
  
  {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *files = [fm directoryContentsAtPath:extensionsPath];
    files = [files pathsMatchingExtensions:[NSArray arrayWithObject:@"secrets"]];
    foreach(file, files) {
      NSData *data = [NSData dataWithContentsOfFile:[extensionsPath stringByAppendingPathComponent:file]];
      NSArray *fileArray = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers
                                                                      format:nil errorDescription:nil];
      
      foreach (entry, fileArray) {
        NSString *category = [entry objectForKey:@"category"];
        if (!category) {
          category = [entry objectForKey:@"bundle"];
          if (category) [entry setObject:category forKey:@"category"];
        }
      }
      [array addObjectsFromArray:fileArray];
    }
  }
  
  
  
  [bundles release];
  bundles = [NSMutableDictionary dictionary];
  [bundles retain];
  
  NSMutableDictionary *global = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"System", @"text",
                                 [NSImage imageNamed:@"NSApplicationIcon"] , @"image",
                                 @".GlobalPreferences", @"category",
                                 [NSMutableArray array] , @"contents",
                                 nil];
  
  [bundles setValue:global forKey:@".GlobalPreferences"];
  
  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
  
	foreach(entry, array) {
    if ([[entry objectForKey:@"hidden"] boolValue]) continue;
    NSString *ident = [entry objectForKey:@"category"];
    if (!ident) ident = [entry objectForKey:@"bundle"];
    if (!ident) continue;
    id bundle = [bundles objectForKey:ident];
    if (!bundle) {
      //NSLog(@"bundleiden %@", ident);
      bundle = [NSMutableDictionary dictionary];
      [bundle setObject:ident forKey:@"category"];
      NSString *name = nil;  
      NSImage *image = nil;
      NSString *path = [workspace absolutePathForAppBundleWithIdentifier:ident];
      if (path) {
        image = [workspace iconForFile:path];
        name = [[path lastPathComponent] stringByDeletingPathExtension];
      } else {
        continue;
        name = [ident pathExtension];
      }
      
      if (![name length]) name = ident;
      if (!image) image = [NSImage imageNamed:@"NSApplicationIcon"];
      
      
      NSString *file = [[NSString stringWithFormat:@"~/Desktop/Icons/%@.png", ident] stringByStandardizingPath];
      [[[image representationOfSize:NSMakeSize(32, 32)] representationUsingType:NSPNGFileType properties:nil] writeToFile:file atomically:YES];
      
      [bundle setObject:image forKey:@"image"];
      [bundle setObject:name forKey:@"text"];
      
      [bundle setObject:[NSMutableArray array] forKey:@"contents"];
      [bundles setValue:bundle forKey:ident];  
    }
    
    id values = [entry objectForKey:@"values"];
    if ([values isKindOfClass:[NSString class]]) {
      values = [NSPropertyListSerialization 
                propertyListFromData:[values dataUsingEncoding:NSUTF8StringEncoding]
                mutabilityOption:NSPropertyListImmutable
                format:nil errorDescription:nil];
      if (values) [entry setObject:values forKey:@"values"];
    }
    
    if (![entry objectForKey:@"title"]) [entry setValue:[entry objectForKey:@"keypath"] forKey:@"title"];
    if (![entry objectForKey:@"title"]) [entry setValue:@"unknown" forKey:@"title"];
    [[bundle objectForKey:@"contents"] addObject:entry];
  }
  
	[self setCategories:[bundles allValues]];
}

- (void)columnResized {
[entriesTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[entriesController arrangedObjects] count]-1 )]];
}




- (float) tableView:(NSTableView *)tableView heightOfRow:(int)row {
	id thisInfo = [[entriesController arrangedObjects] objectAtIndex:row];
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"title"];
	NSCell *cell = [column dataCell];
	NSString *title = [thisInfo objectForKey:@"title"];
  if (!title) title = @"";
	[cell setStringValue:title];
	NSSize size = [cell cellSizeForBounds:NSMakeRect(0, 0, [column width] , MAXFLOAT)]; 		
	return MAX(24, size.height);
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return NO; 
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([[tableColumn identifier] isEqualToString:@"title"]) {
    
    
  }
}


- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation { 
	id thisInfo = [[entriesController arrangedObjects] objectAtIndex:row];
  
  NSString *tip = [thisInfo objectForKey:@"description"];
  if (![tip length]) return [thisInfo objectForKey:@"title"];
  return tip;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if (![[tableColumn identifier] isEqualToString:@"value"])
    return [tableColumn dataCellForRow:row];
  if (!tableColumn) return nil;
	id thisInfo = [[entriesController arrangedObjects] objectAtIndex:row];
	NSString *type = [thisInfo objectForKey:@"datatype"];
  NSString *widget = [thisInfo objectForKey:@"widget"];
  
	NSCell *cell = nil;
	if ([type isEqualToString:@"boolean"] || [type isEqualToString:@"boolean-neg"]) {
		cell = [[[NSButtonCell alloc] init] autorelease];
		[(NSButtonCell *)cell setButtonType:NSSwitchButton];
		[cell setTitle:@""];
	}
  
	if ([widget hasPrefix:@"popup"]) {
		cell = [[[NSPopUpButtonCell alloc] init] autorelease];
		
		[(NSPopUpButtonCell *)cell setBordered:YES];
		
		[(NSPopUpButtonCell *)cell removeAllItems];
		NSDictionary *items = [thisInfo objectForKey:@"values"];
    
    if ([items isKindOfClass:[NSDictionary class]]) {
      NSArray *keys = [[items allKeys] sortedArrayUsingSelector:@selector(compare:)];
      
      for(NSString *key in keys) {
        id option = [items objectForKey:key];
        id item = [[cell menu] addItemWithTitle:option
                                         action:nil
                                  keyEquivalent:@""];
        [item setRepresentedObject:key];
      }		
    }
	}
  if (!cell) {
    cell = [[[NSTextFieldCell alloc] init] autorelease];    
    NSString *placeholder = [thisInfo objectForKey:@"placeholder"];
    if (!placeholder) placeholder = type;
		[(NSTextFieldCell *)cell setPlaceholderString:placeholder];
  }
	[cell setControlSize:NSSmallControlSize];
	[cell setFont:[NSFont systemFontOfSize:11]];
	[cell setEditable:YES];
	return cell;
}

//- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
//	return YES; 		
//}
//- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
//  return YES;  
//}

- (id)getUserDefaultsValueForKeyPath:(NSString *)path bundle:(CFStringRef)bundle user:(CFStringRef)user host:(CFStringRef)host {
  NSArray *components = [path componentsSeparatedByString:@"."];
  NSString *keypath = nil;
  NSString *key = [components objectAtIndex:0];
  if ([components count] > 1) 
    keypath = [[components subarrayWithRange:NSMakeRange(1, [components count] - 1)] componentsJoinedByString:@"."];
  
  NSObject *value = (NSObject *)CFPreferencesCopyValue((CFStringRef)key, (CFStringRef)bundle, user, host);
  [value autorelease];
  
  if (keypath) value = [value valueForKeyPath:keypath];
  return value;
}

- (void)setUserDefaultsValue:(id)value forKeyPath:(NSString *)path bundle:(CFStringRef)bundle user:(CFStringRef)user host:(CFStringRef)host {
  NSArray *components = [path componentsSeparatedByString:@"."];
  NSString *keypath = nil;
  NSString *key = [components objectAtIndex:0];
  if ([components count] > 1) 
    keypath = [[components subarrayWithRange:NSMakeRange(1, [components count] - 1)] componentsJoinedByString:@"."];
  
  
  if (keypath) { // Handle dictionary subpath
    NSDictionary *dictValue = (NSDictionary *)CFPreferencesCopyValue((CFStringRef)key, (CFStringRef)bundle, user, host);
    [dictValue autorelease];
    if (![dictValue isKindOfClass:[NSDictionary class]]) dictValue = nil;
    
    dictValue = [[dictValue mutableCopy] autorelease];
    if (!dictValue) dictValue = [NSMutableDictionary dictionary];
    
    [dictValue setValue:value forKeyPath:keypath];
    value = dictValue;
  }
  
  CFPreferencesSetValue((CFStringRef) key, value, (CFStringRef)bundle, user, host);
  CFPreferencesSynchronize((CFStringRef) bundle, user, host);  
}





- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
  if ([[aTableColumn identifier] isEqualToString:@"icon"]) {
    id thisInfo = [[entriesController arrangedObjects] objectAtIndex:rowIndex]; 	
    NSString *ident = [thisInfo objectForKey:@"category"];
    if (!ident) ident = [thisInfo objectForKey:@"bundle"];
    return [[bundles objectForKey:ident] objectForKey:@"image"];
  }
  
  if ([[aTableColumn identifier] isEqualToString:@"value"]) {
		id thisInfo = [[entriesController arrangedObjects] objectAtIndex:rowIndex]; 	
		NSString *bundle = [thisInfo objectForKey:@"bundle"];
    if ([bundle isEqualToString:@".GlobalPreferences"]) bundle = (NSString *)kCFPreferencesAnyApplication;
    
    NSString *keypath = [thisInfo objectForKey:@"keypath"];
    if (!keypath) return @"";
    
    
    CFStringRef user = kCFPreferencesCurrentUser;
    CFStringRef host = kCFPreferencesAnyHost;
    if ([[thisInfo objectForKey:@"set_for_all_users"] boolValue]) user = kCFPreferencesAnyUser;
    if ([[thisInfo objectForKey:@"current_host_only"] boolValue]) host = kCFPreferencesCurrentHost;
    
    
    
    id value = [self getUserDefaultsValueForKeyPath:keypath
                                         bundle:(CFStringRef)bundle 
                                           user:user
                                               host:host];
    
    
    if (!value) value = [thisInfo objectForKey:@"defaultValue"];
    if ([[thisInfo objectForKey:@"datatype"] isEqualToString:@"boolean-neg"])
      value = [NSNumber numberWithBool:![(NSNumber *)value boolValue]];
    
    
    if ([[thisInfo objectForKey:@"widget"] isEqualToString:@"popup"]) {
      NSDictionary *items = [thisInfo objectForKey:@"values"];
      
      
      if ([items isKindOfClass:[NSDictionary class]]) {
        NSArray *keys = [[items allKeys] sortedArrayUsingSelector:@selector(compare:)];
        value = [NSNumber numberWithInt:[keys indexOfObject:value]];
      }
    }
    
		return value;
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"value"]) {
		id thisInfo = [[entriesController arrangedObjects] objectAtIndex:rowIndex]; 	
	  NSString *bundle = [thisInfo objectForKey:@"bundle"];
    
    if ([[thisInfo objectForKey:@"widget"] isEqualToString:@"popup"]) {
      NSDictionary *items = [thisInfo objectForKey:@"values"];
      
      if ([items isKindOfClass:[NSDictionary class]]) {
      NSArray *keys = [[items allKeys] sortedArrayUsingSelector:@selector(compare:)];
      value = [keys objectAtIndex:[value intValue]];
      }
    }
    
    if ([[thisInfo objectForKey:@"datatype"] isEqualToString:@"float"]) {
      value = [NSNumber numberWithFloat:[value floatValue]];
    }
    
    if ([[thisInfo objectForKey:@"datatype"] isEqualToString:@"integer"]) {
      value = [NSNumber numberWithInt:[value intValue]];
    }
    
    if ([[thisInfo objectForKey:@"datatype"] isEqualToString:@"boolean-neg"])
      value = [NSNumber numberWithBool:![value boolValue]];
    
    
    if ([value isKindOfClass:[NSString class]] && ![(NSString *)value length]) {
      value = nil;
    }
    
    
    CFStringRef user = kCFPreferencesCurrentUser;
    CFStringRef host = kCFPreferencesAnyHost;
    if ([[thisInfo objectForKey:@"set_for_all_users"] boolValue]) user = kCFPreferencesAnyUser;
    if ([[thisInfo objectForKey:@"current_host_only"] boolValue]) host = kCFPreferencesCurrentHost;
    
    
    NSString *keypath = [thisInfo objectForKey:@"keypath"];
    
     [self setUserDefaultsValue:value
                               forKeyPath:keypath
                                   bundle:(CFStringRef)bundle 
                                     user:user
                                     host:host];
    
  
    if (value)
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.blacktree.Secret" object:bundle userInfo:[NSDictionary dictionaryWithObject:value forKey:keypath]];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  NSMutableArray *newEntries = [NSMutableArray array];
  id selection = [object selectedObjects];
  if (![selection count])
    selection = [object arrangedObjects];
  foreach(category, selection) {
    [newEntries addObjectsFromArray:[category valueForKey:@"contents"]];
  }
  [self setEntries:newEntries];
  [self setShowInfo:selection == nil];
}

//- (NSArray *)categories { return [[categories retain] autorelease];  }
//- (void)setCategories: (NSArray *)newCategories
//{
//  if (categories != newCategories) {
//    [categories release];
//    categories = [newCategories retain];
//  }
//}
//
//
//- (NSArray *)entries { return [[entries retain] autorelease];  }
//- (void)setEntries: (NSArray *)newEntries
//{
//  if (entries != newEntries) {
//    [entries release];
//    entries = [newEntries retain];
//    //NSLog(@"entries %@", entries);
//  }
//}
//
//
//
//- (NSDictionary *)currentEntry { return [[currentEntry retain] autorelease];  }
//- (void)setCurrentEntry: (NSDictionary *)newCurrentEntry
//{
//  if (currentEntry != newCurrentEntry) {
//    [currentEntry release];
//    currentEntry = [newCurrentEntry retain];
//  }
//}
// Load the image




- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSString *string = [[[NSString alloc] initWithData:fetchData encoding:NSUTF8StringEncoding] autorelease];
  [fetchData writeToFile:@"/Volumes/Lore/test.plist" atomically:NO];
  if (fetchData) {
    NSString *error = nil;
    NSArray *array = [NSPropertyListSerialization 
             propertyListFromData:fetchData
             mutabilityOption:NSPropertyListMutableContainers
                      format:nil errorDescription:&error];
    
    if (error) {
      NSLog(@"Error loading plist: %@", error);
    } else {
      NSString *path = [@"~/Library/Caches/Secrets.plist" stringByStandardizingPath];
      
      [array writeToFile:path atomically:YES];  
    }
    
  }
  
  
  self.fetchConnection = nil;
  self.fetchData = nil;
  
  [self loadInfo:nil];
  [progressIndicator stopAnimation:nil];
  
  
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
  self.fetchConnection = nil;
  self.fetchData = nil;
  [progressIndicator stopAnimation:nil];

  
  // inform the user
  NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
  [fetchData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [fetchData appendData:data];
}



- (void)dealloc
{
  [self setCategories: nil];
  [self setEntries: nil];
  [self setCurrentEntry: nil];
  [super dealloc];
}

//- (BOOL)showInfo { return showInfo;  }
//- (void)setShowInfo: (BOOL)flag
//{
//  showInfo = flag;
//}


@end
