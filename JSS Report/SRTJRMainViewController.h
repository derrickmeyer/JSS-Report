//
//  SRTJRMainViewController.h
//  JSS Report
//
//  Created by Jeremy Matthews on 10/14/13.
//  Copyright (c) 2013 Stony River Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYPieChart.h"

@interface SRTJRMainViewController : UIViewController <XYPieChartDataSource, XYPieChartDelegate>
{
    
}

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end
