//
//  JSUpdateLookup
//  Copyright (c) 2013 John Sundell
//

#import "JSUpdateLookup.h"

@interface JSUpdateLookup() <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readwrite) BOOL isFirstLookupForUpdatedApp;
@property (nonatomic) NSUInteger appID;
@property (nonatomic, weak) id<JSUpdateLookupDelegate> delegate;
@property (nonatomic, copy) JSUpdateLookupCompletionHandler completionHandler;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *connectionData;
@property (nonatomic) NSTimeInterval scheduledLookupInterval;
@property (nonatomic, strong) NSDate *nextScheduledLookupDate;

@end

@implementation JSUpdateLookup

#pragma mark - Public class methods

+ (instancetype)updateLookupWithAppID:(NSUInteger)appID andDelegate:(id<JSUpdateLookupDelegate>)delegate
{
	JSUpdateLookup *updateLookup = [[JSUpdateLookup alloc] init];
	updateLookup.appID = appID;
	updateLookup.delegate = delegate;
	[updateLookup start];
	
	return updateLookup;
}

+ (instancetype)updateLookupWithAppID:(NSUInteger)appID andCompletionHandler:(JSUpdateLookupCompletionHandler)completionHandler
{
	JSUpdateLookup *updateLookup = [[JSUpdateLookup alloc] init];
	updateLookup.appID = appID;
	updateLookup.completionHandler = completionHandler;
	[updateLookup start];
	
	return updateLookup;
}

#pragma mark - Public instance methods

- (void)scheduleLookupWithInterval:(NSTimeInterval)interval
{
	if (!self.nextScheduledLookupDate) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
	}
	
	self.scheduledLookupInterval = interval;
	[self setDateForNextScheduledLookup];
}

- (void)cancelScheduledLookup
{
	self.scheduledLookupInterval = 0;
	self.nextScheduledLookupDate = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private instance methods

- (void)start
{
	NSString *requestURL = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%u",self.appID];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestURL]];
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cleanupConnection
{
	self.connection = nil;
	self.connectionData = nil;
}

- (void)setDateForNextScheduledLookup
{
	if (self.scheduledLookupInterval > 0) {
		self.nextScheduledLookupDate = [[NSDate date] dateByAddingTimeInterval:self.scheduledLookupInterval];
	}	
}

- (void)appDidBecomeActive
{
	if ([self.nextScheduledLookupDate timeIntervalSinceNow] < -self.scheduledLookupInterval) {
		[self start];
	}
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self cleanupConnection];
	
	if (self.delegate) {
		return [self.delegate updateLookup:self didFailWithError:error];
	}
	
	self.completionHandler(nil, error);
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.connectionData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSDictionary *appStoreInfo = [NSJSONSerialization JSONObjectWithData:self.connectionData options:0 error:nil];
	
	if (appStoreInfo) {
		JSUpdateInfo *updateInfo = [[JSUpdateInfo alloc] initWithAppStoreInfo:appStoreInfo];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSString *lastLookupVersionStorageKey = @"JSVersionLookup_LastLookupVersion";
		NSString *lastLookupVersionString = [userDefaults objectForKey:lastLookupVersionStorageKey];
		
		self.isFirstLookupForUpdatedApp = lastLookupVersionString && ![lastLookupVersionString isEqualToString:updateInfo.currentAppVersion] && !updateInfo.updateAvailable;
		
		[userDefaults setObject:updateInfo.currentAppVersion forKey:lastLookupVersionStorageKey];
		[userDefaults synchronize];
		
		if(self.delegate)
		{
			[self.delegate updateLookup:self didFinishWithInfo:updateInfo];
		}
		else
		{
			self.completionHandler(updateInfo, nil);
		}
		
		[self setDateForNextScheduledLookup];
	} else {
		NSError *error = [NSError errorWithDomain:@"JSUpdateLookup" code:0 userInfo:@{@"error":@"Could not read data from App Store Web Service"}];
		
		if (self.delegate) {
			[self.delegate updateLookup:self didFailWithError:error];
		} else {
			self.completionHandler(nil, error);
		}
	}
	
	[self cleanupConnection];
}

@end

@implementation JSUpdateInfo

- (instancetype)initWithAppStoreInfo:(NSDictionary *)appStoreInfo
{
	if (!(self = [super init])) {
		return nil;
	}
	
	NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString *latestVersionString = [[[appStoreInfo objectForKey:@"results"] firstObject] objectForKey:@"version"];
	
	_currentAppVersion = currentVersionString;
	_latestAppVersion = latestVersionString;
	_updateAvailable = ![currentVersionString isEqualToString:latestVersionString];
	_releaseNotes = [[[appStoreInfo objectForKey:@"results"] firstObject] objectForKey:@"releaseNotes"];
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@\nCurrent app version: %@\nLatest App Version: %@\nUpdate available: %u\nRelease notes:%@", [super description], self.currentAppVersion, self.latestAppVersion, self.updateAvailable, self.releaseNotes];
}

@end