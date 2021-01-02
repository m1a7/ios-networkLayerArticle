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
 🏗 'NetworkRequestConstructor' (aka NRC) - класс созданный для конструирования запросов к API
 ---------------
 Главной задачей класса - это декомпозировать сетевой слой, взяв на себя обязанность в удобный для пользователя
 способ конфигурировать сетевые запросы к API.
 ---------------
 [⚖️] Duties:
 - Конфигурировать сетевые запросы к API.
 ---------------
 The class provides the following features:
 - вы можете получить нужный вам запрос используя общий метод +buildRequestForMethod:properties:.
 - вы можете получить нужный вам запрос используя индивидуальный метод для каждого метода API.
 ---------------
 Additionally:
 (⚠️) Для некоторых API методов класс предоставляет несколько видов методов-конструкторов.
 Первый вид принимает несколько сырых аргументов (int/nsstring/float/итд) и сам формирует запрос.
 Второй вид принимает готовый словарь с параметрами, и в случае надобности самостоятельно добавляет необходимые
 значения.
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
 🥇 Основной метод для взаимодейсвтия с конструктором запросов.
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
 ⭐️ Возвращает расширенную информацию о пользователях.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - user_ids  : [155510513]
 - fields    : [photo_50,photo_100,online,last_seen,music]
 - name_case : Nom
 -------
 📖 Подробнее: https://vk.com/dev/users.get
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_ids"]     =  @[];
    params[@"fields"]       =  @[@"photo_50",@"photo_100",@"photo_200",@"photo_max_orig",@"online",@"last_seen",@"counters"];
    params[@"name_case"]    =  @"Nom";
    params[@"v"]            =  @"5.122";
    params[@"access_token"] =  APIManager.token.access_token;

    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
         params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:usersGet] HTTPMethod:GET params:params headers:nil];
    
    return request;
}


#pragma mark - APIMethod - wall.get

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Возвращает записи со стены.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - owner_id  : 155510513
 - offset    : 0
 - count     : 10
 - filter    : all
 -------
 📖 Подробнее: https://vk.com/dev/wall.get
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"] = APIManager.token.userID;
    params[@"offset"]   = @"0";
    params[@"count"]    = @"1";
    params[@"filter"]   = @"all";
    params[@"extended"]     = @(YES);
    params[@"v"]            =  @"5.122";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:wallGet] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - wall.post

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Позволяет создать запись на стене, предложить запись на стене публичной страницы, опубликовать существующую отложенную запись.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - owner_id     : 155510513 (идентификатор пользователя или сообщества) (owner_id=-1 соответствует идентификатору сообщества.)
 - friends_only : 1/0 (запись будет доступна только друзьям./всем пользователям.)
 - from_group   : 1/0 ( запись будет опубликована от имени группы / запись будет опубликована от имени пользователя (по умолчанию))
 - message      : "" (текст сообщения (является обязательным, если не задан параметр attachments))
 - attachments  : "" (список объектов, приложенных к записи и разделённых символом ',')
                     <type><owner_id>_<media_id>,<type><owner_id>_<media_id>
                     <type> — тип медиа-приложения:
                     photo — фотография;
                     video — видеозапись;
                     Например:
                     photo100172_166443618,photo-1_265827614
 - services : "twitter"/"facebook"
 - signed   : 1/0 (у записи, размещенной от имени сообщества, будет добавлена подпись (имя пользователя, разместившего запись))
 - guid     : "" (уникальный идентификатор, предназначенный для предотвращения повторной отправки одинаковой записи. Действует в течение одного часа.)
 
 - mark_as_ads    : 1/0 (метки добавлено не будет./у записи, размещенной от имени сообщества, будет добавлена метка "это реклама")
 - close_comments : 1/0 (1 — комментарии к записи отключены. / 0 — комментарии к записи включены.)
 -------
 📖 Подробнее: https://vk.com/dev/wall.post
 --------------------------------------------------------------------------------------------------------------*/

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSString*)ownerID
                                                          message:(nullable NSString*)message
                                                      attachments:(nullable NSString*)attachments // а может массив принимать ?
{
    NSMutableDictionary* properties = [NSMutableDictionary new];
    
    properties[@"owner_id"]    = (ownerID.length  > 0) ? ownerID : APIManager.token.userID;
    properties[@"message"]     = (message.length > 0)  ? message : @"";
    properties[@"attachments"] = (attachments.length > 0) ? attachments : @"";
    
    return [NRC buildRequestForMethod_WallPost:properties];
}


+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSDictionary<NSString*,id>*)properties
{
    // Одно из этих двух проперти должно обязательно присутствовать
    if ((!properties[@"message"]) && (!properties[@"attachments"])){
        return nil;
    }
    
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"]     = APIManager.token.userID;
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:wallPost] HTTPMethod:GET params:params headers:nil];
    return request;
}

#pragma mark - APIMethod -  photos.getWallUploadServer

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Возвращает адрес сервера для загрузки фотографии на стену пользователя или сообщества.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - user_id  : 155510513 // Если на стену пользователя
 - group_id : 0         // Если на стену группы
 -------
 📖 Подробнее: https://vk.com/dev/photos.getWallUploadServer
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_id"]      = APIManager.token.userID;
    params[@"v"]            =  @"5.126";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosGetWallUploadServer] HTTPMethod:GET params:params headers:nil];
    return request;
}



#pragma mark - APIMethod - photos.getAll

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - owner_id : 155510513
 - offset   :
 - count    :
 - photo_sizes : bool
 - skip_hidden : bool
 - v           : 5.21
 -------
 📖 Подробнее: https://vk.com/dev/photos.getAll
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"owner_id"] = APIManager.token.userID;
    params[@"offset"]   = @"0";
    params[@"count"]    = @"1";
    
    params[@"photo_sizes"]  = @(NO);
    params[@"skip_hidden"]  = @(YES);
    
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosGetAll] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - photos.saveWallPhoto

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Сохраняет фотографии после успешной загрузки на URI, полученный методом
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - user_id  : 155510513 // Если на стену пользователя
 - group_id : 0         // Если на стену группы
 - photo    : ""
 - server   : 17
 - hash     : ""
 - latitude  : (от -90 до 90)
 - longitude : (от -180 до 180)
 - caption   : "tekst"
 -------
 📖 Подробнее: https://vk.com/dev/photos.saveWallPhoto
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    
    if (!properties[@"user_id"] && !properties[@"group_id"]){
         params[@"user_id"] = APIManager.token.userID;
    }
    params[@"v"]            =  @"5.126";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:photosSaveWallPhoto] HTTPMethod:GET params:params headers:nil];
    return request;
}


#pragma mark - APIMethod - friends.get

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Возвращает список идентификаторов друзей пользователя или расширенную информацию о друзьях пользователя
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
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
 📖 Подробнее: https://vk.com/dev/friends.get
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
    // Создаем шаблонную изначальную структуру параметров
    NSMutableDictionary* params = [NSMutableDictionary new];
    params[@"user_id"] = APIManager.token.userID;
    params[@"offset"]  = @"0";
    params[@"count"]   = @"1";
    
    params[@"order"]   = @"hints";
    params[@"fields"]  = @[@"photo_50",@"photo_100"];
    
    params[@"name_case"]    =  @"nom";
    params[@"v"]            =  @"5.21";
    params[@"access_token"] =  APIManager.token.access_token;
    
    // Объединяем словари если в 'properties' из аргументов вообще что-то есть.
    if ((properties.allKeys.count > 0) || (properties != nil)){
        params = (NSMutableDictionary*)[params mergeWithHighPriority:properties isConcatenateArrays:YES];
    }
    
    // Формируем request
    NSMutableURLRequest* request =
    [BO createRequestWithURL:[API baseURLappend:friendsGet] HTTPMethod:GET params:params headers:nil];
    return request;
}

#pragma mark - Another methods

/*--------------------------------------------------------------------------------------------------------------
 Принимает 'uploadURL' и конфигурирует 'POST' запрос для выгрузки фотографий на сервер.
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
