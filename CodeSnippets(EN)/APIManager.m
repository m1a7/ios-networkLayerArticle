//
//  APIManager.m
//  GitHubAPI
//
//  Created by Admin on 13/05/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "APIManager.h"
// Own Categories
#import "APIManager+Utilites.h"

// Other Network layer components
#import "NetworkRequestConstructor.h"
#import "Validator.h"
#import "Parser.h"
#import "Mapper.h"
#import "NSError+ShortStyle.h"

// Models
#import "Token.h"
#import "Friend.h"
#import "UserProfile.h"
#import "WallPost.h"

#import "OwnerPost.h"
#import "GroupOwnerPost.h"
#import "UserOwnerPost.h"

#import "Attachment.h"
#import "Photo.h"
#import "PhotoGalleryCollection.h"

// Router
#import "Router.h"

// Thirt-party libraries
#import "KFKeychain.h"
#import <RXNetworkOperation/RXNetworkOperation.h>
#import "FEMDeserializer.h"
#import "RealReachability.h"

// WKWebView
#import <WebKit/WebKit.h>
// Foundation
#import "MultiThreads.h"
// Another Classes
#import "Templater.h"


// Key for writing the token to the keyChain
#define vkAccessToken @"vkAccessToken"


static NSString         *_baseURL        = nil;
static NSURLSession     *_defaultSession = nil;
static NSOperationQueue *_aSyncQueue     = nil;
static NSOperationQueue *_syncQueue      = nil;

static Token            *_token                       = nil;
static BOOL              _isOpenAuthenticationProcess = NO;
static AuthenticationCompletion  _authenticationCompletion = nil;



@interface APIManager ()

@property (class, nonatomic, readwrite, strong) NSURLSession* defaultSession;
@property (class, nonatomic, readwrite, strong) NSOperationQueue* aSyncQueue;
@property (class, nonatomic, readwrite, strong) NSOperationQueue* syncQueue;

/*--------------------------------------------------------------------------------------------------------------
 A block that takes the 'authenticationProcess:' method is subsequently stored in this property.
 And it is called after the completion (successful or unsuccessful) of the authentication process.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, copy) AuthenticationCompletion authenticationCompletion;

/*--------------------------------------------------------------------------------------------------------------
 If the operation was performed with a 401 error (authentication error), it adds to the array of deferred operations,
 and then we call the 'authenticationProcess:' method, which will show the UI and allow the user to enter a password and username.
 
 Since several operations can end with this error at once therefore several operations can cause
 the 'authenticationProcess:' method. To avoid collisions and multiple controllers being presented at once, this variable was made.

 It allows the code inside the 'authenticationProcess:' to execute only if it is set to 'NO'.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, assign) BOOL isOpenAuthenticationProcess;

@end


@implementation APIManager

@dynamic defaultSession;
@dynamic token;


#pragma mark - BaseURL & EndPoint
/*--------------------------------------------------------------------------------------------------------------
  Returns the result of joining two strings. 'baseURL' and the value from the 'method' argument.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) baseURLappend:(NSString*)method
{
    if (method.length < 1){
        return [API baseURL];
    }
    return [[API baseURL] stringByAppendingString:method];
}

#pragma mark - Customization
/*--------------------------------------------------------------------------------------------------------------
 The method was created to allow additional configuration of 'APIManager' before use.
 For example, you want to set some additional custom parameters.
 You can do this by calling this method inside 'didFinishLaunchingWithOptions: ..'.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) prepareAPIManagerBeforeUsing:(nullable void(^)(void))completion
{
    [API setBaseURL:@"https://api.vk.com/method/"];
    
    GLobalRealReachability.hostForPing  = @"www.google.com";
    GLobalRealReachability.hostForCheck = @"www.goolge.com";
    
    if (completion) completion();
}


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
       completion:(nullable void(^)(NSArray<UserProfile*>* _Nullable userProfiles, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_UsersGet:userIDs
                                                                               fields:fields
                                                                             nameCase:nil];
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
       
        // Check on 401 and other server's error
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
            
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_UserGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<UserProfile*>* userProfiles = [Mapper usersGetFromJSON:op.json error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:userProfiles error:error block:completion]){
            return;
        }
        
        // Call completion
        if (completion) completion(userProfiles,op);
    }];
    //netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosCollectionFromID:(nullable NSString*)ownerID
                         offset:(NSInteger)offset
                          count:(NSInteger)count
                     completion:(nullable void(^)(PhotoGalleryCollection* _Nullable photoCollection, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_PhotosGetAll:ownerID offset:offset count:count];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_PhotosGetAll];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        PhotoGalleryCollection* collection = [Mapper photosCollectionFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:collection error:error block:completion]){
            return;
        }
        
        // Call completion
        if (completion) completion(collection,op);
    }];
    //netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns a list of the user's friends
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) friendListForUserID:(nullable NSString*)ownerID
                       order:(nullable NSString*)order
                      fields:(NSArray<NSString*>* _Nullable)fields
                       count:(NSInteger)count
                      offset:(NSInteger)offset
                  completion:(void(^)(NSArray<Friend*>* _Nullable friends, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_FriendsGet:ownerID
                                                                                  order:order
                                                                                 fields:fields
                                                                                  count:count
                                                                                 offset:offset];
    // NetworkOpeation
    DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_FriendsGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<Friend*>* friends = [Mapper friendsFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:friends error:error block:completion]){
            return;
        }
        
        // Prepare data for calling completion block
        op.result = friends;
        
        // Call completion
        if (completion) completion(friends,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns an array of posts from a user or community wall
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallGet:(nullable NSString*)ownerID
          offset:(NSInteger)offset
           count:(NSInteger)count
          filter:(nullable NSString*)filter
      completion:(nullable void(^)(NSArray<WallPost*>* _Nullable wallPosts, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_WallGet:ownerID offset:offset count:count filter:filter];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager  checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_WallGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<WallPost*>* wallPosts = [Mapper wallPostsFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:wallPosts error:error block:completion]){
            return;
        }
        
        // Prepare data for calling completion block
        op.result = wallPosts;
        
        // Call completion
        if (completion) completion(wallPosts,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Allows you to create a post on the wall. The method takes an array of attachments and unloads them one at a time.
 Below is the '+(DTO*)wallPost:...' method, it works in a different way. In its 'attachments' parameter you
 must provide links to previously uploaded materials.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
   attachmentsArr:(nullable NSArray<NSData*>*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nonnull postID, BO* op))completion
{
    NSInteger ownerIDintger = [ownerID integerValue];
    
    // We initialize a batch operation to upload attached photos to the server
    GO* groupOp = [GO groupOperation:^(GO * _Nonnull op){
        
        //Upload a photo (if there is data in the attachments array)
        NSMutableString* stringAttachments = [NSMutableString new];
        if (attachments.count > 0)
        {
            // Uploading each photo is a complex, complex process of several network operations.
            // Therefore, group operations are also used for this.
            // Despite the possibility of uploading up to 6 photos at the same time, we upload each photo separately.
            for (NSData* imageData in attachments) {
                [[APIManager uploadImages:@[imageData]
                                   userID:(ownerIDintger > 0) ? ownerID : nil
                                  groupID:(ownerIDintger < 0) ? ownerID : nil
                               completion:^(NSArray<NSDictionary *> * _Nullable savedImages, GO *uploadGroupOp) {
                
                                   NSDictionary* saveWallJSON = uploadGroupOp.result;

                                   if ((uploadGroupOp.error) || (!saveWallJSON)) {
                                       return;
                                   }
                                   
                                   NSArray<NSDictionary*>* responses = saveWallJSON[@"response"];
                                   
                                   //We go through the loop and add to the 'uri' of each uploaded photo
                                   // 'owner_id' - this is the owner id
                                   // 'id' -this is the number of the photo itself.
                                   // Subsequently, we will pass the 'string Attachments' string to the 'wallPost' method,
                                   // To have these addresses of these photos attached to the post
                                   for (NSDictionary* response in uploadGroupOp.result[@"response"]) {
                                       
                                       NSInteger ownerId = [response[@"owner_id"] integerValue];
                                       NSInteger photoId = [response[@"id"]       integerValue];
                                       
                                       [stringAttachments appendFormat:@"photo%@_%@",@(ownerId),@(photoId)];
                                       if (![[responses lastObject] isEqual:response]){
                                             [stringAttachments appendString:@","];
                                       }
                                   }
                }] start];
            }
        }
        
        // Calling the post upload method
        [[API wallPost:ownerID message:message attachments:stringAttachments fromGroup:fromGroup completion:^(NSNumber* postID, BO *op) {
            if (completion) completion(postID,op);
        }] syncStart];
    }];
    return groupOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Allows you to create a post on the wall. The method accepts the attachments string, which must be separated by commas.
 address ALREADY PREVIOUSLY uploaded photos.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
      attachments:(nullable NSString*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nullable postID, BO* op))completion
{
    if (!ownerID) ownerID = APIManager.token.userID;
    
    // NetworkRequestConstructor
    NSDictionary* requestParams = @{ @"owner_id" : ownerID,
                                     @"message"  : message,
                                     @"attachments" : attachments,
                                     @"from_group"  : @(fromGroup)
                                     };
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_WallPost:requestParams];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager  checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_WallPost];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
    
        // Parser
        NSNumber* postID = [Parser postIDInWallPostMethod:op.json error:&error];

        // Call completion
        if (completion) completion(postID,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 The method uploads an array of images to the server.
 Limitations: no more than 6 photos at a time in the method.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) uploadImages:(NSArray<NSData*>*)imagesData
              userID:(nullable NSString*)userID
             groupID:(nullable NSString*)groupID
          completion:(nullable void(^)(NSArray<NSDictionary*>* _Nullable savedImages, GO* op))completion
{
     __block RXNO_GroupOperation* group =
    [RXNO_GroupOperation groupOperation:^(GO * _Nonnull groupOp){
       
        NSString* prgrsDesc = nil; // Variable to shorten the syntax
        BO*       netOp     = nil; // Variable to shorten the syntax
        
        //-------------------------------------------photos.getWallUploadServer---------------------------------------------------------------//
        // NetworkOpeation
        __block DTO* getWallUploadServerOp =
        [APIManager photosGetWallUploadServerForUserID:userID groupID:groupID completion:^(NSString * _Nonnull uploadURL, BO *op) {
            getWallUploadServerOp = (DTO*)op;
        }];
        [getWallUploadServerOp syncStart];
        netOp = getWallUploadServerOp;  // Assign a new value in order to use this link with a short name to shorten the syntax

        
        // Handle Error & Call progress blocks
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:getWallUploadServerOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The first stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(1) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            // Call ProgressDescriptions - gives the user a description of the completed task/stage
            prgrsDesc = str(@"+[uploadImages] The first stage was completed successfully op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(1) totalCount:@(3) inGO:groupOp];
        }


        //-------------------------------------------uploadURL---------------------------------------------------------------//
        // Prepare images to uploading
        NSString* uploadURL = getWallUploadServerOp.result;
        
        // NetworkOpeation
        __block UO* uploadImageOp =
        [APIManager uploadImages:imagesData toURL:uploadURL progress:nil completion:^(NSDictionary * _Nullable response, BO *op) {
            uploadImageOp = (UO*)op;
        }];
        [uploadImageOp syncStart];
        netOp = uploadImageOp;  // Assign a new value in order to use this link with a short name to shorten the syntax

        // Handle Error & Call progress blocks
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:uploadImageOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The second stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(2) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            // Call ProgressDescriptions - gives the user a description of the completed task/stage
            prgrsDesc = str(@"+[uploadImages] The second stage was completed successfully. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(2) totalCount:@(3) inGO:groupOp];
        }

        //-------------------------------------------photos.saveWallPhoto---------------------------------------------------------------//
        // NetworkOpeation
        __block DTO* saveWallPhotoOp =
        [APIManager saveWallPhotoForUserID:userID groupID:groupID uploadServerResponse:uploadImageOp.json completion:^(NSDictionary * _Nullable response, BO *op) {
            saveWallPhotoOp = (DTO*)op;
        }];
        [saveWallPhotoOp syncStart];
        netOp = saveWallPhotoOp; // Assign a new value in order to use this link with a short name to shorten the syntax

        // Handle Error
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:saveWallPhotoOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The thrid stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(3) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            prgrsDesc = str(@"+[uploadImages] The thrid stage was completed successfully. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(3) totalCount:@(3) inGO:groupOp];
        }
    
        // Prepare data for calling completion block
        groupOp.result = saveWallPhotoOp.json;
        NSArray<NSDictionary*>* responses = saveWallPhotoOp.json[@"response"];
        if (completion) completion(responses,groupOp);
    }];
    return group;
}


/*--------------------------------------------------------------------------------------------------------------
 Makes a request to the server. Clears cookies in 'WKWebsiteDataStore'.
 Resets the 'APIManager.token' value and removes the token from the 'KeyChain'.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) logout:(nullable void(^)(void)) completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_logout];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        MainQueue(^{
            // Clear cookies
            WKWebsiteDataStore *dateStore = [WKWebsiteDataStore defaultDataStore];
            [dateStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
                
                for (WKWebsiteDataRecord *record  in records)
                {
                    if ([record.displayName containsString:@"vk.com"]) {
                        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{}];
                    }
                }
            }];
        });
        
        APIManager.token = nil;
        [APIManager removeTokenInKeychain];
        if (completion) completion();
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


#pragma mark - Internal Network Operations

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
  __  .__   __. .___________. _______ .______      .__   __.      ___       __
 |  | |  \ |  | |           ||   ____||   _  \     |  \ |  |     /   \     |  |
 |  | |   \|  | `---|  |----`|  |__   |  |_)  |    |   \|  |    /  ^  \    |  |
 |  | |  . `  |     |  |     |   __|  |      /     |  . `  |   /  /_\  \   |  |
 |  | |  |\   |     |  |     |  |____ |  |\  \----.|  |\   |  /  _____  \  |  `----.
 |__| |__| \__|     |__|     |_______|| _| `._____||__| \__| /__/     \__\ |_______|
 
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
 Below will be presented hidden methods that are available only for internal use of APIManager.
 These methods will be used as components for group operations.
 For example, a method that uploads a photo to the server at the specified URL.
 
 The APIManager policy is that the end user should get the data he needs by calling only one method.
 In the case of receiving "simple" data, for example a list of friends, this can be done using ordinary network operations.
 But if to perform a certain logical action (for example, uploading a photo), sequential execution is required
 several operations, then for such purposes we create a 'GroupOperation', which in itself carries out a sequential
 execution of small operations.
 The methods for these small operations will be listed below.
 --------------------------------------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------------------------------------
 [Internal method] Requests the server address for uploading photos to it
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosGetWallUploadServerForUserID:(nullable NSString*)userID
                                    groupID:(nullable NSString*)groupID
                                 completion:(nullable void(^)(NSString* _Nonnull uploadURL, BO* op))completion
{
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_PhotosGetWallUploadServer:userID groupID:groupID];
    DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_PhotosGetWallUploadServer];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        // Parsing & Mapping
        NSString* uploadURL = nil;
        if (op.json[@"response"]){
            uploadURL = op.json[@"response"][@"upload_url"];
        }
        
        // Prepare data for calling completion
        op.result = uploadURL;
        // Call completion
        if (completion) completion(uploadURL,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
  [Internal method] Uploads an array of photos to the address specified in 'uploadURL'
 --------------------------------------------------------------------------------------------------------------*/
+ (UO*) uploadImages:(NSArray<NSData*>*)imagesData
               toURL:(NSString*)uploadURL
            progress:(nullable void(^)(UO* op, UOUpProgress p))progress
          completion:(nullable void(^)(NSDictionary* _Nullable response, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_UploadImages:imagesData uploadURL:uploadURL];
    
    // Prepare progress block in optimization-way
    void(^progressBlock)(UO* op, UOUpProgress p) = nil;
    if (progress) progressBlock =  progress;

    // Network Operation
    UO* netOp =
    [UO uploadByRequest:request progress:progressBlock completion:^(UO * _Nonnull op, NSError * _Nullable error) {
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        // Call completion
        if (completion) completion(op.json,op);
    }];
    
    netOp.privateSession = self.defaultSession;
    return netOp;
}

/*--------------------------------------------------------------------------------------------------------------
 [Internal method] Makes a request to the server to save previously uploaded photos
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) saveWallPhotoForUserID:(nullable NSString*)userID
                        groupID:(nullable NSString*)groupID
           uploadServerResponse:(NSDictionary*)uploadServerResponse
                     completion:(nullable void(^)(NSDictionary* _Nullable response, BO* op))completion
{
    NSDictionary* upResponse = uploadServerResponse;
    if ((!upResponse[@"photo"]) || (!upResponse[@"server"]) || (!upResponse[@"hash"])){
        return nil;
    }
    
    NSString* photo  =  upResponse[@"photo"];
    NSInteger server = [upResponse[@"server"] integerValue];
    NSString* hash   =  upResponse[@"hash"];
    
    // NetworkRequestConstructor
    NSURLRequest* saveWallPhotoRequest =
    [NetworkRequestConstructor buildRequestForMethod_PhotosSaveWallPhoto:userID groupID:groupID photo:photo server:server hash:hash];
    
    // Network Operation
     DTO* netOp =
    [DTO request:saveWallPhotoRequest uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        // Call completion
        if (completion) completion(op.json,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}

#pragma mark - Logic

///////////////////////////////////////////////////////////////////////////////
/*
  __        ______     _______  __    ______
 |  |      /  __  \   /  _____||  |  /      |
 |  |     |  |  |  | |  |  __  |  | |  ,----'
 |  |     |  |  |  | |  | |_ | |  | |  |
 |  `----.|  `--'  | |  |__| | |  | |  `----.
 |_______| \______/   \______| |__|  \______|
 */
///////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 The method is called from the completion blocks of network operations (initialized inside the APIManager methods).
 From the accepted argument 'op' - the algorithm detects errors that occurred during the operation.
 If a block is passed to the 'completion' argument, the algorithm, if an error is detected, will independently call
 completionBlock of the APIManager method (This allows you to significantly reduce the syntax).
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) checkOnServerAndOtherError:(BO*)op apiMethodCompletion:(nullable void(^)(id value, BO* op))completion
{
    // We handle the case when the request reached the server, but it was compiled unsuccessfully and returned with an error
    if (op.json[@"error"])
    {
        NSString* domain = [NSString stringWithFormat:@"Error code %@",op.json[@"error"][@"error_msg"]];
        op.error = [NSError errorWithDomain:domain code:0 userInfo:op.json[@"error"]];
        
        // User authorization failed.
        if ([op.json[@"error"][@"error_code"] integerValue] == 5){
            
            // ⚠️ We prohibit unblocking the thread if the operation completed with a 401 code
            // You need to update the token, perform the operation, and then allow the semaphore to be released
            
            if (op.isSync) { op.isMayUnlockSemaphore = NO; }
            [BO postponeOperation:op];
            
            // We start the process of authentication or obtaining a fresh token
            [APIManager authenticationProcess:^(NSError * _Nullable error) {
                
                if (error) {
                    // We immediately call the completion of the operation that first failed.
                    // So that she has the exclusive right to forward the signal to the view, and the view can display the only 'UIAlertView'.
                    if (completion) completion(nil,op);
                    
                    for (BO* postponedOp in RXNO_BaseOperation.postponedOperations)
                    {
                        // Call 'completion' blocks for all other pending network operations
                        if ((![postponedOp isEqual:op]) && (postponedOp.completion)){
                            postponedOp.completion(postponedOp, error);
                        }
                    }
                }
            }];
            return op.error;
        }
    } else if (op.error.code == -1009){
        op.error = [NSError initWithMsg:@"No Internet connection" code:-1009];
    }
    
    // Handling Other Errors ...
    if ((completion) && (op.error)) completion(nil,op);
    
    return op.error;
}


/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
 The method calls 'completionBlock' if the 'error' object inside the network operation is not 'nil'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) callCompletionIfOccuredErrorInOp:(BO*)op result:(nullable id)result error:(nullable NSError*)error block:(nullable void(^)(id value, BO* op))completion
{
    op.error = (op.error) ? op.error : error;
    
    if (result) op.result = result;
    
    BOOL isOccuredError = (op.error) ? YES : NO;
    
    if ((op.error) && (completion)){
        completion(result,op);
    }
    return isOccuredError;
}

/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
  The method calls 'completionBlock' if the 'error' object inside the groupOp is not 'nil'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) callCompletionIfOccuredErrorInGO:(GO*)op result:(nullable id)result error:(nullable NSError*)error block:(nullable void(^)(id value, GO* op))completion
{
    op.error = (op.error) ? op.error : error;
    
    if (result) op.result = result;
    
    BOOL isOccuredError = (op.error) ? YES : NO;
    
    if ((op.error) && (completion)){
        completion(result,op);
    }
    return isOccuredError;
}

/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
 Calls 'progressDescription' and 'progressCount' on the groupOp if these blocks have been initialized.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) callProgressDescription:(nullable NSString*)msg
                  doneOperations:(nullable NSNumber*)doneOperation
                      totalCount:(nullable NSNumber*)count
                            inGO:(GO*)groupOp
{
    if (!groupOp) return;
    if ((msg) && (groupOp.progressDescription)) groupOp.progressDescription(msg);
    
    if ((doneOperation) && (count)){
        if (groupOp.progressCount) groupOp.progressCount((int)[doneOperation integerValue],(int)[count integerValue]);
    }
}

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
+ (void) receiveTokenFromWebViewAuth:(nullable Token*)token error:(nullable NSError*)error
{
    // ⚠️ Remember, if the token was not received for any reason, then synchronous operations are
    // able to indefinitely hold the thread from which they were called.
    // To avoid 'deadlocks' handle cases of unsuccessful receipt of a new token.
    // In this case, call the '-unlockSemaphore' methods on synchronous operations
    if (error){
        for (BO* op in RXNO_BaseOperation.postponedOperations) {
             op.isMayUnlockSemaphore = YES;
            
            NSMutableDictionary* userInfoError =  @{ @"message" : @"Token was received with error" }.mutableCopy;
            if (error.userInfo){
                userInfoError[@"error"] = error.userInfo;
            }
            op.json = userInfoError;
        }
        // Unblocking previously frozen threads
        [BO unlockSemaphoreForAllPostponned];

        // We call the 'completion' of the 'authenticationProcess' method so that the entity that
        // called it can call the 'completion' blocks of network operations, so that they, in turn,
        // send a message about the error down the chain -> viewModel -> view.
        if (APIManager.authenticationCompletion) APIManager.authenticationCompletion(error);

        // Remove all postponned operations.
        [BO removeAllPostponedOperations];
        APIManager.isOpenAuthenticationProcess = NO;
        return;
    }
    // Below is the case of successful receipt of a fresh token.
    // Write to keychain and write to RAM
    [APIManager saveTokenInKeychain:token];
    [APIManager updateToken:token.access_token expiresAfter:token.expiresAfter userID:token.userID];
    
    // Call the method for executing postponed operations.
    // We insert a fresh token into the parameters of each operation that was completed with an error.
    [BO performPostponedOperationsOnQueue:APIManager.aSyncQueue
                     updateOperationBlock:^NSArray<BO*>* (NSArray<BO*>* rawOperations) {
                         
                         for (int i=0; i<=rawOperations.count-1; i++)
                         {
                             BO* op = rawOperations[i];
                             modifyOperation block = RXNO_BaseOperation.modificationBlocksForPostponedOperations[op.uniqueHash];
                             
                             if (block){
                                 op =  block(op);
                             }else {
                                 op.parameters[@"access_token"] = APIManager.token.access_token;
                             }
                         }
                         return rawOperations;
                     }];
    
    APIManager.isOpenAuthenticationProcess = NO;
    if (APIManager.authenticationCompletion) APIManager.authenticationCompletion(error);
}


/*--------------------------------------------------------------------------------------------------------------
 Using 'Router', it shows 'AuthViewController' and starts the authentication process
 --------------------------------------------------------------------------------------------------------------*/
+ (void) authenticationProcess:(nullable AuthenticationCompletion)completion
{
    // ⚠️ Remember, if the token was not received for any reason, then synchronous operations are
    // able to indefinitely hold the thread from which they were called.
    // To avoid 'deadlocks' handle cases of unsuccessful receipt of a new token.
    // In this case, call the '-unlockSemaphore' methods on synchronous operations
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (self.isOpenAuthenticationProcess){
            return;
        } else {
            self.isOpenAuthenticationProcess = YES;
        }
        [Router showOAuthControllerWithDelegate:(id<Auth2_0_Delegate>)[APIManager class] showType:PresentController_ShowType];
        APIManager.authenticationCompletion = completion;
    }
}



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


/*--------------------------------------------------------------------------------------------------------------
 Returns 'YES' if the token is written to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) isThereTokenInKeychain
{
    if ([KFKeychain loadObjectForKey:vkAccessToken class:[Token class]]){
        return YES;
    }
    return NO;
}

/*--------------------------------------------------------------------------------------------------------------
   Restores from 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable Token*) restoreTokenFromKeychain
{
    Token* token = [KFKeychain loadObjectForKey:vkAccessToken class:[Token class]];
    return token;
}

/*--------------------------------------------------------------------------------------------------------------
  Deletes from 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) removeTokenInKeychain {
    [KFKeychain deleteObjectForKey:vkAccessToken];
}


/*--------------------------------------------------------------------------------------------------------------
 Saves in 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) saveTokenInKeychain:(Token*)token
{
    BOOL isSaved = [KFKeychain saveObject:token forKey:vkAccessToken];
    if (!isSaved){
        return [NSError errorWithDomain:@"Token не был сохранен в keyChain" code:0 userInfo:nil];
    }
    return nil;
}

/*--------------------------------------------------------------------------------------------------------------
 Updates the values for '@property token' and writes a new instance to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) updateToken:(NSString*)accessToken expiresAfter:(NSString*)expiresAfter userID:(NSString*)userID
{
    Token* token = [APIManager token];
    if (!token){
        token = [Token initWithAccessToken:accessToken expiresAfter:expiresAfter userID:userID];
    } else {
        token.access_token = accessToken;
        token.expiresAfter = expiresAfter;
        token.userID       = userID;
    }
    [APIManager saveTokenInKeychain:token];
}


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
 completed with an error.
 The method calls the given 'completion' block if the operation contains 'error'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletion:(nullable void(^)(NSError* _Nullable error))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error);
    }
    return op.error;
}

/*--------------------------------------------------------------------------------------------------------------
  The method was created to shorten the syntax.
  Called inside the 'completion' method blocks of the APIManager class.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithTwoArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error,nil);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error,nil);
    }
    return op.error;
}

/*--------------------------------------------------------------------------------------------------------------
 The method was created to shorten the syntax.
 Called inside the 'completion' method blocks of the APIManager class.
 (!) The difference from the methods below is the presence of three arguments in the block.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithThreeArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1, id _Nullable arg2))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error,nil,nil);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error,nil,nil);
    }
    return op.error;
}


#pragma mark - Setters & Getters

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______. _______ .___________.___________. _______ .______          _______.
     /       ||   ____||           |           ||   ____||   _  \        /       |
    |   (----`|  |__   `---|  |----`---|  |----`|  |__   |  |_)  |      |   (----`
     \   \    |   __|      |  |        |  |     |   __|  |      /        \   \
 .----)   |   |  |____     |  |        |  |     |  |____ |  |\  \----.----)   |
 |_______/    |_______|    |__|        |__|     |_______|| _| `._____|_______/
 
   _______  _______ .___________.___________. _______ .______          _______.
  /  _____||   ____||           |           ||   ____||   _  \        /       |
 |  |  __  |  |__   `---|  |----`---|  |----`|  |__   |  |_)  |      |   (----`
 |  | |_ | |   __|      |  |        |  |     |   __|  |      /        \   \
 |  |__| | |  |____     |  |        |  |     |  |____ |  |\  \----.----)   |
  \______| |_______|    |__|        |__|     |_______|| _| `._____|_______/
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readwrite, strong) NSURLSession* defaultSession;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setDefaultSession:(NSURLSession *)defaultSession
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _defaultSession = defaultSession;
    }
}

+ (NSURLSession *) defaultSession
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_defaultSession){
            NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.timeoutIntervalForRequest  = 5;
            configuration.timeoutIntervalForResource = 120;
            configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
            configuration.URLCredentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
            configuration.requestCachePolicy   = NSURLRequestReloadIgnoringLocalCacheData;
            configuration.discretionary        = YES;
            
            if (@available(macOS 10.13.1, iOS 11, *)) {
                // Be sure to set the value to 'NO', then the operation will complete with an error if the number
                // of seconds of waiting exceeds the value of the property 'timeoutIntervalForRequest'.
                // Otherwise, it will wait until the value from 'timeoutIntervalForResource' is exceeded.
                configuration.waitsForConnectivity = NO;
            }
            _defaultSession = [NSURLSession sessionWithConfiguration:configuration
                                                            delegate:RXNO_BaseOperation.internal_delegate
                                                       delegateQueue:nil];
            _defaultSession.sessionDescription = @"APIManager.defaultSession";
        }
        return _defaultSession;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, copy)  AuthenticationCompletion authenticationCompletion;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setAuthenticationCompletion:(AuthenticationCompletion)authenticationCompletion
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _authenticationCompletion = authenticationCompletion;
    }
}

+ (AuthenticationCompletion)authenticationCompletion
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        return _authenticationCompletion;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, assign) BOOL isOpenAuthenticationProcess;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setIsOpenAuthenticationProcess:(BOOL)isOpenAuthenticationProcess
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _isOpenAuthenticationProcess = isOpenAuthenticationProcess;
    }
}

+ (BOOL)isOpenAuthenticationProcess
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        return _isOpenAuthenticationProcess;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readonly, strong) NSOperationQueue* aSyncQueue;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setASyncQueue:(NSOperationQueue *)aSyncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _aSyncQueue = aSyncQueue;
    }
}

+ (NSOperationQueue *)aSyncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_aSyncQueue){
             _aSyncQueue = [[NSOperationQueue alloc] init];
             _aSyncQueue.maxConcurrentOperationCount = 5;
        }
        return _aSyncQueue;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readwrite, strong) NSOperationQueue* syncQueue;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setSyncQueue:(NSOperationQueue *)syncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _syncQueue = syncQueue;
    }
}

+ (NSOperationQueue *)syncQueue{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_syncQueue){
             _syncQueue = [[NSOperationQueue alloc] init];
             _syncQueue.maxConcurrentOperationCount = 1;
        }
        return _syncQueue;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, strong, nullable) Token* token;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setToken:(Token *)token
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _token = token;
    }
}

+ (Token* _Nullable)token
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_token){
             _token = [APIManager restoreTokenFromKeychain];
        }
        return _token;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, strong) NSString* baseURL;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setBaseURL:(NSString *)baseURL
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _baseURL = baseURL;
    }
}

+ (NSString *)baseURL
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        
        if (!_baseURL){
             _baseURL = @"https://api.vk.com/method/";
        }
        return _baseURL;
    }
}

@end
