//
//  AlertOptionVCtrl.m
//  WeiJu
//
//  Created by Michael Luo on 9/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AlertOptionVCtrl.h"
#import "WeiJuAppPrefs.h"
#import "DataFetchUtil.h"

@interface AlertOptionVCtrl ()

@end

@implementation AlertOptionVCtrl

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = @"Manage Alerts";
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if(section==0)
		return 2;
    else 
		return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section==0) 
	{
		return @"When an invitation (to share your path) from another participant arrives";
	}
	
	if (section==1) 
	{
		return @"When a path update from another participant arrives";
	}

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AlertOption";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    UISwitch *demoSwitch;
	if(cell==nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		
		demoSwitch = [[UISwitch alloc] init];
		demoSwitch.frame=CGRectMake(cell.contentView.bounds.size.width - demoSwitch.bounds.size.width-25, (cell.contentView.bounds.size.height - demoSwitch.bounds.size.height)/2, demoSwitch.bounds.size.width, demoSwitch.bounds.size.height);
		[demoSwitch addTarget:self action:@selector(demoSwitch:) forControlEvents:UIControlEventValueChanged];
		demoSwitch.tag=199;
		[cell.contentView addSubview:demoSwitch];
		//cell.textLabel.text=@"Show Demo Event";
	}
	else {
		demoSwitch = (UISwitch *)[cell.contentView viewWithTag:199];
	}
	
	if (indexPath.section==0) 
	{
		if (indexPath.row==0) {
			cell.textLabel.text=@"Notification alert is";
			UIRemoteNotificationType alertType = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
			
			if(alertType & UIRemoteNotificationTypeAlert ) {
				demoSwitch.on=YES;
			}
			else {
				demoSwitch.on=NO;
			}
		}
		else 
		{
			cell.textLabel.text=@"Vibration is";
			if ([[WeiJuAppPrefs getSharedInstance] inviteVibrate]) {
				demoSwitch.on=YES;
			}
			else {
				demoSwitch.on=NO;
			}
		}
	}
	
	if (indexPath.section==1) 
	{
		cell.textLabel.text=@"Vibration is";
		if ([[WeiJuAppPrefs getSharedInstance] pathUpdateVibrate]) {
			demoSwitch.on=YES;
		}
		else {
			demoSwitch.on=NO;
		}
	}

    return cell;
}

-(void) demoSwitch:(id)sender
{
	UISwitch *demoSwitch = (UISwitch *)sender;
	UIView *contentView = [sender superview];
	UITableViewCell *cell = (UITableViewCell *)[contentView superview];
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	
	if (indexPath.section==0) 
	{
		if (indexPath.row==0) 
		{
			if(demoSwitch.on)
			{
                [DataFetchUtil saveButtonsEventRecord:@"95"];
				demoSwitch.on=NO;
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn on notification alert" message:@"You need to go to iPhone's \"Settings\", \"Notifications\", select this app, and set the \"Alert Style\" there.\n\nWe recommend you turn on \"Badge\" and \"Sounds\" too." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
				[alert show];
			}
			else {
                [DataFetchUtil saveButtonsEventRecord:@"96"];
				demoSwitch.on=YES;
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn off notification alert" message:@"You need to go to iPhone's \"Settings\", \"Notifications\", select this app, and set the \"Alert Style\" to be \"None\" there" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
				[alert show];
			}
		}
		else 
		{
			if (demoSwitch.on) {
                [DataFetchUtil saveButtonsEventRecord:@"97"];
				[[WeiJuAppPrefs getSharedInstance] setInviteVibrate:YES];
			}
			else {
                [DataFetchUtil saveButtonsEventRecord:@"98"];
				[[WeiJuAppPrefs getSharedInstance] setInviteVibrate:NO];
			}
		}
	}
	
	if (indexPath.section==1) 
	{
		if (demoSwitch.on) {
            [DataFetchUtil saveButtonsEventRecord:@"99"];
			[[WeiJuAppPrefs getSharedInstance] setPathUpdateVibrate:YES];
		}
		else {
            [DataFetchUtil saveButtonsEventRecord:@"1a"];
			[[WeiJuAppPrefs getSharedInstance] setPathUpdateVibrate:NO];
		}
	}
	
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
