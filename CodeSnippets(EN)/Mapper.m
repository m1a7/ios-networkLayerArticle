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
 📄 ➡️ 💾  'Mapper' - класс созданый для сборки моделей данных из json файлов
 ---------------
 Главная задача класса это декомпозировать 'APIManager', вынося из него код парсинга и маппинга моделей.
 ---------------
 [⚖️] Duties:
 - Создавать модели данных из полученного json.
 --------------------------------------------------------------------------------------------------------------*/

@implementation Mapper

/*--------------------------------------------------------------------------------------------------------------
 Возвращает массив объектов содержащих детальную информацию о пользователях.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<UserProfile*>*) usersGetFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+usersGetFromJSON: received empty json"]; return nil;}

    FEMMapping*           objectMapping = [UserProfile defaultMapping];
    NSArray<UserProfile*>* userProfiles = [FEMDeserializer collectionFromRepresentation:json[@"response"] mapping:objectMapping];
    
    return userProfiles;
}

/*--------------------------------------------------------------------------------------------------------------
 Возвращает массив записей со стены пользователя или сообщества.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<WallPost*>*) wallPostsFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+wallPostsFromJSON: received empty json"]; return nil;}

    FEMMapping*     objectMapping = [WallPost defaultMapping];
    NSArray<WallPost*>* wallPosts = [FEMDeserializer collectionFromRepresentation:json[@"items"] mapping:objectMapping];
    
    // Теперь нужно проинициализировать авторов постов.
    NSArray* profiles = json[@"profiles"];
    NSArray* groups   = json[@"groups"];

    for (WallPost* post in wallPosts)
    {
        // Пост был опубликован от имени пользователя
        if (post.fromID > 0){
            NSDictionary* ownerDict        = [Mapper postOwnerByID:post.fromID inCollection:profiles];
            FEMMapping*   userOwnerMapping = [UserOwnerPost defaultMapping];
            UserOwnerPost* userOwnerPost = [FEMDeserializer objectFromRepresentation:ownerDict mapping:userOwnerMapping];
            post.owner = userOwnerPost;
        }
        // Пост был опубликован от имени группы
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
 Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSArray<Photo*>*)  photosGetAllFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+photosGetAllFromJSON: received empty json"]; return nil;}

    FEMMapping*     objectMapping = [Photo photosGetAllMapping];
    NSArray<Photo*>*       photos = [FEMDeserializer collectionFromRepresentation:json[@"items"] mapping:objectMapping];
    
    return photos;
}


/*--------------------------------------------------------------------------------------------------------------
 Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable PhotoGalleryCollection*)  photosCollectionFromJSON:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error
{
    if (json.allKeys.count < 1) { *error = [NSError initWithMsg:@"+photosCollectionFromJSON: received empty json"]; return nil;}
    
    FEMMapping*          objectMapping = [PhotoGalleryCollection defaultMapping];
    PhotoGalleryCollection* collection = [FEMDeserializer objectFromRepresentation:json mapping:objectMapping];
    
    return collection;
}



/*--------------------------------------------------------------------------------------------------------------
Возвращает список идентификаторов друзей пользователя или расширенную информацию о друзьях пользователя
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
  [Вспомогательный метод] Помогает вычленять 'id' собственника поста на стене.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) postOwnerByID:(NSInteger)fromID inCollection:(NSArray<NSDictionary*>*)collection
{
    // В 'collection' приходит либо массив 'profiles' либо 'groups'.
    // И этот метод должен найти словарь который содержит идентичный 'from_id'
    
    // Конвертируем отрицательно число в положительное.
    // Потому что в этих массивах вне зависимости от того пользователь или группа, у всех id будет положительным
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
