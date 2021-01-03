//
//  APIMethods.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#ifndef APIMethods_h
#define APIMethods_h

/*--------------------------------------------------------------------------------------------------------------
 (📄) File 'APIMethods.h' - contains enumerations of API methods that 'APIManager' supports
 --------------------------------------------------------------------------------------------------------------*/

#pragma mark - Enum API Part
/*--------------------------------------------------------------------------------------------------------------
 API enumerations of methods supported by 'APIManager'.
 Used for convenience in 'NetworkRequestConstructor' as arguments to query building functions.
 --------------------------------------------------------------------------------------------------------------*/
typedef NS_ENUM(NSInteger, APIMethod) {
    
    APIMethod_Unknow = 0,
    APIMethod_UserGet,
    APIMethod_FriendsGet,

    APIMethod_WallGet,
    APIMethod_WallPost,
    
    APIMethod_PhotosGetAll,
    APIMethod_PhotosGetWallUploadServer,
    APIMethod_PhotosSaveWallPhoto,
    
    APIMethod_Logout
};


#pragma mark - String Constants API Part
/*--------------------------------------------------------------------------------------------------------------
 String constants containing the name EndPoint and the name of the API methods.
 Used by the 'NetworkRequestConstructor' constructor when constructing the NSURLRequest.
 --------------------------------------------------------------------------------------------------------------*/
static NSString *const usersGet = @"users.get"; // Returns extended information about users.
static NSString *const wallGet  = @"wall.get";  // Returns entries from users' wall
static NSString *const wallPost = @"wall.post"; // Lets you create a post on the wall

static NSString *const photosGetAll  = @"photos.getAll"; // Returns all photos of a user or community in anti-chronological order.
static NSString *const friendsGet    = @"friends.get";   // Returns a list of user friend ids or extended information about user friends


static NSString *const photosGetWallUploadServer = @"photos.getWallUploadServer"; // Returns the server address for uploading a photo to a user or community wall.
static NSString *const photosSaveWallPhoto       = @"photos.saveWallPhoto";       // Saves photos after successful upload to the URI obtained by the method

static NSString *const logout = @"auth.logout";

#endif /* APIMethods_h */
