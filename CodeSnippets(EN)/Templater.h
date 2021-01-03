//
//  Templater.h
//  vk-networkLayer
//
//  Created by Admin on 06/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIMethods.h"


NS_ASSUME_NONNULL_BEGIN

/*--------------------------------------------------------------------------------------------------------------
 🖨🧾 'Templater' - restores sample server responses in .json format from the device disk.
 ---------------
 The main task is to provide the user with NSDictionary instances initialized using json files
 stored on disk.
 ---------------
 [⚖️] Duties:
 - Interact with the 'TemplaterFileManager' class that manages the sandbox.
 - Write / Read values from NSUserDefault.
 - Work with strings (editing paths for folders in the sandbox).
 ---------------
 The class provides the following features:
 - Initialize dictionaries from json files located in the application sandbox.
 - Sandbox templates by the API name of the request method.
 - Remove a specific template by the API name of the method that was requested.
 - Delete all templates from disk.
 - Ability to safely move the template folder to other locations.
 ---------------
 Additionally:
 (⚠️) The architecture of the class was planned in such a way that while using the application, it was possible to
      dynamically add new and change old templates.
     This feature is available only when working with a sandbox, since you cannot add files to the application bundle with code.
 
 This leads to the following problem, - "Where should Templater take files for the Validator, if the just downloaded
 does the app from the AppStore have a clean sandbox? "
 
 One possible solution could be to save a template archive with the name 'APIManagerResponseDefaultTemplates.zip'
 in the bundle of the application, and then during the first launch, you need to call the unarchiveFolderWithDefaultTemplates: .. method,
 which will unzip the folder to the desired directory (by default in 'pathToTemplateDirectory').
 
 In the subsequent use of the application, you get json files from disk, and also modify them.
 --------------------------------------------------------------------------------------------------------------*/


@interface Templater : NSObject

/*--------------------------------------------------------------------------------------------------------------
 Returns the address to the folder that contains the template files.
 If you change the value of the folder, then the folder along with the files will move to another location.
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, readonly, class) NSString* pathToTemplateDirectory;


/*--------------------------------------------------------------------------------------------------------------
 The default is 'NO'. If you replace it with 'YES', then the required file will be searched for in the bundle of the application.
 --------------------------------------------------------------------------------------------------------------*/
@property (nonatomic, assign, class) BOOL loadTemplateFromBundle;

#pragma mark - Methods

/*--------------------------------------------------------------------------------------------------------------
 Allows you to safely change the location of the templates folder.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) setNewPathToTemplateDirectory:(NSString*)path;

/*--------------------------------------------------------------------------------------------------------------
 Recovers a previously written json file from disk or returns it from RAM memory.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) templateForAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
  Writes a sample file named method API
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) writeTemplate:(NSDictionary*)template forAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
 Removes sample file from disk and from RAM by method API name
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeTemplateForAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
  Allows you to safely delete a folder with all templates at the same time
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeAllTemplates;


/*--------------------------------------------------------------------------------------------------------------
 The method unpacks an archive with a folder of standard json files (responses from the server).
 If you specify nil in the 'atPath' argument, then the algorithm will automatically unzip the folder to the 'Templater.pathToTemplateDirectory' path.
 You can call this method every time you start the application inside the +APIManager.prepareBeforeUsing: method,
 inside built-in protection against repeated unzipping.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) unarchiveFolderWithDefaultTemplates:(nullable NSString*)atPath
                                  completion:(nullable void(^)(NSError* error))completion;

@end

NS_ASSUME_NONNULL_END
