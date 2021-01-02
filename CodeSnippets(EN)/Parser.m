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
 🗂 🔍 'Parser' - извлекает данные из сложной структуры.
 ---------------
 Применим исключительно в особых случаях, когда требуются достать глубоко расположенные данные.
 ---------------
 [⚖️] Duties:
 - Содержать код методов которые извлекают данные из сложных структур, чтобы не засорять данным кодом остальные сущности.
 ---------------
 [📇] Code style:
 1) Имя метода должно начинаться с названия того элемента который планируется извлекать. (Напр. 'lastSeenPlatform')
 2) После имени метода обязательно идет название API метода (напр 'UserGet') и суфикс 'Method'.
 3) Имя аргумента должно быть идентично названию того родительского контейнера, который передается в функцию.
    Если вы хотите чтобы метод самостоятельно искал нужные данные от того ответа который пришел с сервера, то имя
    аргументу вы должны дать 'json'.
 4) Если условия вынуждают создать два похожих метода которые работают с одной и той же структурой, то во избежание
 дублирования названия то на конец метода разрешается добавить суффикс 'From' и имя вложенной структуры из которой
 будет извлеченны данные.
 Пример: 'followers'+'InUserGet'+'Method'+'From'+'Counters'.
 --------------------------------------------------------------------------------------------------------------*/


@implementation Parser

#pragma mark - Parsing elements from API method 'user.get'
/*--------------------------------------------------------------------------------------------------------------
 Извлекает код платформы с которой пользователь совершил свой крайний сеанс.
 Извлекает данные из ответа сервера на выполнение метода 'UserGet'.
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
 Извлекает количество подписчиков из словаря 'counters' который был получен в ответ вызов метода 'UserGet'.
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
 Извлекает 'post_id' и json полученного по методу 'wall.post'
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
