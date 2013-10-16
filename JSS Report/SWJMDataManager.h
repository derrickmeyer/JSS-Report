//
//  SWJMDataManager.h
//  JSS Monitor
//
//  Created by Jeremy Matthews on 8/24/13.
//  Copyright (c) 2013 SISU Works LLC. All rights reserved.
//

#import "AFHTTPClient.h"

@interface SWJMDataManager : AFHTTPClient
{
    
}

-(void)setUsername:(NSString *)username andPassword:(NSString *)password;

+(SWJMDataManager *)sharedManager;
+(NSURL *)url;

@end
