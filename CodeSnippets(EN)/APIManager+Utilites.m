

#import "APIManager+Utilites.h"

/*--------------------------------------------------------------------------------------------------------------
 🌐🍑 'APIManager(Utilites)' - содержит методы косвенно используемые в 'APIManager' и его категориях.
 ---------------
 Содержит методы помогающие осуществлять корректное функционирование 'APIManager', которые невозможно поместить
 в любые другие его категории по причине того что не входят в их круг фунциональных обязанностей.
 
 Например это могут быть методы которые:
 - конвертируют 'NSDictionary' в 'NSData'.
 - определяет расширение файла по бинарному коду.
 - конвертирует значение 'enum' в 'NSString'
 --------------------------------------------------------------------------------------------------------------*/


@implementation APIManager (Utilites)

/*--------------------------------------------------------------------------------------------------------------
 Конвертирует значения 'enum' в 'NSString'
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
 Возвращает 'mimeType' после анализа 'NSData'
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
 Возвращает расширение файла после анализа 'NSData'
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
 Конвертирует бинарный код в 'NSDictionary'
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
