//
//  APIConsts.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#ifndef APIConsts_h
#define APIConsts_h

/*--------------------------------------------------------------------------------------------------------------
 (📄) File 'APIConsts.h' - содержит объявление абревиатур и сокращенных названий
 --------------------------------------------------------------------------------------------------------------*/

@class  APIManager;
typedef APIManager API;

@class  NetworkRequestConstructor;
typedef NetworkRequestConstructor NRC;

typedef void(^AuthenticationCompletion)(NSError* _Nullable error);


/*--------------------------------------------------------------------------------------------------------------
 Макрос созданный для ситуации когда в приложении отключенно логирование.
 Но по прежнему имеется потребность выводить логи во время возникновения критических ошибок.
 Например:
 Валидатор не может найти шаблон запроса на диске и поэтому возвращает ошибку даже для корректного ответа сервера.
 --------------------------------------------------------------------------------------------------------------*/
#if __has_feature(objc_arc)
#define APILog(FORMAT, ...) fprintf(stderr,"%s %s\n", [[NSString stringWithFormat:@"%s",__PRETTY_FUNCTION__] UTF8String], [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define APILog(format, ...) CFShow([NSString stringWithFormat:@"%s %@",__PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]]);
#endif


/*--------------------------------------------------------------------------------------------------------------
 // C method that allows you to use concise syntax when creating a formatted string
 --------------------------------------------------------------------------------------------------------------*/
static inline NSString * _Nullable str(NSString * _Nullable format, ...)  {
    va_list ap;
    va_start(ap, format);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    
    va_end(ap);
    return message;
}


#endif /* APIConsts_h */
