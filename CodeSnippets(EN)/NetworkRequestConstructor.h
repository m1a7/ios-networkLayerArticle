//
//  NetworkRequestConstructor.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIConsts.h"
#import "APIMethods.h"

NS_ASSUME_NONNULL_BEGIN

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

@interface NetworkRequestConstructor : NSObject

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

+ (nullable NSMutableURLRequest*) buildRequestForMethod:(APIMethod)method
                                             properties:(nullable NSDictionary<NSString*,id>*)properties;



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

#pragma mark - APIMethod - users.get

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
+ (nullable NSMutableURLRequest*) buildRequestForMethod_UsersGet:(nullable NSDictionary<NSString*,id>*)properties;

+ (nullable NSMutableURLRequest*) buildRequestForMethod_UsersGet:(nullable NSArray<NSString*>*)userIds
                                                          fields:(nullable NSArray<NSString*>*)fields
                                                        nameCase:(nullable NSString*)nameCase;


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
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSString*)ownerID
                                                          offset:(NSInteger)offset
                                                           count:(NSInteger)count
                                                          filter:(nullable NSString*)filter;

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

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSString*)ownerID
                                                          message:(nullable NSString*)message
                                                      attachments:(nullable NSString*)attachments;


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

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSString*)userID
                                                                           groupID:(nullable NSString*)groupID;



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

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSString*)userID
                                                                     groupID:(nullable NSString*)groupID
                                                                       photo:(NSString*)photo
                                                                      server:(NSInteger)server
                                                                        hash:(NSString*)hash;



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
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSString*)ownerID
                                                               offset:(NSInteger)offset
                                                                count:(NSInteger)count;


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
                                                             offset:(NSInteger)offset;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_FriendsGet:(nullable NSDictionary<NSString*,id>*)properties;



#pragma mark - Another methods

/*--------------------------------------------------------------------------------------------------------------
 Accepts an 'uploadURL' and configures a 'POST' request to upload photos to the server.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_UploadImages:(NSArray<NSData*>*)imagesData
                                                            uploadURL:(NSString*)uploadURL;


#pragma mark - APIMethod - oauth.logout

+ (NSMutableURLRequest*) buildRequestForMethod_logout;


@end

NS_ASSUME_NONNULL_END
