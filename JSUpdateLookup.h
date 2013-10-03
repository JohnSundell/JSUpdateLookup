//
//  JSUpdateLookup
//  Copyright (c) 2013 John Sundell
//

#import <Foundation/Foundation.h>

@class JSUpdateLookup;
@class JSUpdateInfo;

typedef void(^JSUpdateLookupCompletionHandler)(JSUpdateInfo *updateInfo, NSError *error);

/**
 *	Delegate protocol to get notified of update lookup events
 */
@protocol JSUpdateLookupDelegate <NSObject>

/**
 *	Sent to the update lookup's delegate when it has finished loading
 *
 *	@param updateLookup The update lookup instance that triggered the event.
 *	@param updateInfo Object containing update info (see JSUpdateInfo).
 */
- (void)updateLookup:(JSUpdateLookup *)updateLookup didFinishWithInfo:(JSUpdateInfo *)updateInfo;

/**
 *	Sent to the update lookup's delegate if it failed to load update info
 *
 *	@param updateLookup The update lookup instance that triggered the event.
 *	@param error An error that identifies the reason why the lookup failed.
 */
- (void)updateLookup:(JSUpdateLookup *)updateLookup didFailWithError:(NSError *)error;

@end

/**
 *	Class used to gather information about whether an app has an update available on the App Store
 */
@interface JSUpdateLookup : NSObject

/**
 *	Will be set to YES if this is the first time an update lookup was performed for this version,
 *	and a lookup has previously been performed for an earlier version of the same app.
 */
@property (nonatomic, readonly) BOOL isFirstLookupForUpdatedApp;

/**
 *	Initialize an update lookup instance with an App ID and a delegate
 *
 *	@param appID The App ID to lookup update info for.
 *	@param delegate The object acting as a delegate to the update lookup.
 *	@discussion The lookup will start loading as soon as it has been initialized.
 */
+ (instancetype)updateLookupWithAppID:(NSUInteger)appID andDelegate:(id<JSUpdateLookupDelegate>)delegate;

/**
 *	Initialize an update lookup instance with an App ID and a completion handler block
 *
 *	@param appID The App ID to lookup update info for.
 *	@param delegate The completion handler block to run when the lookup has completed.
 *	@discussion The lookup will start loading as soon as it has been initialized.
 *	The completion handler will be called whether or not the lookup was successful.
 */
+ (instancetype)updateLookupWithAppID:(NSUInteger)appID andCompletionHandler:(JSUpdateLookupCompletionHandler)completionHandler;

/**
 *	Schedule that an update lookup should be performed when the app becomes active
 *	(not by launching), after the set interval has passed
 *
 *	@discussion Once the update has been successfully performed, a new one will be
 *	scheduled using the same interval.
 *	This is useful for performing periodic update checks.
 *	The scheduled lookup will be cancelled if the app is terminated.
 */
- (void)scheduleLookupWithInterval:(NSTimeInterval)interval;

/**
 *	Cancel a previously scheduled update lookup
 */
- (void)cancelScheduledLookup;

@end

/**
 *	Class containing update info about an app
 */
@interface JSUpdateInfo : NSObject;

/**
 *	Initialize an info object with a dictionary containing data from the App Store web service
 *
 *	@discussion JSUpdateLookup will create a JSUpdateInfo instance for you.
 */
- (instancetype)initWithAppStoreInfo:(NSDictionary *)appStoreInfo;

/**
 *	The current version of this app (equivalent to CFBundleShortVersionString)
 */
@property (nonatomic, strong, readonly) NSString *currentAppVersion;

/**
 *	The latest version available on the App Store
 */
@property (nonatomic, strong, readonly) NSString *latestAppVersion;

/**
 *	Whether or not an update is available for this app
 */
@property (nonatomic, readonly) BOOL updateAvailable;

/**
 *	The latest release notes for the app
 */
@property (nonatomic, strong, readonly) NSString *releaseNotes;

@end