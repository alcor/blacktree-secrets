//
//  SecretsPref.h
//  Secrets
//
//  Created by Nicholas Jitkoff on 9/9/06.
//  Copyright (c) 2006 Blacktree. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface SecretsPref : NSPreferencePane 
{
	IBOutlet NSView *sidebarView;
	IBOutlet NSSplitView *splitView;
	
	NSArray *categories;
	NSDictionary *bundles;
	NSArray *entries;
	
  IBOutlet NSDictionary *sourcesDictionary;
  
	IBOutlet NSArrayController *categoriesController;
	IBOutlet NSTableView  *categoriesTable;
	IBOutlet NSArrayController *entriesController;
	IBOutlet NSTableView  *entriesTable;
  
	IBOutlet NSPanel *sourcesPanel;
	
	NSDictionary *currentEntry;
  IBOutlet NSProgressIndicator *progressIndicator;
  IBOutlet NSTextField *progressField;
  BOOL downloading;
  BOOL showInfo;
  
  NSURLConnection *fetchConnection;
  NSMutableData   *fetchData;
}

@property(retain) NSURLConnection *fetchConnection;
@property(retain) NSMutableData   *fetchData;
@property(retain) NSArray *entries;
@property(retain) NSArray *categories;
@property(retain) NSDictionary *currentEntry;
@property(assign) BOOL showInfo;

- (IBAction)reloadInfo:(id)sender;

- (NSArray *) categories;
- (void) setCategories: (NSArray *) newCategories;
- (NSArray *) entries;
- (void) setEntries: (NSArray *) newEntries;
- (NSDictionary *) currentEntry;
- (void) setCurrentEntry: (NSDictionary *) newCurrentEntry;

- (BOOL) showInfo;
- (void) setShowInfo: (BOOL) flag;

- (IBAction)loadInfo:(id)sender;




@end
