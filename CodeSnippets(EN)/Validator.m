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
// Recovers json files from disk using APIMethod keys
#import "Templater.h"


/*--------------------------------------------------------------------------------------------------------------
Constants for working with dictionaries containing rules for extended validation
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
 
 1. Add the new key as a constant in the header of the file.
 2. Add new key handling to different types of validation methods:
     +validateString:
     +validateArray:
     +validateDictionary:
     +validateNumber:
 --------------------------------------------------------------------------------------------------------------*/


/*--------------------------------------------------------------------------------------------------------------
 | 🚦⚖️📄 Instructions for adding new methods to validate server responses
 ---------------------------------------------------------------------------------------------------------------
 
 1. Create a new unique method. Use the "validateResponseFrom_" prefix, followed by the method API name
 Example:
   +(NSError* _Nullable)validateResponseFrom_usersGet:(NSDictionary*)recievedJSON

 2. Implement response validation yourself. By choosing automatic or manual.
 
 3. By pre-adding the value for the new API method to the APIMethod enumeration.
 
 4. In the +validateResponse:fromAPIMethod: method, add your validation method to the switch construct.
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
 The distributor method independently determines which validation method to call for json received by a specific API method
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
 The method validates the server response to the "users.get" method request.
 ------------------------------------------------------------
 The implementation of the method depends entirely on the needs of the developer.
 You can write your own custom check here, and if you have a template, you can use the method
 automatic testing, which will compare the received json and its sample from disk by ten parameters.
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
The method validates the server response to the request for the "wall.get" method.
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
 The method validates the server response to the "photos.getAll" method request.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_photosGetAll:(NSDictionary*)recievedJSON
{
    NSDictionary* template = [Templater templateForAPIMethod:APIMethod_PhotosGetAll];
    if (!template) return nil;
    return nil;
}


/*--------------------------------------------------------------------------------------------------------------
 The method validates the server response to the "friends.get" method request.
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
 The automatic validation method verifies the received json and the sample from disk.
 If a mismatch is found, it returns an error.
 
 You can also significantly customize the validation process yourself - by writing conditions in the template for each
 object from json.
 Example:
 
 {
   "fistName" : "Steve",
   "firstName-Rules" : { "isOptional" : true,
                         "lengthMustBeEqualOrGreaterThan" : 1
                       }
 }
 
 Create a dictionary with rules according to "KeyName-Rules". The algorithm will automatically detect the presence of additional
 validation parameters for such objects.
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
        // The array is needed in order to decide at the end of the for loop whether to check for rules.
        // If errors were found in the main algorithm, that is (lack of a key, another class, etc.),
        // then there is simply no point in checking for rules for a specific key-value pair
        NSMutableArray* localUserInfoArray = [NSMutableArray new];

        id valueFromJSON     = recievedJSON[key];
        id valueFromTemplate = templateJSON[key];
        
        NSDictionary* rules = [Validator rulesByKey:key inJSON:templateJSON];
        BOOL     isOptional = [rules[isOptionalKey] boolValue];

        // Checking for keys
        if ((mask & CheckOnKeys) && (![allKeysFromRecievedJSON containsObject:key]) && (!isOptional)){
            isOccuredError = YES;
            domain = [NSString stringWithFormat:@"json hasn't '%@' key",key];
            [userInfoArray addObject:domain];
            continue;
        } else if ((![allKeysFromRecievedJSON containsObject:key]) && (isOptional)) {
            continue;
        }
        
        // Type checking
        if (mask & CheckOnTypesOfValues)
        {
            NSString* superClassValueFromJSON     = [Validator typeSuperClassName:[valueFromJSON superclass]];
            NSString* superClassValueFromTemplate = [Validator typeSuperClassName:[valueFromTemplate superclass]];
            
            // We handle the case if the values for the keys have different types, classes.
            if (![superClassValueFromJSON isEqualToString:superClassValueFromTemplate]){
                isOccuredError = YES;
                domain = [NSString stringWithFormat:@"Value for key '%@' in recievedJSON has class (%@)\n"
                          "Value for key '%@' in templateJSON has class (%@).",
                          key,superClassValueFromJSON,
                          key,superClassValueFromTemplate];
                [localUserInfoArray addObject:domain];
            }
        }
        
        // Checking nesting
        if ((mask & CheckSubEntityOnKeys) && (recievedJSON[key])){
            
            //NSLog(@"valueFromJSON.class %@",NSStringFromClass([valueFromJSON superclass]));
            //NSLog(@"valueFromTemplate.class %@",NSStringFromClass([valueFromTemplate superclass]));

           if (([valueFromJSON isKindOfClass:[NSDictionary class]]) &&
               ([valueFromTemplate isKindOfClass:[NSDictionary class]])) {
               
                // Recursively invoke the check of nested subdictionaries
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
        
        // We run a check for a dictionary with rules if we have passed all the previous checks
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
    
    // We initialize an error if it occurs
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
 Checks according to the parameters specified in the json file.
 Takes a value from a json file, and depending on their type (String / Array / Dictionary / Number), call the required
 the validation method for the given type.
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
    
    // We handle the case if the values for the keys have different types, classes.
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
The method is engaged in the validation of variables of type NSString
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
    
    
    // If the value from json == nil, and the conditions say that it is not necessary to property
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
 The method is engaged in validating objects of type NSArray
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
    
    // If the value from json == nil, and the conditions say that it is not necessary to property
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
 The method is engaged in validating objects of type NSDictionary
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
    
    // If the value from json == nil, and the conditions say that it is not necessary to property
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
 The method validates objects of type NSNumber. Only handles numeric values (int / float / .. ect)
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

    
    // If the value from json == nil, and the conditions say that it is not necessary to property
    if ((isOptional) && (!jsonNumber)){
        return nil;
    }
    
    if ((mustMatch) && (![jsonNumber isEqualToNumber:templateNumber])){
        domain = str(@"Number by key(%@) from json not matches with templete value(%@))",key,templateNumber);
        [userInfoArray addObject:domain];
    }
    
    // BOOL is not validated further
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
 The method accepts a 'Class' object and returns the superclass name cast to one standard.
 For example, a situation may arise that in other dictionaries, strings can be represented by different classes
 ('__NSCFString' and 'NSString').
 Therefore, the class manages all exceptions, and always returns the class names from Foundation.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) typeSuperClassName:(Class)superClass
{
    NSString* superClassName = NSStringFromClass(superClass);
    
    // Exceptions
    if (([superClassName isEqualToString:@"__NSCFString"]) || ([superClassName isEqualToString:@"NSMutableString"])){
        return @"NSString";
    }
    
    // Further here you can write support for other classes ...
    return superClassName;
}


/*--------------------------------------------------------------------------------------------------------------
 Returns a dictionary with rules (if any) for a specific key from a common json
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
 Removes all rules from the dictionary and from its nested structures.
 This is required in cases when the "mustMatch" key has a whole dictionary from the template, which has
 rules for their nested objects.
 
 In order for the algorithm to correctly compare the server response and the template, all 'rules' must be removed from the latter.
 --------------------------------------------------------------------------------------------------------------*/

+ (NSDictionary* _Nullable) removeAllRulesFromDictionaryAndNastedStructure:(NSDictionary*)dictionary
{
    NSMutableDictionary* mutableCopy = [dictionary mutableCopy];
    
    // We go through the entire dictionary through its keys
    for (NSString* key in [mutableCopy allKeys]) {
        
        // If the key contains this suffix, then the value is a dictionary with rules, then we delete it immediately.
        if ([key rangeOfString:@"-Rules"].location != NSNotFound){
            [mutableCopy removeObjectForKey:key];
            continue;
        }
        // If the value by key is some kind of dictionary, then we call the method recursively, let it clean up and return a clean one.
        if ([mutableCopy[key] isKindOfClass:[NSDictionary class]]){
            mutableCopy[key] = [Validator removeAllRulesFromDictionaryAndNastedStructure:mutableCopy[key]];
            continue;
        }
        // If the value by key is an array, then we also call the method and let it return us a readable array
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
 
  This requires deleting all rules in nested objects.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSArray* _Nullable) removeAllRulesFromArrayAndNastedStructure:(NSArray*)array
{
    NSMutableArray* mutableCopy = [array mutableCopy];
    
    // Array for storing indexes of dictionaries
    NSMutableArray<NSNumber*>* dictionariesIndexes = [NSMutableArray new];
    
    // Array for storing dictionaries
    NSMutableArray<NSDictionary*>* dictionaries    = [NSMutableArray new];
    
    
    // We go through the array, determine if the current object is a dictionary.
    // Then we enter the information into (dictionariesIndexes и dictionaries).
    for (NSInteger i=0; i<=mutableCopy.count-1; i++) {
        
        id value = mutableCopy[i];
        if ([value isKindOfClass:[NSDictionary class]]){
            [dictionaries        addObject:value];
            [dictionariesIndexes addObject:[NSNumber numberWithInteger:i]];
        }
    }
    
    //We go through the array that contains dictionaries
    for (NSInteger i=0; i<=dictionaries.count-1; i++) {
        
        // We take a dictionary
        NSDictionary* dictionary = dictionaries[i];
        // We take its ordinal index in the mutableCopy array (!)
        NSInteger         index  = [dictionariesIndexes[i] integerValue];
        
        // Call the dictionaries cleanup method
        NSDictionary* newDict = [Validator removeAllRulesFromDictionaryAndNastedStructure:dictionary];
        // Place the cleaned-up dictionary by index into the main array
        mutableCopy[index] = newDict;
    }
    return mutableCopy;
}


/*--------------------------------------------------------------------------------------------------------------
  Returns an array of strings with all characters converted to small case.
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
