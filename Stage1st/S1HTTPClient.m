//
//  S1HTTPClient.m
//  Stage1st
//
//  Created by Suen Gabriel on 2/19/13.
//  Copyright (c) 2013 Renaissance. All rights reserved.
//

#import "S1HTTPClient.h"
#import "AFNetworking.h"


@implementation S1HTTPClient 

+ (S1HTTPClient *)sharedClient
{
    static S1HTTPClient *httpClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpClient = [[S1HTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"BaseURL"]]];
        httpClient.responseSerializer = [AFHTTPResponseSerializer serializer];
    });
    return httpClient;
}

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                     parameters:(id)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [operation setCompletionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end
