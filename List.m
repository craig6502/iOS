//
//  List.m
//  JuniorCricket
//
//  Created by Craig Duncan on 29/9/18.
//  Copyright © 2018 Craig Duncan. All rights reserved.
//
// This class will handle list save IO and allow additional list functions like rotate, move item up etc
// will also allow tracking of the 'image' and 'accessory' items that can be displayed on iPad, iPhone lists
// separates all this from the view (tableview in the View, in the View Controller).

#import "List.h"
#import "Fileops.h"
#import "AppDelegate.h"

@implementation List {
	NSMutableArray * myList; //main list item
	NSMutableArray * listitemID; // unique ID for list item
	NSMutableArray * selected; //for tracking items selected
	NSNumber * sel;
	NSNumber * unsel;
	NSString * listFilename;
	AppDelegate * myAppDelegate; //to obtain app counter values
	BOOL hasListIDs; //to flag if this list has universal counter IDs
}

//constructor
-(List *) init {
	myList = [[NSMutableArray alloc]init];
	listitemID = [[NSMutableArray alloc]init];
	listFilename = [NSString stringWithFormat:@""];
	selected = [[NSMutableArray alloc] init];
	sel = [NSNumber numberWithInt:1];
	unsel = [NSNumber numberWithInt:0];
	myAppDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	hasListIDs = FALSE;
	return self;
}

-(BOOL)isIDincluded {
	return hasListIDs;
}

-(void)setHasIDs {
	hasListIDs=TRUE;
}

-(void)defineList:(NSString *)listname {
	[self setListFilename:listname];
	[self loadList];
}

-(NSString *)checkfilename:(NSString *)testname {
	//replace any slash chars with a - alternative
	NSString * output = [testname stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	//don't allow blank game names
	if (output.length<1) {
		output = @"NewGame";
	}
	return output;
}

//general save function for list
-(void)saveList {
	Fileops * mySaver = [[Fileops alloc] init];
	NSString * myListString = [self getListWithIDAsString];
	[mySaver saveList:listFilename myCSVList:myListString]; //object filename
}

-(NSString *)getListFilename {
	return listFilename;
}

-(void)setListFilename:(NSString *)name {
	NSString * newname = [self checkfilename:name];
	listFilename = newname;
}

//get List as its array.  Create new to avoid pointer issues.
-(NSMutableArray *)getListAsArray {
	NSMutableArray * newlist = [[NSMutableArray alloc] init];
	for (int p=0;p<myList.count;p++) {
		[newlist addObject:myList[p]];
	}
	return newlist;
}

//get this list as CSV string: first entry will be list length
-(NSString *)getListAsString{
	int listcount = (int)[myList count];
	NSString * first = [NSString stringWithFormat:@"%d\n",listcount];
	NSMutableString * myArrayAsCSV = [[NSMutableString alloc] init];
	[myArrayAsCSV appendString:first];
	for (int x=0;x<listcount;x++) {
		NSString * selmark = @"0";
		if ([selected[x] isEqualToNumber:sel]) {
			selmark=@"1";
		}
		NSString * row = [NSString stringWithFormat:@"%@,%@\n",myList[x],selmark];
		[myArrayAsCSV appendString:row];
	}
	return myArrayAsCSV;
}

//get list as CSV string with IDs
//Do ID checks before calling this function to avoid save loop
-(NSString *)getListWithIDAsString {
	//first entry is list length
	int listcount = (int)[myList count];
	NSString * first = [NSString stringWithFormat:@"%d\n",listcount];
	NSMutableString * myArrayAsCSV = [[NSMutableString alloc] init];
	[myArrayAsCSV appendString:first];
	//main list entries
	for (int x=0;x<listcount;x++) {
		int selmark = 0 + (int)[selected[x] intValue];
		int playID = (int)[listitemID[x] intValue];
		NSString * listentry = myList[x]; //already string
		//
		NSString * row = [NSString stringWithFormat:@"%@,%d,%d\n",listentry,playID,selmark];
		//NSLog(@"%@",row);
		[myArrayAsCSV appendString:row];
	}
	return myArrayAsCSV;
}

-(void)setDefaultList {
	myList = [[NSMutableArray alloc] init];
	[self addNewItem];
	[self saveList];
}

//load list.  First entry will be count of items
-(void)loadList {
	Fileops * myLoader = [[Fileops alloc] init];
	NSString * filename = [self getListFilename];
	NSString * fileContents = [myLoader loadListFile:filename];
	if ([fileContents isEqualToString:@"fileerror"] || fileContents.length<1) {
		[self setDefaultList];
	}
	else {
		[self processStringForList:fileContents];
	}
}

-(void)processStringForList:(NSString *)input {
	//process row file
	NSString * EOL = @"\n";
	NSArray * rowfile = [input componentsSeparatedByString:EOL];
	if ([rowfile count]<2) {
		[self setDefaultList];
	}
	//this assumes one entry on first line i.e. row[0] is just one int
	//To do: have a list file contain number of row entries and data format info first line
	int listcount = [rowfile[0] intValue];
	if (listcount<1) {
		[self setDefaultList]; //or return file error
		return;
	}

	//read in each row
	for (int x=0;x<listcount;x++) {
		NSString * nextEntry = rowfile[x+1];
		NSString * cleanitem = [nextEntry stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		//make an array with whatever is on the row
		NSArray * myrow = [cleanitem componentsSeparatedByString:@","];
		NSNumber * selitem = unsel; //default value is unselected state
		//CASE 1: just one item in row
		if (myrow.count==1) {
			[myList addObject:myrow[0]];
			//add a new universal counter to lists without one
			NSInteger counter = [myAppDelegate newUnivCounter];
			NSNumber * myNum = @(counter);
			[listitemID addObject:myNum];
			hasListIDs = TRUE;
			[selected addObject:selitem];
			[self saveList];
		}
		//CASE 2
		if (myrow.count==2) {
		[myList addObject:myrow[0]]; //list item
		//selected status
		int selint = [myrow[1] intValue];
			if (selint==1) {
				selitem=sel; //change it to selected
		}
		//add a new universal counter to lists without one
		NSInteger ucounter = [myAppDelegate newUnivCounter];
		NSNumber * myNum = @(ucounter);
		//old compiler, use NSNumber *myNum = [NSNumber numberWithInteger:myNsIntValue];
		[listitemID addObject:myNum];
		hasListIDs = TRUE;
		[selected addObject:selitem];
		[self saveList]; //save the updates to new IDs
		}
		//CASE 3
		if (myrow.count>=3) {
			[myList addObject:myrow[0]]; //list item
			//Set data type of ID entry
			NSInteger plyCode = [myrow[1] intValue]; //converts strings?
			if (plyCode<=0) {
				plyCode=0;
			}
			NSNumber * plyCodeObj = [NSNumber numberWithInteger:plyCode];
			[listitemID addObject:plyCodeObj]; //use existing ID
			hasListIDs = TRUE;
			//add selection
			int selint = [myrow[2] intValue];
			if (selint==1) {
				selitem=sel; //change it to object for array
			}
			[selected addObject:selitem];
		}
	}
	[self doIDchecking]; //check if loaded IDs are valid
}

-(void)deleteListItem:(int)index  {
	[self doIDchecking];
	[myList removeObjectAtIndex:index];
	[listitemID removeObjectAtIndex:index];
	[selected removeObjectAtIndex:index];
	//save current List
	[self saveList];
	//check if last item; if so, create default
	if (myList.count<1) {
		[self setDefaultList]; //performs save
	}
}

-(void)insertListItem:(NSString *)myItem withID:(int)itemID atIndex:(int)index {
	NSString * newname = [self checkfilename:myItem];
	[self doIDchecking];
	//NSNumber * IDNum = listitemID[index];
	NSNumber * myID = [NSNumber numberWithInt:itemID];
	[listitemID insertObject:myID atIndex:index];
	[myList insertObject:newname atIndex:index];
	[selected insertObject:sel atIndex:index];
}

-(void)addNewItem {
	NSString * token = @"NewItem";
	[self addListItem:token];
	/*
	 [myList addObject:newItem];
	NSNumber * newcount = @([myAppDelegate newUnivCounter]);
	[listitemID addObject:newcount];  //add this ID silently
	[selected addObject:unsel];
	[self saveList];
	 */
}

//Specify new item name
//called by external functions - has counter included
-(void)addListItem:(NSString *)newItem {
	NSString * newname = [self checkfilename:newItem];
	[myList addObject:newname];
	NSNumber * ucount = @([myAppDelegate newUnivCounter]);
	[listitemID addObject:ucount];  //add this ID silently
	[selected addObject:unsel];
	[self saveList];
}

//called by clone function only
-(void)copyListItem:(NSString *)newItem {
	NSString * newname = [self checkfilename:newItem];
	[myList addObject:newname];
}

//called by clone function only
-(void)addSelectedDefault{
	[selected addObject:unsel];
}

//called by clone function only
-(void)addListID:(NSNumber *)newID {
	[listitemID addObject:newID];
}

//return listID as an integer
-(int)getListID:(int)index {
	NSNumber * myID = listitemID[index];
	return (int)[myID intValue];
}

-(NSString *)printList {
	[self doIDchecking];
	int countme = (int)[myList count];
	int pid = 0;
	NSMutableString * output = [[NSMutableString alloc]init];
	for (int i=0;i<countme;i++) {
		pid = [self getListID:i];
		NSString * pname = [self getListItem:i];
		NSString * row = [NSString stringWithFormat:@"%@ %d \n",pname,pid];
		[output appendString:row];
		}
	NSString * EOL = @"\n";
	[output appendString:EOL];
	return output;
}

//replace an item that itself has child list (1 level)
-(void)replaceItem:(int)myListIndex withItem:(NSString *)newObject {
	[self doIDchecking];
	NSString * old = myList[myListIndex];
	NSString * safename = [self checkfilename:newObject];
	//rename the List on disk
	Fileops * mySaver = [[Fileops alloc] init];
	NSString * extn = @"csv";
	[mySaver renameFile:old newname:safename ext:extn];
	//rename the item in the present list
	[myList replaceObjectAtIndex:myListIndex withObject:safename];
	//save the list
	[self saveList];
}

//replace an item with item and its ID
-(void)replaceItem:(int)myListIndex withItem:(NSString *)newObject ID:(NSInteger)itemID {
	[self doIDchecking];
	NSString * old = myList[myListIndex];
	NSString * safename = [self checkfilename:newObject];
	//rename the List on disk
	Fileops * mySaver = [[Fileops alloc] init];
	NSString * extn = @"csv";
	[mySaver renameFile:old newname:safename ext:extn];
	//rename the item in the present list
	[myList replaceObjectAtIndex:myListIndex withObject:safename];
	//add the new ID
	NSNumber * numID = @(itemID);
	[listitemID replaceObjectAtIndex:myListIndex withObject:numID];
	//save the list
	[self saveList];
}


//replace an element of a list that has no child lists
-(void)replaceLeafItem:(int)myListIndex withItem:(NSString *)newObject ID:(NSInteger)itemID{
	//rename the item in the present list
	NSString * safename = [self checkfilename:newObject];
	[myList replaceObjectAtIndex:myListIndex withObject:safename];
	//add the new ID
	NSNumber * numID = @(itemID);
	[listitemID replaceObjectAtIndex:myListIndex withObject:numID];
	//save the list
	[self saveList];
}

-(NSString *)getListItem:(int)index {
	NSString * myString = myList[index];
	return myString;
}

-(NSInteger)count {
	return myList.count;
}

//SELECTION

-(void)setUnselected:(int)index {
	[selected replaceObjectAtIndex:index withObject:unsel];
}

-(void)toggleSelection:(int)index {
	if ([selected[index] isEqualToNumber:sel]) {
		[selected replaceObjectAtIndex:index withObject:unsel];
	}
	else {
		[selected replaceObjectAtIndex:index withObject:sel];
	}
		[self saveList];
}

-(BOOL)isSelected:(int)row {
	if ([selected[row] isEqualToNumber:sel]) {
		return TRUE;
	}
	else {
		return FALSE;
	}
}

//Method to ensure all list entries have IDs from universal counter
-(void)doIDchecking {
	int numentries = (int)[myList count];
	//check enough ID valid entries in this list; if not add until full
	for (int x=0;x<numentries-1;x++) {
		int IDcheck = (int)[listitemID count]-1;
		if (x>IDcheck) {
			NSNumber * newcount = @([myAppDelegate newUnivCounter]);
			[listitemID addObject:newcount];
		}
		//where it exists, check it is initialised
		if (listitemID[x]==NULL) {
			NSNumber * newcount = @([myAppDelegate newUnivCounter]);
			[listitemID replaceObjectAtIndex:x withObject:newcount];
		}
	}
	//check if existing IDs are valid, replace if needed
	for (int x=0;x<numentries-1;x++) {
			int testID = (int)[listitemID[x] intValue];
			if (testID<3141) {
				NSNumber * newcount = @([myAppDelegate newUnivCounter]);
				[listitemID replaceObjectAtIndex:x withObject:newcount];
			}
	}
	//change status
	if (hasListIDs==FALSE) {
		hasListIDs=TRUE;
	}
	//check enough sel entries in this list; if not add until full
	for (int x=0;x<numentries-1;x++) {
		int SELcheck = (int)selected.count-1;
		if (x>SELcheck) {
			[selected addObject:unsel];
		}
	}
	[self saveList]; //save this list in case IDs updated
}

//
-(List *)cloneSelected {
	List * newlist = [[List alloc] init];
	NSString * newname = [NSString stringWithFormat:@"%@_team",[self getListFilename]];
	[newlist setListFilename:newname];
	int numentries = (int)[myList count];
	[self doIDchecking];
	// Now do the main cloning
		for (int x=0;x<numentries;x++) {
		if ([self isSelected:x]) {
			//copy the string part
			[newlist copyListItem:myList[x]];
			//copy the ID
			[newlist addListID:listitemID[x]];
			//set unselected in new list
			[newlist addSelectedDefault];
			//set IDs
			[newlist setHasIDs];
			}
		}
	return newlist;
}

@end
