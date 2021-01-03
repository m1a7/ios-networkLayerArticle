//
//  NetworkRequestConstructor.m
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "NetworkRequestConstructor.h"

// APIManager's Categories
#import "APIManager+Utilites.h"

// Models
#import "Token.h"

// Foundation Categories
#import "NSDictionary+Merge.h"

// Third-party frameworks
#import <RXNetworkOperation/RXNetworkOperation.h>


/*--------------------------------------------------------------------------------------------------------------
 🏗 'NetworkRequestConstructor' (aka NRC) - constructs requests ('NSURLRequest') for the API.
 ---------------
 The main task of the class is to decompose the network layer, taking on the responsibility in a user-friendly way
 a way to configure network API requests.
 ---------------
 [⚖️] Duties:
 - Configure network API requests.
 ---------------
 The class provides the following features:
 - you can get the request you want using the general method + buildRequestForMethod: properties :.
 - you can get the request you need using an individual method for each API method.
 ---------------
 Additionally:
 (⚠️) For some method APIs, the class provides several kinds of constructor methods.
 The first type takes several raw arguments (int / nsstring / float / etc.) and forms the request itself.
 The second type takes a ready-made dictionary with parameters, and, if necessary, independently adds the necessary values.
 --------------------------------------------------------------------------------------------------------------*/


@implementation NetworkRequestConstructor

#pragma mark - Shared method

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______. __    __       ___      .______       _______  _______
     /       ||  |  |  |     /   \     |   _  \     |   ____||       \
    |   (----`|  |__|  |    /  ^  \    |  |_)  |    |  |__   |  .--.  |
     \   \    |   __   |   /  /_\  \   |      /     |   __|  |  |  |  |
 .----)   |   |  |  |  |  /  _____  \  |  |\  \----.|  |____ |  '--'  |
 |_______/    |__|  |__| /__/     \__\ | _| `._____||_______||_______/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 🥇 The main method for interacting with the query designer.
 --------------------------------------------------------------------------------------------------------------*/

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod:(APIMethod)method
                                              properties:(nullable NSDictionary<NSString*,id>*)properties
{
    NSMutableURLRequest* request;
    switch (method) {
        case APIMethod_Unknow:     request = nil;                                                break;
        case APIMethod_UserGet:    request = [NRC buildRequestForMethod_UsersGet:properties];    break;
        case APIMethod_FriendsGet: request = [NRC buildRequestForMethod_FriendsGet:properties];  break;

            
        case APIMethod_WallGet:  request = [NRC buildRequestForMethod_WallGet:properties];  break;
        case APIMethod_WallPost: request = [NRC buildRequestForMethod_WallPost:properties]; break;

        case APIMethod_PhotosGetAll:              request = [NRC buildRequestForMethod_PhotosGetAll:properties];                break;
        case APIMethod_PhotosGetWallUploadServer: request = [NRC buildRequestForMethod_PhotosGetWallUploadServer:properties];   break;
      
        case APIMethod_Logout: request = [NRC buildRequestForMethod_logout]; break;
        
        default: APILog(@"+buildRequestForMethod:properties:| Switch not found mathes!"); break;
    }
    return request;
}





#pragma mark - Individual methods

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
  __  .__   __.  _______   __  ____    ____  __   _______   __    __       ___       __
 |  | |  \ |  | |       \ |  | \   \  /   / |  | |       \ |  |  |  |     /   \     |  |
 |  | |   \|  | |  .--.  ||  |  \   \/   /  |  | |  .--.  ||  |  |  |    /  ^  \    |  |
 |  | |  . `  | |  |  |  ||  |   \      /   |  | |  |  |  ||  |  |  |   /  /_\  \   |  |
 |  | |  |\   | |  '--'  ||  |    \    /    |  | |  '--'  ||  `--'  |  /  _____  \  |  `----.
 |__| |__| \__| |_______/ |__|     \__/     |__| |_______/  \______/  /__/     \__\ |_______|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark - APIMethod - user.get

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Returns extended information about users.
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - user_ids  : [155510513]
 - fields    : [photo_50,photo_100,online,last_seen,music]
 - name_case : Nom
 -------
 📖 More details: https://vk.com/dev/users.get
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_UsersGet:(nullable NSArray<NSString*>*)userIds
                                                           fields:(nullable NSArray<NSString*>*)fields
                                                         nameCase:(nullable NSString*)nameCase
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"user_ids"]  = (userIds.count   > 0) ? userIds  : @[APIManager.token.userID];
    properties[@"fields"]    = (fields.count    > 0) ? fields   : @[@"photo_50",@"photo_100",@"photo_200",@"online",@"last_seen",@"counters",@"city",@"country",@"home_town"];
    properties[@"name_case"] = (nameCase.length > 0) ? nameCase : @"Nom";

    return [NRC buildRequestForMethod_UsersGet:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_UsersGet:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_ids"]     =  @[];
    params[@"fields"]       =  @[@"photo_50",@"photo_100",@"photo_200",@"photo_max_orig",@"online",@"last_seen",@"counters"];
    params[@"name_case"]    =  @"Nom";
    params[@"v"]            =  @"5.122";
    params[@"access_token"] =  APIManager.token.access_token;

    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
         params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:usersGet] HTTPMethod:GET params:params headers:nil];
    
    return request;
}


#pragma mark - APIMethod - wall.get

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Returns records from the wall.
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - owner_id  : 155510513
 - offset    : 0
 - count     : 10
 - filter    : all
 -------
 📖 More details: https://vk.com/dev/wall.get
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSString*)ownerID
                                                          offset:(NSInteger)offset
                                                           count:(NSInteger)count
                                                          filter:(nullable NSString*)filter
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"owner_id"] = (ownerID.length  > 0) ? ownerID  : APIManager.token.userID;
    properties[@"offset"]   = [NSString stringWithFormat:@"%d",(int)offset];
    properties[@"count"]    = (count > 0) ? [NSString stringWithFormat:@"%d",(int)count] : @"1";
    properties[@"filter"]   = (filter.length > 0) ? filter : @"all";
    
    return [NRC buildRequestForMethod_WallGet:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"] = APIManager.token.userID;
    params[@"offset"]   = @"0";
    params[@"count"]    = @"1";
    params[@"filter"]   = @"all";
    params[@"extended"]     = @(YES);
    params[@"v"]            =  @"5.122";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:wallGet] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - wall.post

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Allows you to create a post on the wall, suggest a post on the wall of a public page, post an existing deferred post.
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - owner_id     : 155510513
 - friends_only : 1/0
 - from_group   : 1/0
 - message      : ""
 - attachments  : ""
 - services : "twitter"/"facebook"
 - signed   : 1/0
 - guid     : ""
 - mark_as_ads    : 1/0
 - close_comments : 1/0
 -------
 📖 More details: https://vk.com/dev/wall.post
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSString*)ownerID
                                                          message:(nullable NSString*)message
                                                      attachments:(nullable NSString*)attachments
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"owner_id"]    = (ownerID.length  > 0) ? ownerID : APIManager.token.userID;
    properties[@"message"]     = (message.length > 0)  ? message : @"";
    properties[@"attachments"] = (attachments.length > 0) ? attachments : @"";
    
    return [NRC buildRequestForMethod_WallPost:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSDictionary<NSString*,id>*)properties
{
    // One of these two must be present
    if ((!properties[@"message"]) && (!properties[@"attachments"])){
        return nil;
    }
    
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"]     = APIManager.token.userID;
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:wallPost] HTTPMethod:GET params:params headers:nil];
    return request;
}

#pragma mark - APIMethod -  photos.getWallUploadServer

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Returns the server address for uploading a photo to a user or community wall.
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - user_id  : 155510513 // If on the user's wall
 - group_id : 0         // If on the wall of the group
 -------
 📖 More details: https://vk.com/dev/photos.getWallUploadServer
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSString*)userID
                                                                           groupID:(nullable NSString*)groupID
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    if (userID.length  > 0)  properties[@"user_id"] = userID;
    if (groupID.length > 0) properties[@"groupID"] = userID;
    return [NRC buildRequestForMethod_PhotosGetWallUploadServer:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_id"]      = APIManager.token.userID;
    params[@"v"]            =  @"5.126";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosGetWallUploadServer] HTTPMethod:GET params:params headers:nil];
    return request;
}



#pragma mark - APIMethod - photos.getAll

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Returns all photos of a user or community in anti-chronological order.
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - owner_id : 155510513
 - offset   :
 - count    :
 - photo_sizes : bool
 - skip_hidden : bool
 - v           : 5.21
 -------
 📖 More details: https://vk.com/dev/photos.getAll
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSString*)ownerID
                                                               offset:(NSInteger)offset
                                                                count:(NSInteger)count
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"owner_id"] = (ownerID.length  > 0) ? ownerID  : APIManager.token.userID;
    properties[@"offset"]   = [NSString stringWithFormat:@"%d",(int)offset];
    properties[@"count"]    = (count > 0) ? [NSString stringWithFormat:@"%d",(int)count] : @"1";
   
    return [NRC buildRequestForMethod_PhotosGetAll:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"] = APIManager.token.userID;
    params[@"offset"]   = @"0";
    params[@"count"]    = @"1";
    
    params[@"photo_sizes"]  = @(NO);
    params[@"skip_hidden"]  = @(YES);
    
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosGetAll] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - photos.saveWallPhoto

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Saves photos after successful upload to the URI obtained by the method
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - user_id  : 155510513 // If on the user's wall
 - group_id : 0         // If on the wall of the group
 - photo    : ""
 - server   : 17
 - hash     : ""
 - latitude  : (from -90 to 90)
 - longitude : (from -180 to 180)
 - caption   : "tekst"
 -------
 📖 More details: https://vk.com/dev/photos.saveWallPhoto
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSString*)userID
                                                                     groupID:(nullable NSString*)groupID
                                                                       photo:(NSString*)photo
                                                                      server:(NSInteger)server
                                                                        hash:(NSString*)hash
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    if (userID.length  > 0) properties[@"user_id"]  = userID;
    if (groupID.length > 0) properties[@"group_id"] = groupID;

    if (photo.length > 0) properties[@"photo"] = photo;
    if (hash.length  > 0) properties[@"hash"]  = hash;
    if (server) properties[@"server"] = @(server);
    
    return [NRC buildRequestForMethod_PhotosSaveWallPhoto:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    
    if (!properties[@"user_id"] && !properties[@"group_id"]){
         params[@"user_id"] = APIManager.token.userID;
    }
    params[@"v"]            =  @"5.126";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Build request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosSaveWallPhoto] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - friends.get

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Returns a list of user friend ids or extended information about user friends
 -------
 📥 Forms a request from the received dictionary with parameters:
 
 - owner_id : 155510513
 - offset   :
 - count    :
 - order    : hints/mobile/name/random
 - fields   : nickname, domain, sex, bdate, city, country, timezone,
              photo_50, photo_100, photo_200_orig, has_mobile, contacts,
              education, online, relation, last_seen, status, can_write_private_message,
              can_see_all_posts, can_post, universities
 - name_case : nom/gen/dat/acc/ins/abl.
 - v         : 5.21
 -------
 📖 More details: https://vk.com/dev/friends.get
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_FriendsGet:(nullable NSString*)ownerID
                                                              order:(nullable NSString*)order
                                                             fields:(NSArray<NSString*>* _Nullable)fields
                                                              count:(NSInteger)count
                                                             offset:(NSInteger)offset
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"user_id"] = (ownerID.length  > 0) ? ownerID  : APIManager.token.userID;
    properties[@"offset"]  = [NSString stringWithFormat:@"%d",(int)offset];
    properties[@"count"]   = (count > 0) ? [NSString stringWithFormat:@"%d",(int)count] : @"1";
    return [NRC buildRequestForMethod_FriendsGet:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_FriendsGet:(nullable NSDictionary<NSString*,id>*)properties
{
    // Create a boilerplate initial parameter structure
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_id"] = APIManager.token.userID;
    params[@"offset"]  = @"0";
    params[@"count"]   = @"1";
    
    params[@"order"]   = @"hints";
    params[@"fields"]  = @[@"photo_50",@"photo_100"];
    
    params[@"name_case"]    =  @"nom";
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // We combine the dictionaries if there is anything at all in the 'properties' of the arguments.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // We form a request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:friendsGet] HTTPMethod:GET params:params headers:nil];
    return request;
}

#pragma mark - Another methods

/*--------------------------------------------------------------------------------------------------------------
 Accepts an 'uploadURL' and configures a 'POST' request to upload photos to the server.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_UploadImages:(NSArray<NSData*>*)imagesData
                                                            uploadURL:(NSString*)uploadURL
{
    if ((!uploadURL) || (imagesData.count < 1)) return nil;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:uploadURL]];
    [RXNO_BaseOperation addMultipartData:imagesData fileName:@"file" boundary:nil toRequest:request];
    [request setHTTPMethod:@"POST"];
    return request;
}


#pragma mark - APIMethod - oauth.logout

+ (NSMutableURLRequest*) buildRequestForMethod_logout
{
    NSURLComponents* urlComponents = [[NSURLComponents alloc] initWithString:@"https://oauth.vk.com/authorize"];    
    urlComponents.queryItems = @[[NSURLQueryItem queryItemWithName:@"access_token" value:APIManager.token.access_token],
                                 [NSURLQueryItem queryItemWithName:@"client_id" value:@"7531597"],
                                 [NSURLQueryItem queryItemWithName:@"revoke"    value:@"1"],
                                 [NSURLQueryItem queryItemWithName:@"v"         value:@"5.52"]];
    
    return [NSURLRequest requestWithURL:urlComponents.URL].mutableCopy;
}


@end
