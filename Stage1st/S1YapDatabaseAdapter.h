//
//  S1YapDatabaseAdapter.h
//  Stage1st
//
//  Created by Zheng Li on 8/8/15.
//  Copyright (c) 2015 Renaissance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "S1DataCenter.h"

@class DatabaseManager;

NS_ASSUME_NONNULL_BEGIN

@interface S1YapDatabaseAdapter : NSObject

- (instancetype)initWithDatabase:(DatabaseManager *)database;

@end

@interface S1YapDatabaseAdapter (Topic)

- (void)hasViewed:(S1Topic *)topic;
- (void)removeTopicFromHistory:(NSNumber *)topicID;
- (void)removeTopicFromFavorite:(NSNumber *)topicID;
- (S1Topic * _Nullable)topicByID:(NSNumber *)topicID;
- (NSNumber *)numberOfTopicsInDatabse;
- (NSNumber *)numberOfFavoriteTopicsInDatabse;
- (void)removeTopicBeforeDate:(NSDate *)date;

@end

@interface S1YapDatabaseAdapter (User)

- (void)blockUserWithID:(NSUInteger)userID;
- (void)unblockUserWithID:(NSUInteger)userID;
- (BOOL)userIDIsBlocked:(NSUInteger)userID;

@end

NS_ASSUME_NONNULL_END
