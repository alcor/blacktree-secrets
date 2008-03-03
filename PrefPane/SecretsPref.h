//
//  SecretsPref.h
//  Secrets
//
//  Created by Nicholas Jitkoff on 9/9/06.


#import <PreferencePanes/PreferencePanes.h>


@interface SecretsPref : NSPreferencePane 
{
	IBOutlet NSView *sidebarView;
	IBOutlet NSSplitView *splitView;
	
	NSArray *categories;
	NSMutableDictionary *bundles;
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
  NSPredicate *searchPredicate;
}

@property(retain) NSURLConnection *fetchConnection;
@property(retain) NSMutableData   *fetchData;
@property(retain) NSArray *entries;
@property(retain) NSArray *categories;
@property(retain) NSMutableDictionary *bundles;
@property(retain) NSDictionary *currentEntry;
@property(retain) NSPredicate *searchPredicate;
@property(assign) BOOL showInfo;

- (IBAction)reloadInfo:(id)sender;
- (IBAction)showSite:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)loadInfo:(id)sender;
- (IBAction)resetValue:(id)sender;
- (IBAction)openEntry:(id)sender;


- (NSArray *) categories;
- (void) setCategories: (NSArray *) newCategories;
- (NSArray *) entries;
- (void) setEntries: (NSArray *) newEntries;
- (NSDictionary *) currentEntry;
- (void) setCurrentEntry: (NSDictionary *) newCurrentEntry;

- (BOOL) showInfo;
- (void) setShowInfo: (BOOL) flag;


@end
