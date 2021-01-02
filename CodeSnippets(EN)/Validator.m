//
//  Validator.m
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "Validator.h"
// APIManager's Categories
#import "APIManager+Utilites.h"
// Восстанавливает с диска json файлы по ключам APIMethod
#import "Templater.h"


/*--------------------------------------------------------------------------------------------------------------
 Константы для работы со словарями содержащими правила для расширенной валидации
 --------------------------------------------------------------------------------------------------------------*/

// Shared
NSString * const isOptionalKey = @"isOptional";
NSString * const mustMatchKey  = @"mustMatch";

// For Strings
NSString * const equalInLengthKey                  = @"equalInLength";
NSString * const lengthMustBeEqualOrGreaterThanKey = @"lengthMustBeEqualOrGreaterThan";
NSString * const lengthMustBeEqualOrLessThanKey    = @"lengthMustBeEqualOrLessThan";
NSString * const hasSuffixKey                      = @"hasSuffix";
NSString * const matchWithOneOfKey                 = @"matchWithOneOf";

// For Arrays
NSString * const elementsMustBeEqualOrMoreThanKey  = @"elementsMustBeEqualOrMoreThan";
NSString * const elementsMustBeEqualOrLessThanKey  = @"elementsMustBeEqualOrLessThan";


// For Number
NSString * const minimumKey  = @"minimum";
NSString * const maximumKey  = @"maximum";


/*--------------------------------------------------------------------------------------------------------------
 | [📄⚙️] ➡️ [🗃] Instructions for adding new validation parameters to dictionary rules.
 ---------------------------------------------------------------------------------------------------------------
 
 1. Добавьте новый ключ как константу в шапке файла.
 2. Добавьте обработку новых ключей в методы валидации разных типов:
     +validateString:
     +validateArray:
     +validateDictionary:
     +validateNumber:
 --------------------------------------------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------------------------------------------
 | 🚦⚖️📄 Инструкция по добавлению новых методов валидирующих ответы сервера
 ---------------------------------------------------------------------------------------------------------------
 
 1. Создайте новый уникальный метод. Используйте префикс "validateResponseFrom_", после должно идти имя API метода
    Пример:
   + (NSError* _Nullable) validateResponseFrom_usersGet:(NSDictionary*)recievedJSON

 2. Самостоятельно реализуйте валидацию ответа. Выбрав автоматическую либо ручную.
 
 3. Предварительно добавив значение для нового API метода в перечисление APIMethod.
 
 4. В методе +validateResponse:fromAPIMethod: добавьте свой метод валидации в конструкцию switch.
 --------------------------------------------------------------------------------------------------------------*/


@implementation Validator

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______. __    __       ___      .______       _______  _______
     /       ||  |  |  |     /   \     |   _  \     |   ____||       \
    |   (----`|  |__|  |    /  ^  \    |  |_)  |    |  |__   |  .--.  |
     \   \    |   __   |   /  /_\  \   |      /     |   __|  |  |  |  |
 .----)   |   |  |  |  |  /  _____  \  |  |\  \----.|  |____ |  '--'  |
 |_______/    |__|  |__| /__/     \__\ | _| `._____||_______||_______/
 
 ____    ____  ___       __       __   _______       ___   .___________. __    ______   .__   __.
 \   \  /   / /   \     |  |     |  | |       \     /   \  |           ||  |  /  __  \  |  \ |  |
  \   \/   / /  ^  \    |  |     |  | |  .--.  |   /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |
   \      / /  /_\  \   |  |     |  | |  |  |  |  /  /_\  \    |  |     |  | |  |  |  | |  . `  |
    \    / /  _____  \  |  `----.|  | |  '--'  | /  _____  \   |  |     |  | |  `--'  | |  |\   |
     \__/ /__/     \__\ |_______||__| |_______/ /__/     \__\  |__|     |__|  \______/  |__| \__|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Shared Validation Methods

/*--------------------------------------------------------------------------------------------------------------
  Метод распределитель, самостоятельно определяет какой метод валидации вызывать для json полученного по конкретнному методу API
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponse:(NSDictionary*)recievedJSON fromAPIMethod:(APIMethod)method
{
    NSError* error  = nil;
    switch (method) {
        case APIMethod_UserGet: error = [Validator validateResponseFrom_usersGet:recievedJSON]; break;
        case APIMethod_WallGet: error = [Validator validateResponseFrom_wallGet:recievedJSON];  break;
      
        case APIMethod_PhotosGetAll: error = [Validator validateResponseFrom_photosGetAll:recievedJSON];  break;
        case APIMethod_FriendsGet:   error = [Validator validateResponseFrom_friendsGet:recievedJSON];    break;
            
        default: APILog(@"+validateResponse:fromAPIMethod: | Switch not found mathes!"); break;
    }
    return error;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______..______    _______   ______  __   _______  __    ______
     /       ||   _  \  |   ____| /      ||  | |   ____||  |  /      |
    |   (----`|  |_)  | |  |__   |  ,----'|  | |  |__   |  | |  ,----'
     \   \    |   ___/  |   __|  |  |     |  | |   __|  |  | |  |
 .----)   |   |  |      |  |____ |  `----.|  | |  |     |  | |  `----.
 |_______/    | _|      |_______| \______||__| |__|     |__|  \______|
 
 ____    ____  ___       __       __   _______       ___   .___________. __    ______   .__   __.
 \   \  /   / /   \     |  |     |  | |       \     /   \  |           ||  |  /  __  \  |  \ |  |
  \   \/   / /  ^  \    |  |     |  | |  .--.  |   /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |
   \      / /  /_\  \   |  |     |  | |  |  |  |  /  /_\  \    |  |     |  | |  |  |  | |  . `  |
    \    / /  _____  \  |  `----.|  | |  '--'  | /  _____  \   |  |     |  | |  `--'  | |  |\   |
     \__/ /__/     \__\ |_______||__| |_______/ /__/     \__\  |__|     |__|  \______/  |__| \__|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Specific Validation Methods (for specific API methods)

/*--------------------------------------------------------------------------------------------------------------
 Метод валидирует ответ сервера на запрос метода "users.get".
 ------------------------------------------------------------
 Реализация метода полностью зависит от потребностей разработчика.
 Вы можете написать тут собственную кастомную проверку, а при наличии шаблона можете воспользоваться методом
 автоматического тестирования, который сверит полученный json и его образец с диска по десятку параметров.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_usersGet:(NSDictionary*)recievedJSON
{
    NSDictionary* template = [Templater templateForAPIMethod:APIMethod_UserGet];
    if (!template) return nil;
    
    NSError* error = [Validator automaticValidateResponse:recievedJSON
                                                 template:template
                                           validationMask:AllChecks
                                            fromAPIMethod:APIMethod_UserGet];
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод валидирует ответ сервера на запрос метода "wall.get".
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_wallGet:(NSDictionary*)recievedJSON
{
    NSDictionary* template = [Templater templateForAPIMethod:APIMethod_WallGet];
    if (!template) return nil;
    
    NSError* error = [Validator automaticValidateResponse:recievedJSON
                                                 template:template
                                           validationMask:AllChecks
                                            fromAPIMethod:APIMethod_WallGet];
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод валидирует ответ сервера на запрос метода "photos.getAll".
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_photosGetAll:(NSDictionary*)recievedJSON
{
    NSDictionary* template = [Templater templateForAPIMethod:APIMethod_PhotosGetAll];
    if (!template) return nil;
    return nil;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод валидирует ответ сервера на запрос метода "friends.get".
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_friendsGet:(NSDictionary*)recievedJSON
{
    NSDictionary* template = [Templater templateForAPIMethod:APIMethod_FriendsGet];
    if (!template) return nil;
    return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
     ___      __    __  .___________.  ______   .___  ___.      ___   .___________. __    ______
    /   \    |  |  |  | |           | /  __  \  |   \/   |     /   \  |           ||  |  /      |
   /  ^  \   |  |  |  | `---|  |----`|  |  |  | |  \  /  |    /  ^  \ `---|  |----`|  | |  ,----'
  /  /_\  \  |  |  |  |     |  |     |  |  |  | |  |\/|  |   /  /_\  \    |  |     |  | |  |
 /  _____  \ |  `--'  |     |  |     |  `--'  | |  |  |  |  /  _____  \   |  |     |  | |  `----.
/__/     \__\ \______/      |__|      \______/  |__|  |__| /__/     \__\  |__|     |__|  \______|

____    ____  ___       __       __   _______       ___   .___________. __    ______   .__   __.
\   \  /   / /   \     |  |     |  | |       \     /   \  |           ||  |  /  __  \  |  \ |  |
 \   \/   / /  ^  \    |  |     |  | |  .--.  |   /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |
  \      / /  /_\  \   |  |     |  | |  |  |  |  /  /_\  \    |  |     |  | |  |  |  | |  . `  |
   \    / /  _____  \  |  `----.|  | |  '--'  | /  _____  \   |  |     |  | |  `--'  | |  |\   |
    \__/ /__/     \__\ |_______||__| |_______/ /__/     \__\  |__|     |__|  \______/  |__| \__|
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Метод автоматической валидации сверяет пришедший json и образец с диска.
 В случае нахождения несовпадений - возвращает ошибку.
 
 Также вы самостоятельно можете значительно кастомизировать процесс валидации - прописав условия в шаблоне для каждого
 объекта из json.
 Пример:
 
 {
   "fistName" : "Steve",
   "firstName-Rules" : { "isOptional" : true,
                         "lengthMustBeEqualOrGreaterThan" : 1
                       }
 }
 
 Создайте словарь с правилами по приниципу "имяКлюча-Rules". Алгоритм автоматический определит наличие дополнительных
 параметров валидации для таких объектов.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) automaticValidateResponse:(NSDictionary*)recievedJSON
                                        template:(NSDictionary*)templateJSON
                                  validationMask:(ResponseValidationMask)mask
                                   fromAPIMethod:(APIMethod)method
{
    NSError* error      = nil;
    BOOL isOccuredError = NO;
    NSString* domain;
    NSMutableArray* userInfoArray = [NSMutableArray new];
    
    if ((recievedJSON.allKeys.count < 1) || (templateJSON.allKeys.count < 1)){
        domain = [NSString stringWithFormat:@"'recievedJSON' or 'templateJSON' is nil."];
        domain = [NSString stringWithFormat:@"%@\nIn +[Validator automaticValidateResponse:template:validationMask:]",domain];
        return [NSError errorWithDomain:domain code:0 userInfo:nil];
    }
    

    NSArray<NSString*>* allKeysFromRecievedJSON = [recievedJSON allKeys];
    NSArray<NSString*>* allKeysFromTemplateJSON = [templateJSON allKeys];

    for (NSString* key in allKeysFromTemplateJSON)
    {
        if ([key hasSuffix:@"-Rules"]){
            continue;
        }
        // Массив нужен для того, чтобы в конце цикла for решить, нужно ли осуществлять проверку на правила.
        // Если ошибки были обнаружены в основным алгоритмом то есть (отсутьствие ключа,другой класс итд),
        // тогда просто нету смысла осуществлять проверку на правила для конкретнной пары ключ-значение
        NSMutableArray* localUserInfoArray = [NSMutableArray new];

        id valueFromJSON     = recievedJSON[key];
        id valueFromTemplate = templateJSON[key];
        
        NSDictionary* rules = [Validator rulesByKey:key inJSON:templateJSON];
        BOOL     isOptional = [rules[isOptionalKey] boolValue];

        // Проверяем на наличие ключей
        if ((mask & CheckOnKeys) && (![allKeysFromRecievedJSON containsObject:key]) && (!isOptional)){
            isOccuredError = YES;
            domain = [NSString stringWithFormat:@"json hasn't '%@' key",key];
            [userInfoArray addObject:domain];
            continue;
        } else if ((![allKeysFromRecievedJSON containsObject:key]) && (isOptional)) {
            continue;
        }
        
        // Проверка на типы
        if (mask & CheckOnTypesOfValues)
        {
            NSString* superClassValueFromJSON     = [Validator typeSuperClassName:[valueFromJSON superclass]];
            NSString* superClassValueFromTemplate = [Validator typeSuperClassName:[valueFromTemplate superclass]];
            
            // Обрабатываем случай если значения по ключам имеет разные типы,классы.
            if (![superClassValueFromJSON isEqualToString:superClassValueFromTemplate]){
                isOccuredError = YES;
                domain = [NSString stringWithFormat:@"Value for key '%@' in recievedJSON has class (%@)\n"
                          "Value for key '%@' in templateJSON has class (%@).",
                          key,superClassValueFromJSON,
                          key,superClassValueFromTemplate];
                [localUserInfoArray addObject:domain];
            }
        }
        
        // Проверяем вложенности
        if ((mask & CheckSubEntityOnKeys) && (recievedJSON[key])){
            
            //NSLog(@"valueFromJSON.class %@",NSStringFromClass([valueFromJSON superclass]));
            //NSLog(@"valueFromTemplate.class %@",NSStringFromClass([valueFromTemplate superclass]));

           if (([valueFromJSON isKindOfClass:[NSDictionary class]]) &&
               ([valueFromTemplate isKindOfClass:[NSDictionary class]])) {
               
                // Рекурсивно вызываем проверку вложенных подсловарей
                NSError* subError = [Validator automaticValidateResponse:valueFromJSON
                                                                template:valueFromTemplate
                                                          validationMask:mask
                                                           fromAPIMethod:method];
               
                if ((subError) && (subError.userInfo[@"userInfoArray"]))
                {
                    isOccuredError = YES;
                    [localUserInfoArray addObjectsFromArray:subError.userInfo[@"userInfoArray"]];
                }
            }
        }
        
        // Запускаем проверку на словарь с правилами, если мы прошли все предыдущие проверки
        if ((mask & CheckOnExtendedRules) && (rules.allKeys.count > 0) && (localUserInfoArray.count < 1)) {
            NSError* subError = [Validator validateJSONValue:valueFromJSON templateValue:valueFromTemplate key:key onRules:rules];
          
            if ((subError) && (subError.userInfo[@"userInfoArray"])) {
                isOccuredError = YES;
                [userInfoArray addObjectsFromArray:subError.userInfo[@"userInfoArray"]];
            }
        } else {
            [userInfoArray addObjectsFromArray:localUserInfoArray];
        }
    }
    
    // Инициализируем ошибку если она возникла
    if (isOccuredError)
    {
        NSString* APIMethod = [API convertAPIMethodToString:method];
        domain = [NSString stringWithFormat:@"json recieved from API method (%@) has incorrect stucture",APIMethod];
        error  = [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
    }
    return error;
}



///////////////////////////////////////////////////////////////////////////////
/*
 .______       __    __   __       _______    ____    ____  ___       __       __   _______       ___   .___________. _______
 |   _  \     |  |  |  | |  |     |   ____|   \   \  /   / /   \     |  |     |  | |       \     /   \  |           ||   ____|
 |  |_)  |    |  |  |  | |  |     |  |__       \   \/   / /  ^  \    |  |     |  | |  .--.  |   /  ^  \ `---|  |----`|  |__
 |      /     |  |  |  | |  |     |   __|       \      / /  /_\  \   |  |     |  | |  |  |  |  /  /_\  \    |  |     |   __|
 |  |\  \----.|  `--'  | |  `----.|  |____       \    / /  _____  \  |  `----.|  | |  '--'  | /  _____  \   |  |     |  |____
 | _| `._____| \______/  |_______||_______|       \__/ /__/     \__\ |_______||__| |_______/ /__/     \__\  |__|     |_______|
 */
///////////////////////////////////////////////////////////////////////////////

#pragma mark - Rule Validate

/*--------------------------------------------------------------------------------------------------------------
 Осуществляет проверку по параметрам заданным в json файле.
 Принимает значение из json файла, и в зависимости от их типа (String/Array/Dictionary/Number) вызывать нужный
 метод валидации для данного типа.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateJSONValue:(id)jsonValue templateValue:(id)templateValue key:(NSString*)key onRules:(NSDictionary*)rules
{
    NSError*  error   = nil;
    NSString* message = nil;
    
    // Check on nil
    if ((!jsonValue) || (!templateValue) || (!rules)){
        message = @"One of params is nil. In +validateJSONValue:templateValue:key:onRules:";
        return [NSError errorWithDomain:message code:0 userInfo:@{ @"userInfoArray" : @[message] }];
    }
    
    // Check on other class
    NSString* superClassValueFromJSON     = [Validator typeSuperClassName:[jsonValue superclass]];
    NSString* superClassValueFromTemplate = [Validator typeSuperClassName:[templateValue superclass]];
    
    // Обрабатываем случай если значения по ключам имеет разные типы,классы.
    if (![superClassValueFromJSON isEqualToString:superClassValueFromTemplate]){
        message = @"jsonValue & templateValue are members of other classes. In +validateJSONValue:templateValue:key:onRules:";
        return [NSError errorWithDomain:message code:0 userInfo:@{ @"userInfoArray" : @[message] }];
    }
    
    // String case:
    if ([superClassValueFromJSON isEqualToString:@"NSString"]){
        return [Validator validateString:jsonValue templateString:templateValue key:key onRules:rules];
    }
    
    // Array case:
    if ([superClassValueFromJSON isEqualToString:@"NSArray"]){
        return [Validator validateArray:jsonValue templateArray:templateValue key:key onRules:rules];
    }

    // Dictionary case:
    if ([superClassValueFromJSON isEqualToString:@"NSDictionary"]){
        return [Validator validateDictionary:jsonValue templateDictionary:templateValue key:key onRules:rules];
    }
    
    // Number case:
    if ([superClassValueFromJSON isEqualToString:@"NSNumber"]){
        return  [Validator validateNumber:jsonValue templateNumber:templateValue key:key onRules:rules];
    }
    
    return error;
}

/*--------------------------------------------------------------------------------------------------------------
 Метод занимается валидированием переменных типа NSString
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateString:(nullable NSString*)jsonString
                       templateString:(NSString*)templateString
                                  key:(NSString*)key
                              onRules:(NSDictionary*)rules
{
    NSError*  error  = nil;
    NSString* domain = nil;
    NSMutableArray* userInfoArray = [NSMutableArray new];
    
    // Check on nil
    if ((!templateString) || (rules.allKeys.count < 1)){
        domain = str(@"One of params (in +validateString:...) is nil. By key (%@)",key);
        return [NSError errorWithDomain:domain code:0 userInfo: @{ @"userInfoArray" : @[domain] }];
    }
    
    BOOL isOptional             =  [rules[isOptionalKey]        boolValue];
    BOOL  mustMatch             =  [rules[mustMatchKey]         boolValue];
    BOOL equalInLength          =  [rules[equalInLengthKey]     boolValue];
    NSInteger lengthMustBeEqualOrGreaterThan =  [rules[lengthMustBeEqualOrGreaterThanKey] integerValue];
    NSInteger lengthMustBeEqualOrLessThan    =  [rules[lengthMustBeEqualOrLessThanKey]    integerValue];
    NSString* hasSuffix         =  rules[hasSuffixKey];
    NSArray*  matchWithOneOf    =  rules[matchWithOneOfKey];
    
    
    // Если значение из json==nil, а условия говорят, что проперти необязательно
    if ((isOptional) && (!jsonString)){
        return nil;
    }
    
    //hasSuffix
    if ((hasSuffix) && (![jsonString hasPrefix:hasSuffix])) {
        domain = str(@"The value(%@) by key(%@) hasn't requiered suffix(%@)",jsonString,key,hasSuffix);
        [userInfoArray addObject:domain];
    }
    
    // matchWithOneOf
    if (matchWithOneOf.count > 0) {
       NSArray*  lowercaseArray  =  [Validator lowercaseArray:matchWithOneOf];
       NSString* lowercaseString =  [jsonString lowercaseString];
      
        if (![lowercaseArray containsObject:lowercaseString]){
            domain = str(@"The value(%@) by key(%@) not found in the allowed array(%@))",jsonString,key,matchWithOneOf);
            [userInfoArray addObject:domain];
        }
    }
    
    if ((mustMatch) && (![jsonString isEqualToString:templateString])) {
        domain = str(@"The value by key(%@) not match with required=%@)",key,templateString);
        [userInfoArray addObject:domain];
    }
    
    if ((equalInLength) && (jsonString.length != templateString.length)) {
        domain = str(@"The length of values for key(%@) does not match",key);
        [userInfoArray addObject:domain];
    }
    
    if ((rules[@"lengthMustBeEqualOrGreaterThan"]) && (rules[@"lengthMustBeEqualOrLessThan"])){
        if (lengthMustBeEqualOrGreaterThan > lengthMustBeEqualOrLessThan){
            domain = str(@"Invalid rules (lengthMustBeEqualOrGreaterThan (cannot be greater than)> lengthMustBeEqualOrLessThan) in key(%@) value(%@)",key,jsonString);
            [userInfoArray addObject:domain];
            return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
        }
    }
    
    //lengthGreaterThan
    if ((rules[@"lengthMustBeEqualOrGreaterThan"]) && (jsonString.length <= lengthMustBeEqualOrGreaterThan)) {
        domain = str(@"The length of the key(%@) value is less than the required length. Must be greater than %d",key,lengthMustBeEqualOrGreaterThan);
        [userInfoArray addObject:domain];
    }
    
    //lengthGreaterThan
    if ((rules[@"lengthMustBeEqualOrLessThan"]) && (jsonString.length >= lengthMustBeEqualOrLessThan)) {
        domain = str(@"The length of the key(%@) value is greater than the required length. Must be less than %d",key,lengthMustBeEqualOrLessThan);
        [userInfoArray addObject:domain];
    }
    
    
    if (userInfoArray.count > 0){
        domain = [NSString stringWithFormat:@"Value for key(%@) has uncorrect data or structure",key];
        error  = [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
    }
    
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод занимается валидированием объектов типа NSArray
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateArray:(nullable NSArray*)jsonArray
                       templateArray:(NSArray*)templateArray
                                 key:(NSString*)key
                             onRules:(NSDictionary*)rules
{
    NSError*  error  = nil;
    NSString* domain = nil;
    NSMutableArray* userInfoArray = [NSMutableArray new];
    
    // Check on nil
    if ((!templateArray) || (rules.allKeys.count < 1)){
        domain = str(@"One of params (in +validateArray:...) is nil. By key (%@)",key);
        return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : @[domain] }];
    }
    
    BOOL isOptional = [rules[isOptionalKey] boolValue];
    BOOL  mustMatch = [rules[mustMatchKey]  boolValue];

    NSInteger elementsMustBeEqualOrMoreThan = [rules[elementsMustBeEqualOrMoreThanKey] integerValue];
    NSInteger elementsMustBeEqualOrLessThan = [rules[elementsMustBeEqualOrLessThanKey] integerValue];
    
    // Если значение из json==nil, а условия говорят, что проперти необязательно
    if ((isOptional) && (!jsonArray)){
        return nil;
    }
    
    if (mustMatch){
        
        NSArray* arrayWithoutRules  = [Validator removeAllRulesFromArrayAndNastedStructure:templateArray];
        NSArray* lowercaseTemplate  = [Validator lowercaseArray:arrayWithoutRules];
        NSArray* lowercaseJSON      = [Validator lowercaseArray:jsonArray];
        
        if (![lowercaseTemplate isEqualToArray:lowercaseJSON]){
            domain = str(@"The value by key(%@) not match with required=%@)",key,templateArray);
            [userInfoArray addObject:domain];
        }
    }
    
    if ((rules[@"elementsMustBeEqualOrMoreThan"]) && (jsonArray.count < elementsMustBeEqualOrMoreThan)){
        domain = str(@"Array by key(%@) from json has less elements than required(%d)",key,elementsMustBeEqualOrMoreThan);
        [userInfoArray addObject:domain];
    }
    
    if ((rules[@"elementsMustBeEqualOrLessThan"]) && (jsonArray.count > elementsMustBeEqualOrLessThan)){
        domain = str(@"Array by key(%@) from json has greater elements than required(%d)",key,elementsMustBeEqualOrLessThan);
        [userInfoArray addObject:domain];
    }
    
    
    if (userInfoArray.count > 0){
        domain = [NSString stringWithFormat:@"Value for key(%@) has uncorrect data or structure",key];
        error  = [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
    }
    
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод занимается валидированием объектов типа NSDictionary
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateDictionary:(nullable NSDictionary*)jsonDictionary
                       templateDictionary:(NSDictionary*)templateDictionary
                                      key:(NSString*)key
                                  onRules:(NSDictionary*)rules
{
    NSError*  error  = nil;
    NSString* domain = nil;
    
    // Check on nil
    if ((!templateDictionary) || (rules.allKeys.count < 1)){
        domain = str(@"One of params (in +validateDictionary:...) is nil. By key (%@)",key);
        return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : @[domain] }];
    }
    
    BOOL isOptional = [rules[isOptionalKey] boolValue];
    BOOL  mustMatch = [rules[mustMatchKey]  boolValue];
    
    // Если значение из json==nil, а условия говорят, что проперти необязательно
    if ((isOptional) && (!jsonDictionary)){
        return nil;
    }
    
    if (mustMatch){
        NSDictionary* templateWithoutRules = [Validator removeAllRulesFromDictionaryAndNastedStructure:templateDictionary];
        if (![jsonDictionary isEqualToDictionary:templateWithoutRules]){
            domain = str(@"The value by key(%@) not match with required=(%@)",key,templateDictionary);
            return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : @[domain] }];
        }
    }
    return error;
}



/*--------------------------------------------------------------------------------------------------------------
 Метод занимается валидированием объектов типа NSNumber. Обрабатывает только численные значения (int/float/..ect)
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateNumber:(nullable NSNumber*)jsonNumber
                       templateNumber:(NSNumber*)templateNumber
                                  key:(NSString*)key
                              onRules:(NSDictionary*)rules
{
    NSError*  error  = nil;
    NSString* domain = nil;
    NSMutableArray* userInfoArray = [NSMutableArray new];
    
    // Check on nil
    if ((!templateNumber) || (rules.allKeys.count < 1)){
        domain = str(@"One of params (in +validateNumber:...) is nil. By key (%@)",key);
        return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : @[domain] }];
    }
    float jsonFloat = [jsonNumber  floatValue];

    BOOL isOptional = [rules[isOptionalKey] boolValue];
    BOOL  mustMatch = [rules[mustMatchKey]  boolValue];
    
    float  minimum = [rules[minimumKey]  floatValue];
    float  maximum = [rules[maximumKey]  floatValue];

    
    // Если значение из json==nil, а условия говорят, что проперти необязательно
    if ((isOptional) && (!jsonNumber)){
        return nil;
    }
    
    if ((mustMatch) && (![jsonNumber isEqualToNumber:templateNumber])){
        domain = str(@"Number by key(%@) from json not matches with templete value(%@))",key,templateNumber);
        [userInfoArray addObject:domain];
    }
    
    // BOOL далее не валидируем
    if ([NSStringFromClass([jsonNumber class]) isEqualToString:@"__NSCFBoolean"]){
          if (userInfoArray.count > 0) return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
    }
    
    
    if ((rules[minimumKey]) && (rules[maximumKey])){
        if (minimum > maximum){
            domain = str(@"Invalid rules (minimum (cannot be greater than)> maximum) in key(%@))",key);
            [userInfoArray addObject:domain];
            return [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
        }
    }
    
    
    if ((rules[minimumKey]) && (jsonFloat < minimum)){
        domain = str(@"Number by key(%@) from json has value(%f). But mandatory minimum is (%f))",key,jsonFloat,minimum);
        [userInfoArray addObject:domain];
    }
    
    
    if ((rules[maximumKey]) && (jsonFloat > maximum)){
        domain = str(@"Number by key(%@) from json has value(%f). But mandatory maximum is (%f))",key,jsonFloat,maximum);
        [userInfoArray addObject:domain];
    }
    
    if (userInfoArray.count > 0){
        domain = [NSString stringWithFormat:@"Value for key(%@) has uncorrect data or structure",key];
        error  = [NSError errorWithDomain:domain code:0 userInfo:@{ @"userInfoArray" : userInfoArray }];
    }
    return error;
}





///////////////////////////////////////////////////////////////////////////////
/*
  __    __   _______  __      .______    _______ .______
 |  |  |  | |   ____||  |     |   _  \  |   ____||   _  \
 |  |__|  | |  |__   |  |     |  |_)  | |  |__   |  |_)  |
 |   __   | |   __|  |  |     |   ___/  |   __|  |      /
 |  |  |  | |  |____ |  `----.|  |      |  |____ |  |\  \----.
 |__|  |__| |_______||_______|| _|      |_______|| _| `._____|
 */
///////////////////////////////////////////////////////////////////////////////

#pragma mark - Helper

/*--------------------------------------------------------------------------------------------------------------
 Метод принимает объект 'Class' и  возвращает имя суперкласса приведенное к одому стандарту.
 Например может возникнуть ситуация, что в друх разных словарях строки могут быть представлены разными классами
 ('__NSCFString' и 'NSString').
 Поэтому класс управляет всеми исключениями, и возвращает всегда названия классов из Foundation.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) typeSuperClassName:(Class)superClass
{
    NSString* superClassName = NSStringFromClass(superClass);
    
    // Исключения
    if (([superClassName isEqualToString:@"__NSCFString"]) || ([superClassName isEqualToString:@"NSMutableString"])){
        return @"NSString";
    }
    
    // Далее тут можно прописывать поддержку других классов....
    return superClassName;
}


/*--------------------------------------------------------------------------------------------------------------
 Возвращает словарь с правилами (если он имеется) для конкретного ключа из общего json
 --------------------------------------------------------------------------------------------------------------*/
+ (NSDictionary* _Nullable) rulesByKey:(NSString*)key inJSON:(NSDictionary*)json
{
    if ((!key) || (!json)) return nil;
    
    NSDictionary* rules = nil;
    NSString*   ruleKey = [NSString stringWithFormat:@"%@-Rules",key];
    
    if (json[ruleKey]){
        rules = json[ruleKey];
    }
    return rules;
}



/*--------------------------------------------------------------------------------------------------------------
 Удаляет все правила из словаря и из его вложенных структур.
 Это требуется в тех случаях, когда ключ "mustMatch" имеет целый словарь из шаблона, который в себе имеет
 правила для своих вложенных объектов.
 
 Чтобы алгоритм корректно провел сравнение ответа сервера и шаблона, то из последнего нужно удалить все 'rules'.
 --------------------------------------------------------------------------------------------------------------*/

+ (NSDictionary* _Nullable) removeAllRulesFromDictionaryAndNastedStructure:(NSDictionary*)dictionary
{
    NSMutableDictionary* mutableCopy = [dictionary mutableCopy];
    
    // (!) Кстати как решение, словари же можно было запаралелить, и искать пути в одном, а удалять в другом...
    
    // Проходим по всему словарю через его ключи
    for (NSString* key in [mutableCopy allKeys]) {
        
        // Если ключ содержит в себе этот суффикс, то значение это словарь с правилами, тогда удаляем сразу.
        if ([key rangeOfString:@"-Rules"].location != NSNotFound){
            [mutableCopy removeObjectForKey:key];
            continue;
        }
        // Если значение по ключу это какой-то словарь, то вызываем метод рекурсивно, пусть отчистит и вернет чистый.
        if ([mutableCopy[key] isKindOfClass:[NSDictionary class]]){
            mutableCopy[key] = [Validator removeAllRulesFromDictionaryAndNastedStructure:mutableCopy[key]];
            continue;
        }
        // Если значение по ключу это некий массив, то также вызываем метод и пусть вернет нам читсый массив
        if ([mutableCopy[key] isKindOfClass:[NSArray class]]){
            mutableCopy[key] = [Validator removeAllRulesFromArrayAndNastedStructure:mutableCopy[key]];
            continue;
        }
    }
    return mutableCopy;
}


/*--------------------------------------------------------------------------------------------------------------
  Метод +validateArray:.. среди прочих, поддерживает валидацию по флагу "mustMatch".
  Если массивы содержат в себе словари, а эти словари содержат объекты для которых имеются правила, то метод
  -isEqualToArray: не сможет выполнить корректную проверку.
 
  Для этого требуется удалить все правила во вложенных объектах.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSArray* _Nullable) removeAllRulesFromArrayAndNastedStructure:(NSArray*)array
{
    NSMutableArray* mutableCopy = [array mutableCopy];
    
    // Массив для хранения индексов словарей
    NSMutableArray<NSNumber*>* dictionariesIndexes = [NSMutableArray new];
    
    // Массив для хранения словарей
    NSMutableArray<NSDictionary*>* dictionaries    = [NSMutableArray new];
    
    
    // Проходим по массиву, определяем если текущий объект это словарь.
    // То заносим информацию в (dictionariesIndexes и dictionaries).
    for (NSInteger i=0; i<=mutableCopy.count-1; i++) {
        
        id value = mutableCopy[i];
        if ([value isKindOfClass:[NSDictionary class]]){
            [dictionaries        addObject:value];
            [dictionariesIndexes addObject:[NSNumber numberWithInteger:i]];
        }
    }
    
    // Проходим по массиву который содержит словари
    for (NSInteger i=0; i<=dictionaries.count-1; i++) {
        
        // Берем словарь
        NSDictionary* dictionary = dictionaries[i];
        // Берем его порядковый индекс в массиве mutableCopy (!)
        NSInteger         index  = [dictionariesIndexes[i] integerValue];
        
        // Вызываем метод отчистки словарей
        NSDictionary* newDict = [Validator removeAllRulesFromDictionaryAndNastedStructure:dictionary];
        // Отчищенный словарь помещаем по индексу в основной массив
        mutableCopy[index] = newDict;
    }
    return mutableCopy;
}


/*--------------------------------------------------------------------------------------------------------------
  Возвращает массив строк у которых все символы переведены в малый регистр.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSArray*) lowercaseArray:(NSArray*)array
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:array.count];
    
    for (id value in array) {

        if ([[Validator typeSuperClassName:[value superclass]] isEqualToString:@"NSString"]){
            NSString *str = (NSString*)value;
            [tempArray addObject:[str lowercaseString]];
        }
    }
    return [tempArray copy];
}

@end
