JSUpdateLookup
==============

#### Don't be shy, tell your customers about your awesome new features!

* Easily check if your iOS App Store app has an update available.
* Uses the iTunes Store Web Service.
* Get info about latest version and most recent release notes.
* Check for first launch of a recently updated app (useful for iOS7's auto updates).

#### Here's how to use JSUpdateLookup:

##### 1. Create a property for the lookup

```objective-c
@property (nonatomic, strong) JSUpdateLookup *updateLookup; 
```

##### 2. Get your App ID from iTunes Connect

```objective-c
NSUInteger myAppID = 012345678;
```

##### 3. Initialize a lookup with either a delegate or a block

```objective-c
self.updateLookup = [JSUpdateLookup updateLookupWithAppID:myAppID andDelegate:self];
```

or

```objective-c
self.updateLookup = [JSUpdateLookup updateLookupWithAppID:myAppID andCompletionHandler:^(JSUpdateInfo *updateInfo, NSError *error) {
	// Do stuff	
}];
```

##### 4. If you're using a delegate, implement the JSUpdateLookupDelegate protocol

```objective-c
- (void)updateLookup:(JSUpdateLookup *)updateLookup didFailWithError:(NSError *)error
{
	// Handle error
}

- (void)updateLookup:(JSUpdateLookup *)updateLookup didFinishWithInfo:(JSUpdateInfo *)updateInfo
{
	// Do stuff
}
```

##### 5. The JSUpdateInfo object passed to your delegate or completion handler will contain the update info you need

* Whether an app update is available
* The current version of the app
* The latest version available on the App Store
* Most recent release notes

Use this info to display an update prompt with the latest version & most recent release notes to the user.

##### Optionally: Schedule a periodic lookup each time the app becomes active

JSUpdateLookup provides an easy way to periodically check for updates, as soon as the app becomes active.
Just use the following method:

```objective-c
[self.updateLookup scheduleLookupWithInterval:24 * 60 * 60];
```

The above usage will check for updates each day (provided that the app is used).

#### Hope that you'll enjoy using JSUpdateLookup!

Why not give me a shout on Twitter: [@johnsundell](https://twitter.com/johnsundell)