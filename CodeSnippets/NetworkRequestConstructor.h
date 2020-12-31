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
 🏗 'NetworkRequestConstructor' (aka NRC) - конструирует запросы ('NSURLRequest') для API.
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
 🥇 Основной метод для взаимодейсвтия с конструктором запросов.
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
 ⭐️ Возвращает расширенную информацию о пользователях.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
 - user_ids  : [155510513]
 - fields    : [photo_50,photo_100,online,last_seen,music]
 - name_case : Nom
 -------
 📖 Подробнее: https://vk.com/dev/users.get
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSMutableURLRequest*) buildRequestForMethod_UsersGet:(nullable NSDictionary<NSString*,id>*)properties;

+ (nullable NSMutableURLRequest*) buildRequestForMethod_UsersGet:(nullable NSArray<NSString*>*)userIds
                                                          fields:(nullable NSArray<NSString*>*)fields
                                                        nameCase:(nullable NSString*)nameCase;


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
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallGet:(nullable NSString*)ownerID
                                                          offset:(NSInteger)offset
                                                           count:(NSInteger)count
                                                          filter:(nullable NSString*)filter;

#pragma mark - APIMethod - wall.post

/*--------------------------------------------------------------------------------------------------------------
 ⭐️ Позволяет создать запись на стене, предложить запись на стене публичной страницы, опубликовать существующую отложенную запись.
 -------
 📥 Формирует запрос из пришедшего словаря с параметрами:
 
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
 📖 Подробнее: https://vk.com/dev/wall.post
 --------------------------------------------------------------------------------------------------------------*/

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_WallPost:(nullable NSString*)ownerID
                                                          message:(nullable NSString*)message
                                                      attachments:(nullable NSString*)attachments;


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

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetWallUploadServer:(nullable NSString*)userID
                                                                           groupID:(nullable NSString*)groupID;



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

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosSaveWallPhoto:(nullable NSString*)userID
                                                                     groupID:(nullable NSString*)groupID
                                                                       photo:(NSString*)photo
                                                                      server:(NSInteger)server
                                                                        hash:(NSString*)hash;



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
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSDictionary<NSString*,id>*)properties;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_PhotosGetAll:(nullable NSString*)ownerID
                                                               offset:(NSInteger)offset
                                                                count:(NSInteger)count;


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
                                                             offset:(NSInteger)offset;

+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_FriendsGet:(nullable NSDictionary<NSString*,id>*)properties;



#pragma mark - Another methods

/*--------------------------------------------------------------------------------------------------------------
  Принимает 'uploadURL' и конфигурирует 'POST' запрос для выгрузки фотографий на сервер.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableURLRequest* _Nullable) buildRequestForMethod_UploadImages:(NSArray<NSData*>*)imagesData
                                                            uploadURL:(NSString*)uploadURL;


#pragma mark - APIMethod - oauth.logout

+ (NSMutableURLRequest*) buildRequestForMethod_logout;


@end

NS_ASSUME_NONNULL_END