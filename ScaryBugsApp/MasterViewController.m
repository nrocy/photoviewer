//
//  MasterViewController.m
//  ScaryBugsApp
//
//  Created by Ray Wenderlich on 8/11/12.
//  Copyright (c) 2012 Ray Wenderlich. All rights reserved.
//

#import "MasterViewController.h"
#import "ScaryBugDoc.h"
#import "ScaryBugData.h"
#import "EDStarRating.h"
#import <Quartz/Quartz.h>
#import "NSImage+Extras.h"
#import <sqlite3.h>


@interface MasterViewController ()

@property (weak) IBOutlet NSTableView *bugsTableView;
@property (weak) IBOutlet NSTextField *bugTitleView;
@property (weak) IBOutlet NSImageView *bugImageView;
@property (weak) IBOutlet EDStarRating *bugRating;
@property (weak) IBOutlet NSButton *deleteButton;
@property (weak) IBOutlet NSButton *changePictureButton;

@end

@implementation MasterViewController
@synthesize deleteButton = _deleteButton;
@synthesize changePictureButton = _changePictureButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    if( [tableColumn.identifier isEqualToString:@"BugColumn"] )
    {
        ScaryBugDoc *bugDoc = [self.bugs objectAtIndex:row];
        cellView.imageView.image = bugDoc.thumbImage;
        
        if( [bugDoc.createDate length] > 0 ) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *date = [formatter dateFromString:bugDoc.createDate];
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
            
            cellView.textField.stringValue = [NSString stringWithFormat:@"%@\n%@\n%@", [formatter stringFromDate:date], bugDoc.city, bugDoc.country];
        }
//        cellView.textField.stringValue = [NSString stringWithFormat:@"%@ %@ %@", bugDoc.pathToFullImage, bugDoc.location, bugDoc.createDate];
        return cellView;
    }

    if( [tableColumn.identifier isEqualToString:@"CreateDate"] )
    {
        ScaryBugDoc *bugDoc = [self.bugs objectAtIndex:row];
        cellView.textField.stringValue = bugDoc.createDate;
        return cellView;
    }

    if( [tableColumn.identifier isEqualToString:@"Location"] )
    {
        ScaryBugDoc *bugDoc = [self.bugs objectAtIndex:row];
        cellView.textField.stringValue = bugDoc.location;
        return cellView;
    }

    return cellView;
}

-(void)findPhotos:(NSString *)sql
{
    sqlite3 *db;
 
    [self.bugs removeAllObjects];
    
    NSString *pathToDatabase = @"/Users/nroc/src/PhotoViewer/indexer/photos.db";
    
    if( sqlite3_open([pathToDatabase UTF8String], &db) == SQLITE_OK )
    {
        NSString *query = [NSString stringWithFormat:@"%@ %@ %@", @"SELECT filename, thumb, exif_create_date, address, city, country FROM photos LEFT JOIN geo ON (photos.latitude=geo.latitude AND photos.longitude=geo.longitude) ", sql, @" ORDER BY exif_create_date DESC"];
        
        sqlite3_stmt *statement;
        
        if( sqlite3_prepare_v2(db, [query UTF8String], -1, &statement, nil) == SQLITE_OK )
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                char *c_filename = (char *)sqlite3_column_text(statement, 0);

                int len = sqlite3_column_bytes(statement, 1);
                NSData *blob = [[NSData alloc] initWithBytes: sqlite3_column_blob(statement, 1) length:len];
                NSImage *img = [[NSImage alloc]initWithData:blob];
                
                char *c_create_date = (char *)sqlite3_column_text(statement, 2);
                char *c_location = (char *)sqlite3_column_text(statement, 3);
                char *c_city = (char *)sqlite3_column_text(statement, 4);
                char *c_country = (char *)sqlite3_column_text(statement, 5);

                NSString *filename = [[NSString alloc] initWithUTF8String:c_filename];
                NSString *createDate = [[NSString alloc] initWithUTF8String:c_create_date];
                NSString *city;
                NSString *country;
                NSString *location;
                
                if( c_location != NULL ) {
                    location = [[NSString alloc] initWithUTF8String:c_location];
                } else {
                    location = @"";
                }
                
                if( c_city != NULL ) {
                    city = [[NSString alloc] initWithUTF8String:c_city];
                } else {
                    city = @"";
                }
                
                if( c_country != NULL ) {
                    country = [[NSString alloc] initWithUTF8String:c_country];
                } else {
                    country = @"";
                }
                
                ScaryBugDoc *bug = [[ScaryBugDoc alloc] initWithTitle:filename rating:0 thumbImage:img fullImage:[NSImage imageNamed:@"potatoBug.jpg" ] pathToFullImage:filename createDate:createDate location:location city:city country:country];
                
                [self.bugs addObject:bug];
            }
            sqlite3_finalize(statement);
        }
        else
        {
            NSLog(@"SQL error");
        }
        
        sqlite3_close(db);
    }
    else
    {
        NSLog(@"Couldn't open db");
    }

    [self.bugsTableView reloadData];
}

-(void)findAllPhotos
{
    [self findPhotos:@""];
}

-(void)loadView
{
    [super loadView];
    
    [self.changePictureButton setEnabled:NO];
    
    NSMutableArray *bugs = [[NSMutableArray alloc] init];
    self.bugs = bugs;

    [self findAllPhotos];
    
    self.bugRating.starImage = [NSImage imageNamed:@"star.png"];
    self.bugRating.starHighlightedImage = [NSImage imageNamed:@"shockedface2_full.png"];
    self.bugRating.starImage = [NSImage imageNamed:@"shockedface2_empty.png"];
    self.bugRating.maxRating = 5.0;
    self.bugRating.delegate = (id<EDStarRatingProtocol>) self;
    self.bugRating.horizontalMargin = 12;
    self.bugRating.editable=NO;
    self.bugRating.displayMode=EDStarRatingDisplayFull;
    self.bugRating.rating= 0.0;
}

-(ScaryBugDoc*)selectedBugDoc
{
    NSInteger selectedRow = [self.bugsTableView selectedRow];
    if( selectedRow >=0 && self.bugs.count > selectedRow )
    {
        [self.changePictureButton setEnabled:YES];
        ScaryBugDoc *selectedBug = [self.bugs objectAtIndex:selectedRow];
        return selectedBug;
    }
    return nil;
}

-(void)setDetailInfo:(ScaryBugDoc*)doc
{
    NSString    *title = @"";
    NSImage     *image = nil;
    float rating=0.0;
    if( doc != nil )
    {
        title = doc.data.title;
        //image = doc.fullImage;
        rating = doc.data.rating;
    }
    
    image = [[NSImage alloc] initWithContentsOfFile:doc.pathToFullImage];
    
    [self.bugTitleView setStringValue:title];
    [self.bugImageView setImage:image];
    [self.bugRating setRating:rating];
    
}

- (IBAction)changePicture:(id)sender {
    ScaryBugDoc *selectedDoc = [self selectedBugDoc];
    if( selectedDoc )
    {
        NSURL *url = [NSURL fileURLWithPath:selectedDoc.pathToFullImage];
        NSArray *fileURLs = [NSArray arrayWithObjects:url, nil];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    ScaryBugDoc *selectedDoc = [self selectedBugDoc];
    
    // Update info
    [self setDetailInfo:selectedDoc];
    
    // Enable/Disable buttons based on selection
    BOOL buttonsEnabled = (selectedDoc!=nil);
    [self.deleteButton setEnabled:buttonsEnabled];
    [self.changePictureButton setEnabled:buttonsEnabled];
    [self.bugRating setEditable:buttonsEnabled];
    [self.bugTitleView setEnabled:buttonsEnabled];
    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.bugs count];
}

- (IBAction)bugTitleDidEndEdit:(id)sender {
    // 1. Get selected bug
    ScaryBugDoc *selectedDoc = [self selectedBugDoc];
    if (selectedDoc )
    {
        // 2. Get the new name from the text field
        selectedDoc.data.title = [self.bugTitleView stringValue];
        // 3. Update the cell
        NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:[self.bugs indexOfObject:selectedDoc]];
        NSIndexSet * columnSet = [NSIndexSet indexSetWithIndex:0];
        [self.bugsTableView reloadDataForRowIndexes:indexSet columnIndexes:columnSet];
    }
}

- (IBAction)addBug:(id)sender {
    
    NSString *searchText = [sender stringValue];
    
    if( [searchText length] == 0 )
    {
        [self findAllPhotos];
    }
    else
    {
        [self findPhotos:[NSString stringWithFormat:@"%@%@%@%@%@", @"WHERE address like '%", searchText, @"%' or exif_create_date LIKE '%", searchText, @"%'"]];
    }
    
    /*
    // 1. Create a new ScaryBugDoc object with a default name
    ScaryBugDoc *newDoc = [[ScaryBugDoc alloc] initWithTitle:@"New Bug" rating:0.0 thumbImage:nil fullImage:nil pathToFullImage:nil createDate:nil location:nil];

    // 2. Add the new bug object to our model (insert into the array)
    [self.bugs addObject:newDoc];
    NSInteger newRowIndex = self.bugs.count-1;

    // 3. Insert new row in the table view
    [self.bugsTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newRowIndex] withAnimation:NSTableViewAnimationEffectGap];

    // 4. Select the new bug and scroll to make sure it's visible
    [self.bugsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newRowIndex] byExtendingSelection:NO];
    [self.bugsTableView scrollRowToVisible:newRowIndex];
    */
}

- (void) pictureTakerDidEnd:(IKPictureTaker *) picker
                 returnCode:(NSInteger) code
                contextInfo:(void*) contextInfo
{
    NSImage *image = [picker outputImage];
    if( image !=nil && (code == NSOKButton) )
    {
        [self.bugImageView setImage:image];
        ScaryBugDoc * selectedBugDoc = [self selectedBugDoc];
        if( selectedBugDoc )
        {
            selectedBugDoc.fullImage = image;
            selectedBugDoc.thumbImage = [image imageByScalingAndCroppingForSize:CGSizeMake( 44, 44 )];
            NSIndexSet * indexSet = [NSIndexSet indexSetWithIndex:[self.bugs indexOfObject:selectedBugDoc]];
            
            NSIndexSet * columnSet = [NSIndexSet indexSetWithIndex:0];
            [self.bugsTableView reloadDataForRowIndexes:indexSet columnIndexes:columnSet];
        }
    }
}

- (IBAction)deleteBug:(id)sender {
    // 1. Get selected doc
    ScaryBugDoc *selectedDoc = [self selectedBugDoc];
    if (selectedDoc )
    {
        // 2. Remove the bug from the model
        [self.bugs removeObject:selectedDoc];
        // 3. Remove the selected row from the table view.
        [self.bugsTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.bugsTableView.selectedRow] withAnimation:NSTableViewAnimationSlideRight];
        // Clear detail info
        [self setDetailInfo:nil];
    }
}

-(void)starsSelectionChanged:(EDStarRating*)control rating:(float)rating
{
    ScaryBugDoc *selectedDoc = [self selectedBugDoc];
    if( selectedDoc )
    {
        selectedDoc.data.rating = self.bugRating.rating;
    }
}

@end
