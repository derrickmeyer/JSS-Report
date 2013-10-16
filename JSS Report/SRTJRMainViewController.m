//
//  SRTJRMainViewController.m
//  JSS Report
//
//  Created by Jeremy Matthews on 10/14/13.
//  Copyright (c) 2013 Stony River Technologies. All rights reserved.
//

#import "SRTJRMainViewController.h"
#import "SWJMDataManager.h"
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"
#import "AFJSONRequestOperation.h"
#import "AJNotificationView.h"

@interface SRTJRMainViewController ()

//lists for computer ids
@property (nonatomic, copy) NSMutableArray *computerIDs;

//ledger items
@property (strong, nonatomic) IBOutlet UIView *leopardLedgerView;
@property (strong, nonatomic) IBOutlet UIView *snowLeopardLedgerView;
@property (strong, nonatomic) IBOutlet UIView *lionLedgerView;
@property (strong, nonatomic) IBOutlet UIView *mountainLionLedgerView;
@property (strong, nonatomic) IBOutlet UIView *mavericksLedgerView;
@property (strong, nonatomic) IBOutlet UISwitch *toggleButton;


//notifications
@property (strong, nonatomic) AJNotificationView *panelUnreachable;
@property (strong, nonatomic) AJNotificationView *panel;

@property (nonatomic, copy) NSMutableArray *osArray;

//items for pie chart
@property (nonatomic) IBOutlet XYPieChart *pieChart;
@property (nonatomic, strong) NSMutableArray *slices;
@property (nonatomic, strong) NSArray *sliceColors;

//other UI elements
@property (strong, nonatomic) IBOutlet UIButton *refreshButton;

//actions
- (IBAction)refreshDataAction:(id)sender;
- (IBAction)togglePercentageAction:(id)sender;

@end

@implementation SRTJRMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _computerIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //notifications
    
    [_panelUnreachable hide];

    _panel = [AJNotificationView showNoticeInView:self.view
                                             type:AJNotificationTypeBlue
                                            title:@"Working"
                                  linedBackground:AJLinedBackgroundTypeAnimated
                                        hideAfter:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [_pieChart setDelegate:self];
    [_pieChart setDataSource:self];
    [_pieChart setStartPieAngle:M_PI_2];
    [_pieChart setAnimationSpeed:1.0];
    [_pieChart setLabelFont:[UIFont fontWithName:@"DBLCDTempBlack" size:18]];
    [_pieChart setLabelRadius:80];
    [_pieChart setShowPercentage:YES];
    [_pieChart setPieBackgroundColor:[UIColor colorWithWhite:0.95 alpha:1]];
    [_pieChart setPieCenter:CGPointMake(_pieChart.bounds.size.width / 2.0f, _pieChart.bounds.size.height / 2.0f)
     ];
    [_pieChart setUserInteractionEnabled:NO];
    [_pieChart setLabelShadowColor:[UIColor blackColor]];
    
    //only performing 5 major OS checks (leopard, snow leopard, etc.)
    self.slices = [NSMutableArray arrayWithCapacity:5];
    
    
    //set slice colors
    self.sliceColors =[NSArray arrayWithObjects:
                       [UIColor colorWithRed:246/255.0 green:155/255.0 blue:0/255.0 alpha:1],
                       [UIColor colorWithRed:129/255.0 green:195/255.0 blue:29/255.0 alpha:1],
                       [UIColor colorWithRed:62/255.0 green:173/255.0 blue:219/255.0 alpha:1],
                       [UIColor colorWithRed:229/255.0 green:66/255.0 blue:115/255.0 alpha:1],
                       [UIColor colorWithRed:148/255.0 green:141/255.0 blue:139/255.0 alpha:1],nil];
    
    //match background ledger colors to slice colors
    [_leopardLedgerView setBackgroundColor:[_sliceColors objectAtIndex:0]];
    [_snowLeopardLedgerView setBackgroundColor:[_sliceColors objectAtIndex:1]];
    [_lionLedgerView setBackgroundColor:[_sliceColors objectAtIndex:2]];
    [_mountainLionLedgerView setBackgroundColor:[_sliceColors objectAtIndex:3]];
    [_mavericksLedgerView setBackgroundColor:[_sliceColors objectAtIndex:4]];
    
    [self doIt];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability *reach = [note object];
    
    if([reach isReachable])
    {
        //NSLog(@"online from Main view controller");
        [self fadeInControls];
        
        [_panelUnreachable hide];
    }
    else
    {
        //NSLog(@"offline from Main view controller");
        [self fadeOutControls];
        
        _panelUnreachable = [AJNotificationView showNoticeInView:self.view
                                                            type:AJNotificationTypeRed
                                                           title:@"No Internet Connection"
                                                 linedBackground:AJLinedBackgroundTypeStatic
                                                       hideAfter:10];
    }
}

-(void)fadeOutControls
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshButton setEnabled:NO];
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{_pieChart.alpha = 0.5;
                             _refreshButton.alpha = 0.5;}
                         completion:nil];
    });
}

-(void)fadeInControls
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_refreshButton setEnabled:YES];
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{_pieChart.alpha = 1;
                             _refreshButton.alpha = 1;}
                         completion:nil];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)doIt
{
    //set login parameters for API access
    [[SWJMDataManager sharedManager] setUsername:_username andPassword:_password];
    
    [[SWJMDataManager sharedManager] getPath:@"computers" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON)
     {
         //check array count and use it as an index for processing data returned
         if ([[[JSON objectForKey:@"computers"] objectForKey:@"computer"] count] == 0)
         {
             NSLog(@"no data to find");
         }
         else if ([[[JSON objectForKey:@"computers"] objectForKey:@"computer"] count] == 1)
         {
             NSLog(@"array item 1 is %@", [[[JSON objectForKey:@"computers"] objectForKey:@"computer"] objectAtIndex:0]);
         }
         else
         {
             [_computerIDs removeAllObjects];
             //NSLog(@"count is %lu", (unsigned long)[[[JSON objectForKey:@"computers"] objectForKey:@"computer"] count]);
             //pass all returned computer id's to lookup function
             [self osReadout:[[[JSON objectForKey:@"computers"] objectForKey:@"computer"] valueForKey:@"id"]];
         }
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         //throw access error
         NSLog(@"failed to access online store");
         NSLog(@"login credentials are bad, or network connectivity is not solid, or this account does not have sufficient permissions");
     }];
}

-(void)osReadout:(NSArray *)computerCodes
{
    _osArray  = [[NSMutableArray alloc] init];

    [_osArray removeAllObjects];
    
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSUInteger index = 0;
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[SWJMDataManager url]];
    [httpClient setAuthorizationHeaderWithUsername:_username password:_password];
    [httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setParameterEncoding:AFJSONParameterEncoding];

    NSMutableArray *requests = [[NSMutableArray alloc] init];
    for (id object in computerCodes)
    {
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@%@",
                                                                                  @"computers/id/",
                                                                                  [computerCodes objectAtIndex:index]] parameters:nil];
        [requests addObject:request];
        index++;
    }
    
    [[SWJMDataManager sharedManager] enqueueBatchOfHTTPRequestOperationsWithRequests:[requests copy] progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        NSLog(@"Finished %d of %d", numberOfFinishedOperations, totalNumberOfOperations);
    } completionBlock:^(NSArray *operations) {
        //debug
        //NSLog(@"array is %@", operations);
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"Compare Everything" object:nil];
        @try {
            //debug
            //NSLog(@"Json is %@", [[[operations objectAtIndex:0] responseData] class]);
            //NSLog(@"real json is %@", [[operations objectAtIndex:0] responseJSON]);
            
            NSUInteger index = 0;
            for (id operation in operations)
            {
                
                if ([[[[[operation responseJSON] objectForKey:@"computer"] objectForKey:@"hardware"] objectForKey:@"os_version"] isKindOfClass:[NSString class]] )
                {
                    //NSLog(@"string");
                    NSString *osRev23 = [[[[[[[operations objectAtIndex:index] responseJSON] objectForKey:@"computer"] objectForKey:@"hardware"] objectForKey:@"os_version"] componentsSeparatedByString:@"."] objectAtIndex:1];
                    //NSLog(@"osrev23 is %@", osRev23);
                    [_osArray addObject:osRev23];
                }
                else if ([[[[[operation responseJSON] objectForKey:@"computer"] objectForKey:@"hardware"] objectForKey:@"os_version"] isKindOfClass:[NSNumber class]] )
                {
                    //NSLog(@"number");
                    NSString *tmp = [[[[[operation responseJSON] objectForKey:@"computer"] objectForKey:@"hardware"] objectForKey:@"os_version"] stringValue];
                    NSString *osRev23 = [[tmp componentsSeparatedByString:@"."] objectAtIndex:1];
                    //NSLog(@"osrev 23 is %@", osRev23);
                    [_osArray addObject:osRev23];
                }
                index++;
            }
            
            int leopardCount = 0;
            int snowLeopardCount = 0;
            int lionCount = 0;
            int mountainLionCount = 0;
            int mavericksCount = 0;
            
            //NSLog(@"array is %@", _osArray);
            for (NSString *str in _osArray)
            {
                if ([str isEqualToString:@"5"])
                {
                    leopardCount++;
                }
                if ([str isEqualToString:@"6"])
                {
                    snowLeopardCount++;
                }
                if ([str isEqualToString:@"7"])
                {
                    lionCount++;
                }
                if ([str isEqualToString:@"8"])
                {
                    mountainLionCount++;
                }
                if ([str isEqualToString:@"9"])
                {
                    mavericksCount++;
                }
            }
            
            [_slices removeAllObjects];
            [_slices addObject:[NSNumber numberWithInt:leopardCount]];
            [_slices addObject:[NSNumber numberWithInt:snowLeopardCount]];
            [_slices addObject:[NSNumber numberWithInt:lionCount]];
            [_slices addObject:[NSNumber numberWithInt:mountainLionCount]];
            [_slices addObject:[NSNumber numberWithInt:mavericksCount]];
            
            [_pieChart reloadData];
            
            [_panel hide];
            
        }
        @catch (NSException *exception) {
            NSLog(@"exception is %@", exception);
        }
        @finally {
            NSLog(@"JSON reader transaction complete");
        }
        
    }];
       
}

- (IBAction)refreshDataAction:(id)sender
{
    [_panel hide];
    _panel = [AJNotificationView showNoticeInView:self.view
                                             type:AJNotificationTypeBlue
                                            title:@"Working"
                                  linedBackground:AJLinedBackgroundTypeAnimated
                                        hideAfter:0];
    [self doIt];
    [_pieChart reloadData];
}

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    //NSLog(@"%d data source slices", [_slices count]);
    return _slices.count;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [_slices[index] intValue];
    NSLog(@"intvalue is %d", [_slices[index] intValue]);
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    //if(pieChart == _pieChartOnly) return nil;
    return _sliceColors[(index % _sliceColors.count)];
    NSLog(@"color at index %lu is %@", (unsigned long)index, _sliceColors[(index % _sliceColors.count)]);
}

#pragma mark - XYPieChart Delegate
- (void)pieChart:(XYPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will select slice at index %d",index);
}
- (void)pieChart:(XYPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will deselect slice at index %d",index);
}
- (void)pieChart:(XYPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did deselect slice at index %d",index);
}
- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did select slice at index %d",index);
    //self.selectedSliceLabel.text = [NSString stringWithFormat:@"$%@",(self.slices)[index]];
}

- (IBAction)togglePercentageAction:(id)sender
{
    [_pieChart setShowPercentage:[_toggleButton isOn]];
}

@end
