//
//  Parser.m
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "Parser.h"
// Helpers Categories
#import "NSError+ShortStyle.h"


/*--------------------------------------------------------------------------------------------------------------
 🗂 🔍 'Parser' - extracts data from a complex structure.
 ---------------
 Applicable only in special cases when you need to get deep data.
 ---------------
 [⚖️] Duties:
 - Contain the code of methods that retrieve data from complex structures, so as not to clutter up other entities with this code.
 ---------------
 [📇] Code style:
 1) The method name must start with the name of the element that you plan to retrieve. (Ex. 'LastSeenPlatform')
 2) The method name must be followed by the method API name (eg 'UserGet') and the 'Method' suffix.
 3) The argument name must be identical to the name of the parent container that is passed to the function.
 4) If the conditions force the creation of two similar methods that work with the same structure, then in order
 to avoid duplication of the name, it is allowed to add the 'From' suffix to the end of the method and the
 name of the nested structure from which the data will be extracted.
 Example: 'followers'+'InUserGet'+'Method'+'From'+'Counters'.
 --------------------------------------------------------------------------------------------------------------*/


@implementation Parser

#pragma mark - Parsing elements from API method 'user.get'
/*--------------------------------------------------------------------------------------------------------------
 Retrieves the code of the platform from which the user made their last session.
 Retrieves data from the server response to the 'UserGet' method execution.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) lastSeenPlatformInUserGetMethod:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+lastSeenPlatformInUserGetMethod: received empty json"]; return nil;}
    
    NSArray<NSDictionary*>* response = json[@"response"];
    if (!response) { *error = [NSError initWithMsg:@"+lastSeenPlatformInUserGetMethod: 'response' has not found"]; return nil;}
    
    
    NSDictionary* firstNastedObject = [response firstObject];
    if (!firstNastedObject) { *error = [NSError initWithMsg:@"+lastSeenPlatformInUserGetMethod: '[response firstObject]' has not found"]; return nil;}

    
    NSDictionary* lastSeenObject = firstNastedObject[@"last_seen"];
    if (!lastSeenObject) { *error = [NSError initWithMsg:@"+lastSeenPlatformInUserGetMethod: 'firstNastedObject[@\"last_seen\"]' has not found"]; return nil;}

    
    NSNumber* platform = lastSeenObject[@"platform"];
    if (!platform) { *error = [NSError initWithMsg:@"+lastSeenPlatformInUserGetMethod: 'lastSeenObject[@\"platform\"]' has not found"]; return nil;}

    
    return platform;
}

/*--------------------------------------------------------------------------------------------------------------
  Retrieves the number of subscribers from the 'counters' dictionary that was returned by a call to the 'UserGet' method.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) followersInUserGetMethodFromCounter:(NSDictionary*)counters error:(NSError*_Nullable* _Nullable)error
{
    if (counters.allKeys.count < 1) { *error = [NSError initWithMsg:@"+followersInUserGetMethodFromCounter: received empty json"]; return nil;}

    NSNumber* followers = counters[@"counters"];
    if (!followers) { *error = [NSError initWithMsg:@"+followersInUserGetMethodFromCounter: 'counters[@\"counters\"]' has not found"]; return nil;}

    return followers;
}

#pragma mark - Parsing elements from API method 'wall.post'
/*--------------------------------------------------------------------------------------------------------------
  Retrieves 'post_id' and json from 'wall.post' method
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) postIDInWallPostMethod:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+postIDInWallPostMethod: received empty json"]; return nil;}

    NSNumber* postID = nil;
    if (json[@"response"]){
        NSDictionary* response = json[@"response"];
        postID = response[@"post_id"];
    }else {
        *error = [NSError initWithMsg:@"+postIDInWallPostMethod: 'json[@\"response\"]' has not found"];
    }
    return postID;
}


@end
