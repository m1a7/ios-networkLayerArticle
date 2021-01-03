

#import "APIManager+Utilites.h"

/*--------------------------------------------------------------------------------------------------------------
 🌐🍑 'APIManager(Utilites)' - contains methods used indirectly in 'APIManager' and its categories.
 ---------------
 Contains methods to help ensure correct functioning of 'APIManager' that cannot be placed
 into any of its other categories due to the fact that they are not included in their range of functional responsibilities.
 
 For example, these can be methods that:
 - convert 'NSDictionary' to 'NSData'.
 - determines the file extension by binary code.
 - converts the 'enum' value to 'NSString'
 --------------------------------------------------------------------------------------------------------------*/


@implementation APIManager (Utilites)

/*--------------------------------------------------------------------------------------------------------------
  Converts 'enum' values to 'NSString'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) convertAPIMethodToString:(APIMethod)enumValue
{
    NSString* convert;
    switch (enumValue) {
        case APIMethod_Unknow:     convert = @"unknow";       break;
        case APIMethod_UserGet:    convert = @"users.get";    break;
        case APIMethod_FriendsGet: convert = @"friends.get";  break;
      
        case APIMethod_WallGet:    convert = @"wall.get";     break;
        case APIMethod_WallPost:   convert = @"wall.post";    break;

        case APIMethod_PhotosGetAll:              convert = @"photos.getAll";              break;
        case APIMethod_PhotosGetWallUploadServer: convert = @"photos.getWallUploadServer"; break;
        case APIMethod_PhotosSaveWallPhoto:       convert = @"photos.saveWallPhoto";       break;

        case APIMethod_Logout: convert = @"auth.logout";  break;
        //...
        default: APILog(@"+convertAPIMethodToString| Switch not found mathes!"); break;
    }
    return convert;
}


/*--------------------------------------------------------------------------------------------------------------
  Returns 'mimeType' after parsing 'NSData'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    return nil;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns the file extension after parsing 'NSData'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString *)extensionForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"jpg";
            break;
        case 0x89:
            return @"png";
            break;
        case 0x47:
            return @"gif";
            break;
        case 0x49:
        case 0x4D:
            return @"tiff";
            break;
        case 0x25:
            return @"pdf";
            break;
        case 0xD0:
            return @"vnd";
            break;
        case 0x46:
            return @"txt";
            break;
        default:
            return @"octet-stream";
    }
    return nil;
}

/*--------------------------------------------------------------------------------------------------------------
 Converts binary to 'NSDictionary'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) convertDataToDict:(NSData*)data withError:(NSError**)error
{
    if (data.length < 1) return nil;
    
    NSDictionary* recoveredDict;
    if (@available(iOS 12, *)) {
        // iOS 12+
        recoveredDict = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDictionary class]
                                                          fromData:data
                                                             error:error];
    }else{
        // Before iOS 12
        recoveredDict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return recoveredDict;
}

@end
