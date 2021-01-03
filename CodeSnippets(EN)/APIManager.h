//
//  APIManager.h
//  GitHubAPI
//
//  Created by Admin on 13/05/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIConsts.h"
#import "AuthProtocol.h"
#import <RXNetworkOperation/RXNO_OperationProtocols.h>


NS_ASSUME_NONNULL_BEGIN

// models
@class Friend;
@class UserProfile;
@class WallPost;
@class Photo;
@class PhotoGalleryCollection;


/*--------------------------------------------------------------------------------------------------------------
 🌐🕹 'APIManager' - manages all network connections.
 ---------------
 The main task of the class is to create, modify, and perform network operations.
 ---------------
 [⚖️] Duties:
 - Provide methods for interacting with the product API.
 - Be a delegate and conform the <Auth2_0_Delegate> protocol to support authentication.
 - Manage the received token. Store property, write and delete from memory.
 --------------------------------------------------------------------------------------------------------------*/


@interface APIManager : NSObject <Auth2_0_Delegate>

#pragma mark - URLSession
/*--------------------------------------------------------------------------------------------------------------
 This class supports several ways to implement Internet connection.
 1) The execution of all requests using 'RXNetworkOperation'.
 2) Self-configuring operations using 'NSURLSession' itself.
 3) You can also have as many custom sessions as you want for different situations.
 ---
 (⚠️) You may also have a situation where you want to work together with 'RXNetworkOperation' but you need to
 to customize the session as much as possible, then in the 'operation.privateSession' property, you can assign
 each operation value of 'APIManager.defaultSession'
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, readonly, strong) NSURLSession* defaultSession;


#pragma mark - Queues
/*--------------------------------------------------------------------------------------------------------------
 The queues where all network operations are performed by default.
 We recommend performing group operations on a synchronous queue.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, readonly, strong) NSOperationQueue* aSyncQueue;

@property (class, nonatomic, readonly, strong) NSOperationQueue* syncQueue;


#pragma mark - Token Property
/*--------------------------------------------------------------------------------------------------------------
 Property stores the token received from the server. If you previously received it and then restarted the app, the
 redefined getter will extract the token from the 'Keychain' itself.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, strong, nullable) Token* token;



#pragma mark - BaseURL & EndPoint
/*--------------------------------------------------------------------------------------------------------------
 Property was created for the convenience of configuring requests in the future. You can specify the base prefix
 'https://api.vk.com/method/' which will be added to all API requests
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, strong, nullable) NSString* baseURL;


/*--------------------------------------------------------------------------------------------------------------
 Returns the result of joining two strings. 'baseURL' and the value from the 'method' argument.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) baseURLappend:(NSString*)method;


#pragma mark - Customization
/*--------------------------------------------------------------------------------------------------------------
 The method was created to allow additional configuration of 'APIManager' before use.
 For example, you want to set some additional custom parameters.
 You can do this by calling this method inside 'didFinishLaunchingWithOptions:..'.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) prepareAPIManagerBeforeUsing:(nullable void(^)(void))completion;




#pragma mark - Network Operations

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 .__   __.  _______ .___________.____    __    ____  ______   .______       __  ___
 |  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  /
 |   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /
 |  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <
 |  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \
 |__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\
 
   ______   .______    _______ .______          ___   .___________. __    ______   .__   __.      _______.
  /  __  \  |   _  \  |   ____||   _  \        /   \  |           ||  |  /  __  \  |  \ |  |     /       |
 |  |  |  | |  |_)  | |  |__   |  |_)  |      /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
 |  |  |  | |   ___/  |   __|  |      /      /  /_\  \    |  |     |  | |  |  |  | |  . `  |     \   \
 |  `--'  | |  |      |  |____ |  |\  \----./  _____  \   |  |     |  | |  `--'  | |  |\   | .----)   |
  \______/  | _|      |_______|| _| `._____/__/     \__\  |__|     |__|  \______/  |__| \__| |_______/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of information about users
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) usersGet:(NSArray<NSString*>*)userIDs
           fields:(NSArray<NSString*>* _Nullable)fields
       completion:(nullable void(^)(NSArray<UserProfile*>* _Nullable userProfiles, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosCollectionFromID:(nullable NSString*)ownerID
                         offset:(NSInteger)offset
                          count:(NSInteger)count
                     completion:(nullable void(^)(PhotoGalleryCollection* _Nullable photoCollection, BO* op))completion;

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of posts from a user or community wall
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallGet:(nullable NSString*)ownerID
          offset:(NSInteger)offset
           count:(NSInteger)count
          filter:(nullable NSString*)filter
      completion:(nullable void(^)(NSArray<WallPost*>* _Nullable wallPosts, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
Allows you to create a post on the wall. The method takes an array of attachments and unloads them one at a time.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) wallPost:(nullable NSString*)ownerID
         message:(nullable NSString*)message
  attachmentsArr:(nullable NSArray<NSData*>*)attachments
       fromGroup:(BOOL)fromGroup
      completion:(nullable void(^)(NSNumber* _Nonnull postID, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
  Allows you to create a post on the wall. The method accepts the attachments string
  (that is, it requires the address of the already loaded content)
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
      attachments:(nullable NSString*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nullable postID, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 The method uploads an array of images to the server.
 Limitations: no more than 6 photos at a time in the method.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) uploadImages:(NSArray<NSData*>*)imagesData
              userID:(nullable NSString*)userID
             groupID:(nullable NSString*)groupID
          completion:(nullable void(^)(NSArray<NSDictionary*>* _Nullable savedImages, GO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Returns a list of the user's friends
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) friendListForUserID:(nullable NSString*)ownerID
                       order:(nullable NSString*)order
                      fields:(NSArray<NSString*>* _Nullable)fields
                       count:(NSInteger)count
                      offset:(NSInteger)offset
                  completion:(void(^)(NSArray<Friend*>* _Nullable friends, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Makes a request to the server. Clears cookies in 'WKWebsiteDataStore'.
 Resets the 'APIManager.token' value and removes the token from the 'KeyChain'.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) logout:(nullable void(^)(void)) completion;




#pragma mark - <Auth2_0_Delegate>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
   ______        ___      __    __  .___________. __    __      ___        ___
  /  __  \      /   \    |  |  |  | |           ||  |  |  |    |__ \      / _ \
 |  |  |  |    /  ^  \   |  |  |  | `---|  |----`|  |__|  |       ) |    | | | |
 |  |  |  |   /  /_\  \  |  |  |  |     |  |     |   __   |      / /     | | | |
 |  `--'  |  /  _____  \ |  `--'  |     |  |     |  |  |  |     / /_   __| |_| |
  \______/  /__/     \__\ \______/      |__|     |__|  |__|    |____| (__)\___/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 'AuthViewController' calls this method from its delegate and passes the received token to it.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) receiveTokenFromWebViewAuth:(nullable Token*)token error:(nullable NSError*)error;

/*--------------------------------------------------------------------------------------------------------------
 Using 'Router', it shows 'AuthViewController' and starts the authentication process
 --------------------------------------------------------------------------------------------------------------*/
+ (void) authenticationProcess:(nullable AuthenticationCompletion)completion;



#pragma mark - Token Access Methods

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 .___________.  ______    __  ___  _______ .__   __.
 |           | /  __  \  |  |/  / |   ____||  \ |  |
 `---|  |----`|  |  |  | |  '  /  |  |__   |   \|  |
     |  |     |  |  |  | |    <   |   __|  |  . `  |
     |  |     |  `--'  | |  .  \  |  |____ |  |\   |
     |__|      \______/  |__|\__\ |_______||__| \__|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) isThereTokenInKeychain;                //  Returns 'YES' if the token is written to the 'KeyChain'
+ (nullable Token*) restoreTokenFromKeychain;   //  Restores from 'KeyChain'

+ (void)     removeTokenInKeychain;             //  Deletes from 'KeyChain'
+ (NSError*) saveTokenInKeychain:(Token*)token; //  Saves in 'KeyChain'

/*--------------------------------------------------------------------------------------------------------------
 Updates the values for '@property token' and writes a new instance to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) updateToken:(NSString*)accessToken expiresAfter:(NSString*)expiresAfter userID:(NSString*)userID;



#pragma mark - Helpers - Syntax Sugar

///////////////////////////////////////////////////////////////////////////////
/*
  __    __   _______  __      .______    _______ .______          _______.
 |  |  |  | |   ____||  |     |   _  \  |   ____||   _  \        /       |
 |  |__|  | |  |__   |  |     |  |_)  | |  |__   |  |_)  |      |   (----`
 |   __   | |   __|  |  |     |   ___/  |   __|  |      /        \   \
 |  |  |  | |  |____ |  `----.|  |      |  |____ |  |\  \----.----)   |
 |__|  |__| |_______||_______|| _|      |_______|| _| `._____|_______/
 */
///////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Below will be presented methods that allow you to reduce the syntax of the code when working with the network layer.
 --------------------------------------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------------------------------------
 The method is called inside group operations to stop performing subsequent operations if the current one was
 completed with an error. The method calls the given 'completion' block if the operation contains 'error'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletion:(nullable void(^)(NSError* _Nullable error))completion ifOccuredErrorInOperation:(BO*)op;

/*--------------------------------------------------------------------------------------------------------------
 The method was created to shorten the syntax.
 Called inside the 'completion' method blocks of the APIManager class.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithTwoArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1))completion ifOccuredErrorInOperation:(BO*)op;

+ (NSError*) callCompletionWithThreeArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1, id _Nullable arg2))completion ifOccuredErrorInOperation:(BO*)op;

@end
