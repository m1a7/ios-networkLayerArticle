//
//  Parser.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


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
 4) Если условия вынуждают создать два похожих метода которые работают с одной и той же структурой, то во избежание
    дублирования названия то на конец метода разрешается добавить суффикс 'From' и имя вложенной структуры из которой
    будет извлеченны данные.
    Пример: 'followers'+'InUserGet'+'Method'+'From'+'Counters'.
 --------------------------------------------------------------------------------------------------------------*/

@interface Parser : NSObject


#pragma mark - Parsing elements from API method 'user.get'
/*--------------------------------------------------------------------------------------------------------------
 Извлекает код платформы с которой пользователь совершил свой крайний сеанс.
 Извлекает данные из ответа сервера на выполнение метода 'UserGet'.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) lastSeenPlatformInUserGetMethod:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

/*--------------------------------------------------------------------------------------------------------------
 Извлекает количество подписчиков из словаря 'counters' который был получен в ответ вызов метода 'UserGet'.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) followersInUserGetMethodFromCounter:(NSDictionary*)counters error:(NSError*_Nullable* _Nullable)error;


#pragma mark - Parsing elements from API method 'wall.post'
/*--------------------------------------------------------------------------------------------------------------
  Извлекает 'post_id' и json полученного по методу 'wall.post'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSNumber*) postIDInWallPostMethod:(NSDictionary*)json error:(NSError*_Nullable* _Nullable)error;

@end

NS_ASSUME_NONNULL_END
