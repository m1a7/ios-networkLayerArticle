//
//  Mapper.m
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "Mapper.h"
// Frameworks
#import "FEMMapping.h"
#import "FEMDeserializer.h"

// Models
#import "WallPost.h"
#import "Photo.h"
#import "UserOwnerPost.h"
#import "GroupOwnerPost.h"
#import "UserCounter.h"
#import "UserProfile.h"
#import "PhotoGalleryCollection.h"
#import "Friend.h"

// Helpers Categories
#import "NSError+ShortStyle.h"


/*--------------------------------------------------------------------------------------------------------------
 📄 ➡️ 💾  'Mapper' - builds data models from json files.
 ---------------
 The main task of the class is to decompose the 'APIManager', taking out the code for parsing and mapping models from it.
 ---------------
 [⚖️] Duties:
 - Create data models from the received json.
 --------------------------------------------------------------------------------------------------------------*/
@implementation Mapper

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of objects containing detailed information about users.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<UserProfile*>*) usersGetFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+usersGetFromJSON: received empty json"]; return nil;}

    FEMMapping*           objectMapping = [UserProfile defaultMapping];
    NSArray<UserProfile*>* userProfiles = [FEMDeserializer collectionFromRepresentation:json[@"response"] mapping:objectMapping];
    
    return userProfiles;
}

/*--------------------------------------------------------------------------------------------------------------
 Returns an array of posts from a user's or community's wall.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<WallPost*>*) wallPostsFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+wallPostsFromJSON: received empty json"]; return nil;}

    FEMMapping*     objectMapping = [WallPost defaultMapping];
    NSArray<WallPost*>* wallPosts = [FEMDeserializer collectionFromRepresentation:json[@"items"] mapping:objectMapping];
    
    // Now we need to initialize the authors of the posts.
    NSArray* profiles = json[@"profiles"];
    NSArray* groups   = json[@"groups"];

    for (WallPost* post in wallPosts)
    {
        // The post was published on behalf of the user
        if (post.fromID > 0){
            NSDictionary* ownerDict        = [Mapper postOwnerByID:post.fromID inCollection:profiles];
            FEMMapping*   userOwnerMapping = [UserOwnerPost defaultMapping];
            UserOwnerPost* userOwnerPost = [FEMDeserializer objectFromRepresentation:ownerDict mapping:userOwnerMapping];
            post.owner = userOwnerPost;
        }
        // The post was published on behalf of the group
        else if (post.fromID < 0){
            NSDictionary* ownerDict = [Mapper postOwnerByID:post.fromID inCollection:groups];
            FEMMapping*   groupOwnerMapping = [GroupOwnerPost defaultMapping];
            GroupOwnerPost*  groupOwnerPost = [FEMDeserializer objectFromRepresentation:ownerDict mapping:groupOwnerMapping];
            post.owner = groupOwnerPost;
        }
    }
    
    return wallPosts;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<Photo*>*)  photosGetAllFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+photosGetAllFromJSON: received empty json"]; return nil;}

    FEMMapping*     objectMapping = [Photo photosGetAllMapping];
    NSArray<Photo*>*       photos = [FEMDeserializer collectionFromRepresentation:json[@"items"] mapping:objectMapping];
    
    return photos;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns all photos of a user or community in anti-chronological order.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable PhotoGalleryCollection*)  photosCollectionFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+photosCollectionFromJSON: received empty json"]; return nil;}
    
    FEMMapping*          objectMapping = [PhotoGalleryCollection defaultMapping];
    PhotoGalleryCollection* collection = [FEMDeserializer objectFromRepresentation:json mapping:objectMapping];
    
    return collection;
}



/*--------------------------------------------------------------------------------------------------------------
 Returns a list of user friend ids or extended information about user friends
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<Friend*>*) friendsFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+friendsFromJSON: received empty json"]; return nil;}
    
    FEMMapping*    objectMapping = [Friend defaultMapping];
    NSArray<Friend*>*    friends = [FEMDeserializer collectionFromRepresentation:json[@"items"] mapping:objectMapping];

    return friends;
}


#pragma mark - Helpers

/*--------------------------------------------------------------------------------------------------------------
  [Helper] Helps isolate the 'id' of the owner of the post on the wall.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) postOwnerByID:(NSInteger)fromID inCollection:(NSArray<NSDictionary*>*)collection
{
    // Either the 'profiles' or 'groups' array comes to 'collection'.
    // And this method must find a dictionary that contains the identical 'from_id'
    
    // Convert a negative number to a positive one.
    // Because in these arrays, regardless of whether the user or the group, all id will be positive
    if (fromID < 0) fromID *= -1;
    
    NSDictionary* neededDictionary = nil;
    
    for (NSDictionary* ownerPostDict in collection)
    {
        if ([ownerPostDict[@"id"] integerValue] == fromID){
            neededDictionary = ownerPostDict;
            break;
        }
    }
    return neededDictionary;
}

@end
