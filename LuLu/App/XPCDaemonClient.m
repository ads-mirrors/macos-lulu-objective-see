//
//  file: XPCDaemonClient.m
//  project: lulu (shared)
//  description: talk to daemon via XPC (header)
//
//  created by Patrick Wardle
//  copyright (c) 2017 Objective-See. All rights reserved.
//

#import "consts.h"
#import "XPCUser.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "XPCUserProto.h"
#import "XPCDaemonClient.h"

/* GLOBALS */

//log handle
extern os_log_t logHandle;

//alert (windows)
extern NSMutableDictionary* alerts;

@implementation XPCDaemonClient

@synthesize daemon;

//init
// create XPC connection & set remote obj interface
-(id)init
{
    //super
    self = [super init];
    if(nil != self)
    {
        //alloc/init
        daemon = [[NSXPCConnection alloc] initWithMachServiceName:DAEMON_MACH_SERVICE options:0];
    
        //set remote object interface
        self.daemon.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCDaemonProtocol)];
        
        //set exported object interface (protocol)
        self.daemon.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCUserProtocol)];
        
        //set exported object
        // this will allow daemon to invoke user methods!
        self.daemon.exportedObject = [[XPCUser alloc] init];
    
        //resume
        [self.daemon resume];
    }
    
    return self;
}

//get preferences
// note: synchronous, will block until daemon responds
-(NSDictionary*)getPreferences
{
    //preferences
    __block NSDictionary* preferences = nil;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
          //err msg
          os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);

   }] getPreferences:^(NSDictionary* preferencesFromDaemon)
   {
       //dbg msg
       os_log_debug(logHandle, "got preferences: %{public}@", preferencesFromDaemon);
       
       //save
       preferences = preferencesFromDaemon;
       
   }];
    
    return preferences;
}

//update (save) preferences
// note: will merge into current ones
-(NSDictionary*)updatePreferences:(NSDictionary*)preferences
{
    //updated preferences (from daemon)
    __block NSDictionary* updatedPreferences = nil;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //update prefs
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
          
    }] updatePreferences:preferences reply:^(NSDictionary* preferences)
    {
        //dbg msg
        os_log_debug(logHandle, "got preferences: %{public}@", preferences);
        
        //save
        updatedPreferences = preferences;
        
    }];
    
    return updatedPreferences;
}

//get rules
// note: synchronous, will block until daemon responds
-(NSDictionary*)getRules
{
    //rules
    __block NSMutableDictionary* rules = nil;
    
    //error
    __block NSError* error = nil;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //make XPC request to get rules
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] getRules:^(NSData* archivedRules)
    {
        //unarchive
        rules = [NSKeyedUnarchiver unarchivedObjectOfClasses:
                 [NSSet setWithArray: @[[NSMutableDictionary class], [NSMutableArray class], [NSString class], [NSNumber class], [NSMutableSet class], [NSDate class], [Rule class]]] fromData:archivedRules error:&error];
        
        if(nil != error)
        {
            //err msg
            os_log_error(logHandle, "ERROR: failed to unarchive rules: %{public}@", error);
        }
    
    }];
    
    return rules;
}

//add rule
-(void)addRule:(NSDictionary*)info
{
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with info: %{public}@", __PRETTY_FUNCTION__, info);
    
    //make XPC request to add rule
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] addRule:info];
    
    return;
}

//disable (or re-enable) rule
-(void)toggleRule:(NSString*)key rule:(NSString*)uuid state:(NSNumber*)state
{
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with key: %{public}@, rule id: %{public}@", __PRETTY_FUNCTION__, key, uuid);
    
    //disable rule
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] toggleRule:key rule:uuid state:state];
    
    return;
}

//delete rule
-(void)deleteRule:(NSString*)key rule:(NSString*)uuid
{
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with key: %{public}@, rule id: %{public}@", __PRETTY_FUNCTION__, key, uuid);
    
    //delete rule
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] deleteRule:key rule:uuid];
    
    return;
}

//cleanup rules
-(NSInteger)cleanupRules
{
    //result
    __block NSInteger deletedRules = -1;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //import rules
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
          
    }] cleanupRules:^(NSInteger result)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done! (returned %ld)", __PRETTY_FUNCTION__, (long)deletedRules);
         
        //save result
        deletedRules = result;
         
    }];
    
    return deletedRules;
}

//update (save) preferences
-(BOOL)importRules:(NSData*)newRules
{
    //flag
    __block BOOL wasImported = NO;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //import rules
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
          
    }] importRules:newRules result:^(BOOL result)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done!", __PRETTY_FUNCTION__);
         
        //set flag
        wasImported = YES;
         
    }];
    
    return wasImported;
}

//get current profile
-(NSString*)getCurrentProfile
{
    //rules
    __block NSString* currentProfile = nil;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //make XPC request to get profiles
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError* proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] getCurrentProfile:^(NSString* currrentProfileFromDaemon)
    {
        //dbg msg
        os_log_debug(logHandle, "current profile from daemon: '%{public}@'", currrentProfileFromDaemon);
        
        //save
        currentProfile = currrentProfileFromDaemon;
    
    }];
    
    return currentProfile;
}

//get list of profiles
-(NSMutableArray*)getProfiles
{
    //rules
    __block NSMutableArray* profiles = nil;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //make XPC request to get profiles
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError* proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] getProfiles:^(NSArray* profilesFromDaemon)
    {
        //save
        profiles = [profilesFromDaemon mutableCopy];
    
    }];
    
    return profiles;
}

//set profile
-(BOOL)setProfile:(NSString*)name
{
    //flag
    __block BOOL wasSet = NO;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with name: %{public}@", __PRETTY_FUNCTION__, name);
    
    //send XPC message to set profile
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError* proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] setProfile:name reply:^(BOOL reply)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done!", __PRETTY_FUNCTION__);
          
        //set flag
        wasSet = reply;
          
    }];
    
    return wasSet;
}

//add profile
-(BOOL)addProfile:(NSString*)name preferences:(NSDictionary*)preferences
{
    //flag
    __block BOOL wasAdded = NO;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with %{public}@", __PRETTY_FUNCTION__, name);
    
    //make XPC request to add profile
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError* proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] addProfile:name preferences:preferences reply:^(BOOL reply)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done!", __PRETTY_FUNCTION__);
          
        //set flag
        wasAdded = reply;
          
    }];
    
    return wasAdded;
}

//delete profile
-(BOOL)deleteProfile:(NSString*)name
{
    //flag
    __block BOOL wasDeleted = NO;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s' with name: %{public}@", __PRETTY_FUNCTION__, name);
    
    //send XPC message to delete profile
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError* proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
        
    }] deleteProfile:name reply:^(BOOL reply)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done!", __PRETTY_FUNCTION__);
         
        //set flag
        wasDeleted = reply;
         
    }];
    
    //dbg msg
    os_log_debug(logHandle, "daemon XPC method, '%s' with name: %{public}@ returned", __PRETTY_FUNCTION__, name);
    
    return wasDeleted;
}

//uninstall
-(BOOL)uninstall
{
    //flag
    __block BOOL uninstalled = NO;
    
    //dbg msg
    os_log_debug(logHandle, "invoking daemon XPC method, '%s'", __PRETTY_FUNCTION__);
    
    //uninstall
    [[self.daemon synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
          
    }] uninstall:^(BOOL result)
    {
        //dbg msg
        os_log_debug(logHandle, "daemon XPC method, '%s', done!", __PRETTY_FUNCTION__);
        
        //set flag
        uninstalled = result;
        
    }];
    
    return uninstalled;

}

@end
