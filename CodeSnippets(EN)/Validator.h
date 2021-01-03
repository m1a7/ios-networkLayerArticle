//
//  Validator.h
//  vk-networkLayer
//
//  Created by Admin on 03/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIMethods.h"

NS_ASSUME_NONNULL_BEGIN


/*--------------------------------------------------------------------------------------------------------------
  The bitmask contains the settings by which the server response will be validated.
 --------------------------------------------------------------------------------------------------------------*/
typedef NS_OPTIONS(NSUInteger, ResponseValidationMask) {
    
    CheckOnKeys           = 1 << 0, // Checks for the keys from the template in the received json from the server
    CheckSubEntityOnKeys  = 1 << 1, // Checks for keys from a template in nested structures
    CheckOnTypesOfValues  = 1 << 2, // Checks the correspondence of data types by keys
    CheckOnExtendedRules  = 1 << 3, // Checks for rules (if they were listed in the template)
    
    AllChecks = CheckOnKeys | CheckSubEntityOnKeys | CheckOnTypesOfValues | CheckOnExtendedRules
};


/*--------------------------------------------------------------------------------------------------------------
 🚦⚖️  'Validator' - validates responses received from the server
 ---------------
 The main task of the class is to find possible errors in the resulting file and notify the user about it.
 ---------------
 [⚖️] Duties:
 - Own responses from the server by API method keys.
 ---------------
 The class provides the following features:
 
 - You can pass a json + APIMethod pair to a generic method that will automatically determine the required validation
   method and will return the result to you.
 
 - The implementation of validation methods is entirely up to the developer's needs.
   You can write your own custom check here, and if you have a template, you can use the method automatic testing.
 ---------------
 Additionally:
 (⚠️) When using automatic validation, objects located in arrays are not subject to verification.
      If your response from the server returns you an array of objects, then to carry out validation to disk as
      template and always pass the object directly to the validator.
 --------------------------------------------------------------------------------------------------------------*/


@interface Validator : NSObject

#pragma mark - Shared Validation Methods
/*--------------------------------------------------------------------------------------------------------------
 The distributor method independently determines which validation method to call for json received by a specific API method
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponse:(NSDictionary*)recievedJSON fromAPIMethod:(APIMethod)method;



#pragma mark - Automatic Validation (for pair json + template)
/*--------------------------------------------------------------------------------------------------------------
 The automatic validation method verifies the received json and the sample from disk.
 If a mismatch is found, it returns an error.
 
 The standard validation procedure consists of several steps:
 1. Checking for the presence of all keys from the template in json.
 2. Checking for identical data types (so that there is one type for the same key).
 
 (Additionally)
 3. If the template contains validation "rules", they will also be executed.
    For example, you can validate a specific value from json for length, match, suffix, etc.
    To do this, the object you want to validate must have a rules dictionary with its name (eg: "age-Rules").
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) automaticValidateResponse:(NSDictionary*)recievedJSON
                                        template:(NSDictionary*)templateJSON
                                  validationMask:(ResponseValidationMask)mask
                                   fromAPIMethod:(APIMethod)method;




#pragma mark - Specified Validation Method (for specific API method)

/*--------------------------------------------------------------------------------------------------------------
  The method validates the server response to the "users.get" method request.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_usersGet:(NSDictionary*)recievedJSON;

/*--------------------------------------------------------------------------------------------------------------
 The method validates the server response to the request for the "wall.get" method.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_wallGet:(NSDictionary*)recievedJSON;

/*--------------------------------------------------------------------------------------------------------------
 The method validates the server response to the "photos.getAll" method request.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_photosGetAll:(NSDictionary*)recievedJSON;

/*--------------------------------------------------------------------------------------------------------------
 The method validates the server response to the "friends.get" method request.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) validateResponseFrom_friendsGet:(NSDictionary*)recievedJSON;

@end



/*--------------------------------------------------------------------------------------------------------------
 | 📄⚙️ Instructions for supporting extended validation parameters.
 ---------------------------------------------------------------------------------------------------------------
 | ✋🏻 Introduction: |
 ---------------
 
  If you want to validate the received response from the server with additional tools, then create in the template
  dictionary with rules. The key to the rules must contain the name of the validation object and the suffix '-Rules' at the end.
 
  Example:
  (Template.json)
  {
    ....
    "age" : 20,
    "age-Rules" : { "minimum" : 18,
                    "maximum" : 27
                    }
     ...
  }
 Having received this dictionary with rules, the algorithm will check the value so that it is in the range 18-27.
  -----------------------------------------------------------------------------------------------------------
 | 📚 General rules for all data types: |
 -------------------------------------------
 
  👉🏻 "isOptional" - (By default, the absence of a key from the template in the server response is perceived by the algorithm as an error).
                     A `true` for this key will tell the algorithm that the presence of a (key-value) pair for this `json` object - is optional.
 
  👉🏻 "mustMatch"  - The value `true` requires that the value of the variable from the template match the one that came from the server.
                    This key applies to all of the following data types (Strings/Numbers/Dictionaries/Arrays).
 
  Example:
  (Template.json)
  {
     "favouriteFilm"         : "Avatar 2010",
     "favouriteFilm-Rules" : {
                                "isOptional" : true
                              },
 
    "jurisdiction"       : "US",
    "jurisdiction-Rules" : {
                             "mustMatch" : true,
                           }
  }
 
  As we can see from the template below, the presence of a value for the `favoriteFilm` key in the response received from the server is optional.
  And the value for the `jurisdiction` key, not only must be present in the server's response, but the value must necessarily be equal
  to the value from the rules dictionary, that is, `US`.
 -----------------------------------------------------------------------------------------------------------
 | "🅰️🅱️" Strings: |
 ---------------
  The keys below validate only string values.
 
  👉🏻 "equalInLength"                  - Makes sure that the length of the string in the template and in json is the same.
  👉🏻 "lengthMustBeEqualOrGreaterThan" - The length of the value in json must be greater than or equal to this digit.
  👉🏻 "lengthMustBeEqualOrLessThan"    - The length of the value in json must be greater than or equal to this digit.
  👉🏻 "hasSuffix"                      - The value in json must contain this suffix.
  👉🏻 "matchWithOneOf"                 - The value in json must be indentical to one of the objects in the array.
 
 
  Example:
  (Template.json)
  {
   "crediCardPassCode"       : "4321",
   "crediCardPassCode-Rules" : {
                                 "equalInLength" : true
                                },
 
    "userPassword"       : "qwerty123",
    "userPassword-Rules" : {
                            "lengthMustBeEqualOrGreaterThan" : 6,
                            "lengthMustBeEqualOrLessThan"    : 20
                           },
 
    "rootClass"       : "NSObject",
    "rootClass-Rules" : {
                         "hasSuffix" : "NS"
                        }
 
   "continents"       : "Europe",
   "continents-Rules" : {
                         matchWithOneOf : ["Africa","Antarctica","Asia","Europe","North America","Australia","South America"]
                        }
 }
 
 -----------------------------------------------------------------------------------------------------------
 | [🍏 🍎 🍊] Arrays: |
 ---------------
 In addition to the basic keys (isOptional and mustMatch), arrays support two others.
 The example below shows the situation when the number of elements in the array is required to be in a certain range.

  👉🏻 "elementsMustBeEqualOrMoreThan" - The number of elements in the array must be greater than or equal to this number.
  👉🏻 "elementsMustBeEqualOrLessThan" - The number of elements in the array must be less than or equal to this number.
 
 Example:
 (Template.json)
 {
 
    "carWheels" : ["left-front", "right-front",
                   "left-rear",  "right-rear"],
 
   "carWheels-Rules" : {
                           "elementsMustBeEqualOrMoreThan" : 4,
                           "elementsMustBeEqualOrLessThan" : 6
                        }
 }
 
 -----------------------------------------------------------------------------------------------------------
 | 📖 Dictionaries: |
 --------------------
 By themselves, dictionaries can only have two basic validation parameters (isOptional and mustMatch), otherwise
 you need to set specific rules for each individual object within the dictionary.
 
  Example:
  (Template.json)
  {
   "platform"  :  {
                    "OS"     : "iOS",
                    "device" : "iPhone",
                    },
 
   "platform-Rules" : {
                        "isOptional" : true,
                        "mustMatch"  : true
                      }
  }
 
 The example above shows that the absence of the "platform" dictionary in the Jason that came from the server will
 not be considered an error, but if the dictionary is present, then it must be identical to the dictionary from the template.
 -----------------------------------------------------------------------------------------------------------
 | 1️⃣ 2️⃣ 3️⃣ Number: |
 --------------------
 As shown in the introduction, numeric values from json only support validation for min and
 maximum value.

  (⚠️) Booleans do not support validation. maximum value.
 -----------------------------------------------------------------------------------------------------------
 | 🛣🗿 Additionally: |
 -----------------------
 
 - If you have a json sample on disk, and a modified version comes from the server.
 Then there will be no errors if you do not change the structure of old objects, but simply add something else new.
 --------------------------------------------------------------------------------------------------------------*/



NS_ASSUME_NONNULL_END
