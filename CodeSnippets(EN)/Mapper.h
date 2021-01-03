//
//  Mapper.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UserProfile;
@class WallPost;
@class Photo;
@class PhotoGalleryCollection;
@class Friend;

/*--------------------------------------------------------------------------------------------------------------
 📄 ➡️ 💾  'Mapper' - builds data models from json files.
 ---------------
  The main task of the class is to decompose the 'APIManager', taking out the code for parsing and mapping models from it.
 ---------------
 [⚖️] Duties:
 - Create data models from the received json.
 --------------------------------------------------------------------------------------------------------------*/

@interface Mapper : NSObject

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of objects containing detailed information about users.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<UserProfile*>*) usersGetFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of posts from a user's or community's wall.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<WallPost*>*) wallPostsFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<Photo*>*)  photosGetAllFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable PhotoGalleryCollection*) photosCollectionFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

/*--------------------------------------------------------------------------------------------------------------
 Returns a list of user friend ids or extended information about user friends
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<Friend*>*) friendsFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

@end

NS_ASSUME_NONNULL_END
