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
 (📄) File 'APIMethods.h' - содержит перечисления API методов которые поддерживает 'APIManager'
 --------------------------------------------------------------------------------------------------------------*/

#pragma mark - Enum API Part
/*--------------------------------------------------------------------------------------------------------------
 Перечисления API методов которые поддерживает 'APIManager'.
 Используются для удобства в 'NetworkRequestConstructor' в качестве аргументов для функций построения запросов.
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
  Строковые константы содержащие название EndPoint название API-методов.
  Используются конструктором 'NetworkRequestConstructor' при построении NSURLRequest.
 --------------------------------------------------------------------------------------------------------------*/
static NSString *const usersGet = @"users.get"; // Возвращает расширенную информацию о пользователях.
static NSString *const wallGet  = @"wall.get";  // Возвращает записи со стены пользователей
static NSString *const wallPost = @"wall.post"; // Позволяет создать запись на стене,

static NSString *const photosGetAll  = @"photos.getAll"; // Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
static NSString *const friendsGet    = @"friends.get";   // Возвращает список идентификаторов друзей пользователя или расширенную информацию о друзьях пользователя


static NSString *const photosGetWallUploadServer = @"photos.getWallUploadServer"; // Возвращает адрес сервера для загрузки фотографии на стену пользователя или сообщества.
static NSString *const photosSaveWallPhoto       = @"photos.saveWallPhoto";       // Сохраняет фотографии после успешной загрузки на URI, полученный методом

static NSString *const logout = @"auth.logout";

#endif /* APIMethods_h */
