//
//  SentryBreadcrumbStore.m
//  Sentry
//
//  Created by Daniel Griesser on 22/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryBreadcrumbStore.h>
#import <Sentry/SentryBreadcrumb.h>
#import <Sentry/SentryLog.h>
#import <Sentry/SentryFileManager.h>

#else
#import "SentryBreadcrumbStore.h"
#import "SentryBreadcrumb.h"
#import "SentryLog.h"
#import "SentryFileManager.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SentryBreadcrumbStore ()

@property(nonatomic, strong) SentryFileManager *fileManager;

@end

@implementation SentryBreadcrumbStore

- (instancetype)initWithFileManager:(SentryFileManager *)fileManager {
    self = [super init];
    if (self) {
        self.maxBreadcrumbs = 50;
        self.fileManager = fileManager;
    }
    return self;
}

- (void)addBreadcrumb:(SentryBreadcrumb *)crumb {
    [SentryLog logWithMessage:[NSString stringWithFormat:@"Add breadcrumb: %@", crumb] andLevel:kSentryLogLevelDebug];
    [self.fileManager storeBreadcrumb:crumb];
}

- (NSUInteger)count {
    return [[self.fileManager getAllStoredBreadcrumbs] count];
}

- (void)clear {
    [self.fileManager deleteAllStoredBreadcrumbs];
}

- (void)removeOverflowBreadcrumbs:(NSArray<NSDictionary<NSString *, id> *>*)breadCrumbs {
    NSInteger numberOfBreadcrumbsToRemove = ((NSInteger)breadCrumbs.count) - ((NSInteger)self.maxBreadcrumbs);
    if (numberOfBreadcrumbsToRemove > 0) {
        for (NSUInteger i = 0; i < numberOfBreadcrumbsToRemove; i++) {
            [self.fileManager removeFileAtPath:[breadCrumbs objectAtIndex:i][@"path"]];
        }
        [SentryLog logWithMessage:[NSString stringWithFormat:@"Dropped %ld breadcrumb(s) due limit", (long)numberOfBreadcrumbsToRemove]
                         andLevel:kSentryLogLevelDebug];
    }
}

- (NSDictionary<NSString *, id> *)serialize {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];
    
    NSArray<NSDictionary<NSString *, id> *> *breadCrumbs = [self.fileManager getAllStoredBreadcrumbs];
    [self removeOverflowBreadcrumbs:breadCrumbs];
    
    NSMutableArray *crumbs = [NSMutableArray new];
    for (NSDictionary<NSString *, id> *crumb in breadCrumbs) {
        [crumbs addObject:[NSJSONSerialization JSONObjectWithData:crumb[@"data"] options:0 error:nil]];
    }
    if (crumbs.count > 0) {
        [serializedData setValue:crumbs forKey:@"breadcrumbs"];
    }
    
    return serializedData;
}

@end

NS_ASSUME_NONNULL_END

