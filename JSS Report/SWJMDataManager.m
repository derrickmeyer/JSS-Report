//
//  SWJMDataManager.m
//  JSS Monitor
//
//  Created by Jeremy Matthews on 8/24/13.
//  Copyright (c) 2013 SISU Works LLC. All rights reserved.
//

#import "SWJMDataManager.h"
#import "AFJSONRequestOperation.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation SWJMDataManager

#pragma mark - Methods

- (void)setUsername:(NSString *)username andPassword:(NSString *)password
{
    [self clearAuthorizationHeader];
    [self setAuthorizationHeaderWithUsername:username password:password];
}

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if(!self)
        return nil;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFJSONParameterEncoding];
    //[self setDefaultHeader:@"Accept-Charset" value:@"utf-8"];
    
    //[[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    return self;
}

#pragma mark - Singleton Methods

+ (SWJMDataManager *)sharedManager
{
    static dispatch_once_t pred;
    static SWJMDataManager *_sharedManager = nil;
        
    dispatch_once(&pred, ^{ _sharedManager = [[self alloc] initWithBaseURL:[self url]];
    });
    // You should probably make this a constant somewhere
    return _sharedManager;
}

+(NSURL *)url
{
    NSString *prefix = [[NSString alloc] init];
    if (usesSSL == YES)
    {
        prefix = @"https://";
    } else {
        prefix = @"http://";
    }
    
    NSURL *tempURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@:%lu/%@", prefix, hostname, (unsigned long)port, @"JSSResource/"]];
    
    return tempURL;
}

@end


