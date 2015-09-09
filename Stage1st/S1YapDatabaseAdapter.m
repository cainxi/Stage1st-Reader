//
//  S1YapDatabaseAdapter.m
//  Stage1st
//
//  Created by Zheng Li on 8/8/15.
//  Copyright (c) 2015 Renaissance. All rights reserved.
//

#import "S1YapDatabaseAdapter.h"
#import "DatabaseManager.h"
#import "YapDatabaseQuery.h"
#import "YapDatabaseFullTextSearchTransaction.h"
#import "S1Topic.h"

@implementation S1YapDatabaseAdapter

#pragma mark - Backend Protocol

- (void)hasViewed:(S1Topic *)topic {
    [MyDatabaseManager.bgDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        S1Topic *tracedTopic = [transaction objectForKey:[topic.topicID stringValue] inCollection:Collection_Topics];
        if (tracedTopic == nil) {
            NSLog(@"Traced: \n%@",topic);
            [transaction setObject:[topic copy] forKey:[topic.topicID stringValue] inCollection:Collection_Topics];
        } else {
            tracedTopic = [tracedTopic copy];
            if (topic.topicID != nil && (tracedTopic.topicID == nil || (tracedTopic.topicID != nil && (![tracedTopic.topicID isEqualToNumber:topic.topicID])))) {
                tracedTopic.topicID = topic.topicID;
            }
            if (topic.title != nil && (tracedTopic.title == nil || (tracedTopic.title != nil && (![tracedTopic.title isEqualToString:topic.title])))) {
                tracedTopic.title = topic.title;
            }
            if (topic.fID != nil && (tracedTopic.fID == nil || (tracedTopic.fID != nil && (![tracedTopic.fID isEqualToNumber:topic.fID])))) {
                tracedTopic.fID = topic.fID;
            }
            if (topic.replyCount != nil && (tracedTopic.replyCount == nil || (tracedTopic.replyCount != nil && (![tracedTopic.replyCount isEqualToNumber:topic.replyCount])))) {
                tracedTopic.replyCount = topic.replyCount;
            }
            if (topic.lastViewedPage != nil && (tracedTopic.lastViewedPage == nil || (tracedTopic.lastViewedPage != nil && (![tracedTopic.lastViewedPage isEqualToNumber:topic.lastViewedPage])))) {
                tracedTopic.lastViewedPage = topic.lastViewedPage;
            }
            if (topic.lastViewedPosition != nil && (tracedTopic.lastViewedPosition == nil || (tracedTopic.lastViewedPosition != nil && (![tracedTopic.lastViewedPosition isEqualToNumber:topic.lastViewedPosition])))) {
                tracedTopic.lastViewedPosition = topic.lastViewedPosition;
            }
            if (topic.favorite != nil && (tracedTopic.favorite == nil || (tracedTopic.favorite != nil && (![tracedTopic.favorite isEqualToNumber:topic.favorite])))) {
                tracedTopic.favorite = topic.favorite;
            }
            if (topic.favoriteDate != nil && (tracedTopic.favoriteDate == nil || (tracedTopic.favoriteDate != nil && (![tracedTopic.favoriteDate isEqualToDate:topic.favoriteDate])))) {
                tracedTopic.favoriteDate = topic.favoriteDate;
            }
            tracedTopic.lastViewedDate = [NSDate date];
            NSLog(@"Traced: \n%@",tracedTopic);
            [transaction setObject:tracedTopic forKey:[tracedTopic.topicID stringValue] inCollection:Collection_Topics];
        }
    }];
}

- (void)removeTopicFromHistory:(NSNumber *)topicID {
    [MyDatabaseManager.bgDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:[topicID stringValue] inCollection:Collection_Topics];
    }];
}


- (NSMutableArray *)historyObjectsWithLeftCallback:(void (^)(NSMutableArray *))leftTopicsHandler
{
    NSMutableArray *historyTopics = [NSMutableArray array];
    [MyDatabaseManager.bgDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:Collection_Topics usingBlock:^(NSString *key, id object, BOOL *stop) {
            [historyTopics addObject:object];
        }];
    }];
    return historyTopics;
}

- (NSMutableArray *)favoritedObjects
{
    NSMutableArray *favoriteTopics = [NSMutableArray array];
    [MyDatabaseManager.bgDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:Collection_Topics usingBlock:^(NSString *key, id object, BOOL *stop) {
            S1Topic *topic = object;
            if ([topic.favorite boolValue]) {
                [favoriteTopics addObject:object];
            }
        }];
    }];
    return favoriteTopics;
}

-(void)setTopicFavoriteState:(NSNumber *)topicID withState:(BOOL)state
{
    
}

- (S1Topic *)tracedTopicByID:(NSNumber *)topicID
{
    __block S1Topic *topic = nil;
    [MyDatabaseManager.bgDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        topic = [transaction objectForKey:[topicID stringValue] inCollection:Collection_Topics];
    }];
    return topic;
}

- (NSNumber *)numberOfTopicsInDatabse {
    __block NSUInteger count = 0;
    [MyDatabaseManager.bgDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        count = [transaction numberOfKeysInCollection:Collection_Topics];
    }];
    return @(count);
}

- (NSNumber *)numberOfFavoriteTopicsInDatabse {
    __block NSUInteger count = 0;
    [MyDatabaseManager.bgDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [[transaction ext:Ext_FullTextSearch_Archive] enumerateKeysMatching:@"favorite:FY title:*" usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            count = count + 1;
        }];
    }];
    return @(count);
}




@end
