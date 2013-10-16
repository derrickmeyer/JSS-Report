//
//  SRTiLMLoginViewController.m
//
//  Created by Jeremy Matthews on 4/23/13.
//  Copyright (c) 2013 Stony River Technologies. All rights reserved.
//

#import "SRTiLMLoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"
#import "AJNotificationView.h"
#import "SRTJRMainViewController.h"


@interface SRTiLMLoginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UILabel *loginStatusTextField;
@property (strong, nonatomic) AJNotificationView *panelUnreachable;

@end

@implementation SRTiLMLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL displayLinkSupported;
    NSString *reqSysVer = @"6.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
    {
        displayLinkSupported = TRUE;
        //NSLog(@"you are OK; running %@", [[UIDevice currentDevice] systemVersion]);
    }
    
    [_panelUnreachable hide];
	// Do any additional setup after loading the view.
    AJNotificationView *panel = [AJNotificationView showNoticeInView:self.view
                                                                type:AJNotificationTypeBlue
                                                               title:@"Connecting"
                                                     linedBackground:AJLinedBackgroundTypeAnimated
                                                           hideAfter:0];

    dispatch_queue_t queue = dispatch_queue_create("something relevant goes here", NULL);
    dispatch_async(queue, ^{
        //put in any async (no uikit) instructions
            dispatch_async(dispatch_get_main_queue(), ^{
                //put in any non-asyn calls here
                
                [self.navigationController.navigationBar setHidden:YES];
                
                UIColor *darkGreen = [UIColor colorWithRed:0 green:201/255.0f blue:87/255.0f alpha:1];
                //UIColor *lightGreen = [UIColor colorWithRed:189/255 green:252/255.0f blue:201/255.0f alpha:1];
                UIColor *darkerGreen = [UIColor colorWithRed:0 green:185/255.0f blue:80/255.0f alpha:1];
                
                CAGradientLayer *gradient = [CAGradientLayer layer];
                gradient.frame = [[UIScreen mainScreen] bounds];
                gradient.colors = @[(id)[darkGreen CGColor], (id)[darkerGreen CGColor]];
                [self.view.layer insertSublayer:gradient atIndex:0];
                
                //border button
                [[_loginButton layer] setCornerRadius:8.0f];
                [[_loginButton layer] setBorderWidth:1.0];
                [[_loginButton layer] setBorderColor:[[UIColor whiteColor] CGColor]];
                
                //set initial elements
                /*
                [_loginButton setEnabled:NO];
                [_loginTextField setAlpha:.3];
                [_passwordTextField setAlpha:.3];
                
                //set field that we might kill
                [_loginStatusTextField setText:@"Connecting...."];
                 */
                
            });
    });
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability *reach = [Reachability reachabilityWithHostname:hostname];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        [self fadeInControls];
        [panel hide];
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        [self fadeOutControls];
        _panelUnreachable = [AJNotificationView showNoticeInView:self.view
                                                                    type:AJNotificationTypeRed
                                                                   title:@"No Internet Connection"
                                                         linedBackground:AJLinedBackgroundTypeStatic
                                                               hideAfter:10];

    };
    
    [reach startNotifier];
    
    //modify keyboard
    UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    [keyboardToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [keyboardToolbar setItems:@[[[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelLoginKeypad)],
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithLoginKeypad)]]];
    [keyboardToolbar sizeToFit];
    _loginTextField.inputAccessoryView = keyboardToolbar;
    _passwordTextField.inputAccessoryView = keyboardToolbar;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self clearIDAndPass];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability *reach = [note object];
    
    if([reach isReachable])
    {
        [self fadeInControls];
    }
    else
    {
        [self fadeOutControls];
    }
}

-(void)fadeOutControls
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_loginButton setEnabled:NO];
        [_passwordTextField setEnabled:NO];
        [_loginTextField setEnabled:NO];
        [_loginStatusTextField setText:@"Offline"];
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{_loginButton.alpha = 0.5;
                             _loginTextField.alpha = 0.5;
                             _passwordTextField.alpha = 0.5;}
                         completion:nil];
    });
}

-(void)fadeInControls
{
    [_loginButton setEnabled:YES];
    [_passwordTextField setEnabled:YES];
    [_loginTextField setEnabled:YES];
    [_loginStatusTextField setText:@"JSS Accessible"];
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{_loginButton.alpha = 1;
                         _loginTextField.alpha = 1;
                         _passwordTextField.alpha = 1;
                     }
                     completion:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    
    
}

-(void)cancelLoginKeypad
{
    if ([_loginTextField isFirstResponder])
    {
        [_loginTextField resignFirstResponder];
    }
    else if ([_passwordTextField isFirstResponder])
    {
        [_passwordTextField resignFirstResponder];
    }
    
    [self clearIDAndPass];
}

-(void)doneWithLoginKeypad
{
    if ([_loginTextField isFirstResponder])
    {
        [_loginTextField resignFirstResponder];
    }
    else if ([_passwordTextField isFirstResponder])
    {
        [_passwordTextField resignFirstResponder];
    }
}

-(void)clearIDAndPass
{
    [_loginTextField setText:@""];
    [_passwordTextField setText:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginAction:(UIButton *)sender
{
        if (1 == 0)
    {
        //here you can include some custom logic to check a current users' logged in status, permissions levels, etc...
    }
    else
    {
        //NSLog(@"login attempt");
        NSString *userName = [_loginTextField text];
        NSString *pass = [_passwordTextField text];
        
        NSString *userNameModified = [userName stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *passwordModified = [pass stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        //NSLog(@"username is %@", userNameModified);
        //NSLog(@"pass is %@", passwordModified);
        
        if (([userNameModified length] > 0) && ([passwordModified length] > 0))
        {
            //try and auth
            if (1 == 1) {
                NSLog(@"successful auth!");
                [_loginStatusTextField setText:@"Login Successful"];
                
                @try {
                    [self performSegueWithIdentifier:@"segue" sender:self];
                }
                @catch (NSException *exception) {
                    NSLog(@"exception is %@", exception);
                    
                }
                @finally {
                    
                }
                
            } else {
                NSLog(@"bad auth");
                [_loginStatusTextField setText:@"Incorrect ID or Password"];
                [self clearIDAndPass];
            }
            
            if ([_loginTextField isFirstResponder])
            {
                [_loginTextField resignFirstResponder];
            }
            else if ([_passwordTextField isFirstResponder])
            {
                [_passwordTextField resignFirstResponder];
            }
            
        }
        
        //zero-length id or pass
        [_loginStatusTextField setText:@"Incorrect ID or Password"];
        [self clearIDAndPass];
    }
    
}

/*
- (void)configureWithIDAndPassword:(NSString *)username password:(NSString *)password
{
    for (UIViewController *v in self.navigationController.viewControllers)
    {
        if ([v isKindOfClass:[SRTJRMainViewController class]])
        {
            SRTJRMainViewController *smvc = v;
            
            [smvc setUsername:[_loginTextField text]];
            [smvc setPassword:[_passwordTextField text]];
        }
    }
}
 */

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([[segue identifier] isEqualToString:@"segue"])
    {
        UIViewController *destination = segue.destinationViewController;
        [destination setValue:[_loginTextField text] forKey:@"username"];
        [destination setValue:[_passwordTextField text] forKey:@"password"];
        
        [[[[segue destinationViewController] navigationItem] backBarButtonItem] setTitle:@"logout"];
        [[[[segue destinationViewController] navigationItem] leftBarButtonItem] setTitle:@"Logout"];
        //[[[segue destinationViewController] navigationItem] setHidesBackButton:YES animated:YES];
        [[[segue destinationViewController] navigationItem] setTitle:@"Location"];
        [_loginStatusTextField setText:@""];
    }
    
}



@end
