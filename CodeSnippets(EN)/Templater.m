//
//  Templater.m
//  vk-networkLayer
//
//  Created by Admin on 06/08/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "Templater.h"
// APIManager's Categories
#import "APIManager+Utilites.h"

// Own Categories
#import "TemplaterFileManager.h"

// Thrid-party frameworks
#import <RXZipArchive/RXZipArchive.h>

// Ключи для NSUserDefualt
static NSString *const templateDirectoryUserDefaultKey   = @"templateDirectoryUserDefaultKey";
static NSString *const wasArchiveExtractedUserDefaultKey = @"wasArchiveExtractedUserDefaultKey";


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



@interface Templater ()

/*--------------------------------------------------------------------------------------------------------------
 The variable contains the path to the 'APIManagerResponseTemplates' folder on the device drive.
 The first time you call the variable, the internal algorithm will automatically create a folder on disk.
 If you want to move the folder to a different location, call the setNewPathToTemplateDirectory method:
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, readwrite, class) NSString* pathToTemplateDirectory;

/*--------------------------------------------------------------------------------------------------------------
 The dictionary contains the early loaded json files using the apiMethod keys.
 After the first boot from disk, the template is automatically added to the dictionary.
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, class) NSMutableDictionary<NSString*,NSDictionary*>* templates;

/*--------------------------------------------------------------------------------------------------------------
 Serial queue that does not allow changes to the value in property 'pathToTemplateDirectory'
 and then moving the folder with templates to another directory.
 The methods listed below execute their code inside the block that is inserted into this queue.
 
 +templateForAPIMethod:
 +writeTemplate:forAPIMethod:
 +removeTemplateForAPIMethod:
 +removeAllTemplates:
 --------------------------------------------------------------------------------------------------------------*/
@property (nonatomic, strong, class) dispatch_queue_t serialDispatchQueue;

@end


static NSMutableDictionary *_templates               = nil;
static NSString            *_pathToTemplateDirectory = nil;
static dispatch_queue_t     _serialDispatchQueue     = nil;
static BOOL                 _loadTemplateFromBundle  = NO;

@implementation Templater


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 .___________. _______ .___  ___. .______    __          ___   .___________. _______     _______.
 |           ||   ____||   \/   | |   _  \  |  |        /   \  |           ||   ____|   /       |
 `---|  |----`|  |__   |  \  /  | |  |_)  | |  |       /  ^  \ `---|  |----`|  |__     |   (----`
     |  |     |   __|  |  |\/|  | |   ___/  |  |      /  /_\  \    |  |     |   __|     \   \
     |  |     |  |____ |  |  |  | |  |      |  `----./  _____  \   |  |     |  |____.----)   |
     |__|     |_______||__|  |__| | _|      |_______/__/     \__\  |__|     |_______|_______/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Templates

/*--------------------------------------------------------------------------------------------------------------
Recovers a previously written json file from disk or returns it from RAM memory.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) templateForAPIMethod:(APIMethod)method
{
    __block NSDictionary* template = nil;
    
    dispatch_sync(self.serialDispatchQueue, ^{

        if (method == APIMethod_Unknow){
            return;
        }
        NSString* apiMethod = [APIManager convertAPIMethodToString:method];

        // If the template was previously initialized from disk, then we try to get it from RAM
           template = self.templates[apiMethod];
        if (template) return;
        
        NSData* data =  nil;
       
        if (self.loadTemplateFromBundle){
            // Load from Bundle
            NSString *localPathBundle = [[NSBundle mainBundle] pathForResource:apiMethod ofType:@"json"];
            data = [NSData dataWithContentsOfFile:localPathBundle];
        } else {
           //  Load from disk
            NSString* localPath = [NSString stringWithFormat:@"%@/%@.json",self.pathToTemplateDirectory,apiMethod];
           data = [NSData dataWithContentsOfFile:localPath];
        }
        
        if (!data) return;
        
        NSError* error;
        template = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error){
            NSLog(@"+templateForAPIMethod recovered invalid error from disk. By APIMethod(%@)| error: %@",apiMethod,error);
        }
        // put in RAM memory
        if ((template) && (!error)){
            [self.templates setObject:template forKey:apiMethod];
        }
    });
    return template;
}


/*--------------------------------------------------------------------------------------------------------------
   Writes a sample file named method API
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) writeTemplate:(NSDictionary*)template forAPIMethod:(APIMethod)method
{
    __block NSError* error = nil;

    dispatch_sync(self.serialDispatchQueue, ^{

        if ((method == APIMethod_Unknow) || (template.allKeys.count < 1)){
            error = [NSError errorWithDomain:@"template or apiMethod in +writeTemplate:forAPIMethod: is incorrect" code:0 userInfo:nil];
            return;
        }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:template
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];

        if (error) return;
    
        NSString* apiMethod = [APIManager convertAPIMethodToString:method];
        NSString* localPath = [NSString stringWithFormat:@"%@/%@.json",self.pathToTemplateDirectory,apiMethod];

        [jsonData writeToFile:localPath atomically:YES];
        
 
        // If a sample was already stored by the 'apiMethod' key in the 'templates' dictionary, then it needs to be updated
        if (self.templates[apiMethod]){
            self.templates[apiMethod] = template;
        }
    });
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
Removes sample file from disk and from RAM by method API name
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeTemplateForAPIMethod:(APIMethod)method
{
    __block NSError* error = nil;

    dispatch_sync(self.serialDispatchQueue, ^{
        
        if (method == APIMethod_Unknow){
            error = [NSError errorWithDomain:@"apiMethod in +removeTemplateForAPIMethod: is incorrect" code:0 userInfo:nil];
            return;
        }
        NSString* apiMethod = [APIManager convertAPIMethodToString:method];
        
        // Remove from disk
        NSString* localPath = [NSString stringWithFormat:@"%@/%@.json",self.pathToTemplateDirectory,apiMethod];
        [TemplaterFileManager removeItemAtPath:localPath error:&error];

        // Remove from RAM
        [self.templates removeObjectForKey:apiMethod];
    });
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
  Allows you to safely delete a folder with all templates at the same time
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeAllTemplates
{
    __block NSError* error = nil;
    dispatch_sync(self.serialDispatchQueue, ^{
        [TemplaterFileManager removeItemAtPath:self.pathToTemplateDirectory error:&error];
    });
    return error;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______.     ___      .__   __.  _______  .______     ______   ___   ___
     /       |    /   \     |  \ |  | |       \ |   _  \   /  __  \  \  \ /  /
    |   (----`   /  ^  \    |   \|  | |  .--.  ||  |_)  | |  |  |  |  \  V  /
     \   \      /  /_\  \   |  . `  | |  |  |  ||   _  <  |  |  |  |   >   <
 .----)   |    /  _____  \  |  |\   | |  '--'  ||  |_)  | |  `--'  |  /  .  \
 |_______/    /__/     \__\ |__| \__| |_______/ |______/   \______/  /__/ \__\
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Sandbox

/*--------------------------------------------------------------------------------------------------------------
 Creates a folder if it does not exist at the given path
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) createFolderIfItDoesntExitByPath:(NSString*)pathToFolder
{
    if ([TemplaterFileManager isDirectoryItemAtPath:pathToFolder]){
        return nil;
    }
    
    NSError *error = nil;
    [TemplaterFileManager createDirectoriesForPath:pathToFolder error:&error];
    NSLog(@"createFolderIfItDoesntExitByPath error: %@",error);
    return error;
}

/*--------------------------------------------------------------------------------------------------------------
  Moves the 'APIManagerResponseTemplates' folder to a new location
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) replaceTemplateDirectoryAtPath:(NSString*)path
{
    NSError* error;
   [TemplaterFileManager moveItemAtPath:self.pathToTemplateDirectory toPath:path error:&error];
    NSLog(@"replaceTemplateDirectoryAtPath error: %@",error);
    return error;
}




#pragma mark - Getter Setter

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
   _______  _______ .___________.___________. _______ .______
  /  _____||   ____||           |           ||   ____||   _  \
 |  |  __  |  |__   `---|  |----`---|  |----`|  |__   |  |_)  |
 |  | |_ | |   __|      |  |        |  |     |   __|  |      /
 |  |__| | |  |____     |  |        |  |     |  |____ |  |\  \----.
  \______| |_______|    |__|        |__|     |_______|| _| `._____|
      _______. _______ .___________.___________. _______ .______
     /       ||   ____||           |           ||   ____||   _  \
    |   (----`|  |__   `---|  |----`---|  |----`|  |__   |  |_)  |
     \   \    |   __|      |  |        |  |     |   __|  |      /
 .----)   |   |  |____     |  |        |  |     |  |____ |  |\  \----.
 |_______/    |_______|    |__|        |__|     |_______|| _| `._____|
 
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark - Support classes properties

/*--------------------------------------------------------------------------------------------------------------
 @property (nonatomic, assign, class) BOOL loadTemplateFromBundle;
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL)loadTemplateFromBundle{
    return _loadTemplateFromBundle;
}

+ (void)setLoadTemplateFromBundle:(BOOL)loadTemplateFromBundle
{
    _loadTemplateFromBundle = loadTemplateFromBundle;
}


/*--------------------------------------------------------------------------------------------------------------
 @property (nonatomic, strong, class) dispatch_queue_t serialDispatchQueue;
 --------------------------------------------------------------------------------------------------------------*/
+ (dispatch_queue_t)serialDispatchQueue
{
    if (!_serialDispatchQueue){
         _serialDispatchQueue = dispatch_queue_create("Templater.serial.aSyncQueue", NULL);
    }
    return _serialDispatchQueue;
}

+ (void)setSerialDispatchQueue:(dispatch_queue_t)serialDispatchQueue
{
    _serialDispatchQueue = serialDispatchQueue;
}

/*--------------------------------------------------------------------------------------------------------------
 @property (nonatomic, strong, class) NSMutableDictionary<NSString*,NSDictionary*>* templates;
 --------------------------------------------------------------------------------------------------------------*/
+ (NSMutableDictionary<NSString *,NSDictionary *> *)templates {
    
    if (!_templates){
         _templates = [NSMutableDictionary new];
    }
    return _templates;
}

+ (void)setTemplates:(NSMutableDictionary<NSString *,NSDictionary *> *)templates {
    _templates = templates;
}


/*--------------------------------------------------------------------------------------------------------------
 The method allows you to change the location of the folder with templates.
 The 'dispatch_barrier_sync' block allows you to first wait for all other operations to complete, and then execute
 renaming.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) setNewPathToTemplateDirectory:(NSString*)path
{
    dispatch_barrier_sync(self.serialDispatchQueue, ^{
        [self setPathToTemplateDirectory:path];
    });
}

/*--------------------------------------------------------------------------------------------------------------
 @property (nonatomic, strong, class) NSString* pathToTemplateDirectory;
 --------------------------------------------------------------------------------------------------------------*/

+ (NSString *)pathToTemplateDirectory
{
    // Recovers from UserDefault
    if ((!_pathToTemplateDirectory) && ([Templater shortPathFromUserDefault].length > 0)) {
          _pathToTemplateDirectory = [Templater fullPathFromUserDefault];
    }
    
    // If there was nothing in UserDefault, then set the default value and write
    if (!_pathToTemplateDirectory){
        
        NSString* pathToLibraryCaches = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,YES) firstObject];
        NSString* pathToFolder = [pathToLibraryCaches stringByAppendingPathComponent:@"/APIManagerResponseTemplates"];

        [Templater saveAnyPathToUserDefault:pathToFolder];
        _pathToTemplateDirectory = pathToFolder;
    }
    
    if ((_pathToTemplateDirectory) && (![TemplaterFileManager existsItemAtPath:_pathToTemplateDirectory])){
        [self createFolderIfItDoesntExitByPath:_pathToTemplateDirectory];
    }
    
    return _pathToTemplateDirectory;
}


/*--------------------------------------------------------------------------------------------------------------
 The whole path BEFORE the folder should come here, for example:
 '/Users/Containers/Data/Application/.../Library/' the name 'APIManagerResponseTemplates' will be substituted automatically.
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setPathToTemplateDirectory:(NSString*)pathToTemplateDirectory
{
    if (pathToTemplateDirectory.length < 1){
        _pathToTemplateDirectory = nil;
        return;
    }

    NSString* fullPath        = [Templater buildFullPathFrom:pathToTemplateDirectory];
    NSString* shortPathFromUD = [Templater shortPathFromUserDefault];
    
    // If the property already matters
    if ((_pathToTemplateDirectory.length > 0) && (fullPath.length > 0))
    {
        // Then we check that the values are not the same
        if ([_pathToTemplateDirectory isEqualToString:fullPath]){
            //If the values are the same, then we interrupt the execution
            return;
        } else {
            // If the values are different. Then:
            // 1. Move a folder from an old location to a new one
            // 2. Write new path to UserDefault
            NSError* error = [Templater replaceTemplateDirectoryAtPath:fullPath];
            //[TemplaterFileManager moveItemAtPath:_pathToTemplateDirectory toPath:fullPath error:&error];
            if (error) NSLog(@"error: %@",error);
            else {
                //and write the new value to UserDefault
                [Templater saveAnyPathToUserDefault:fullPath];
            }
            _pathToTemplateDirectory = fullPath;
        }
        return;
    }

    // If there was something in UserDefault. And the value from the argument is completely indeterminate, then we set the value and exit
    if ([[Templater cutShortPathFrom:fullPath] isEqualToString:[Templater shortPathFromUserDefault]])
    {
        _pathToTemplateDirectory = fullPath;
        return;
    }

    
    // If UserDefault is empty
    if (shortPathFromUD.length < 1){
        //Create a folder
        [self createFolderIfItDoesntExitByPath:fullPath];

    // If there was something in UserDefault, then just move it to a new location
    } else if ((shortPathFromUD.length > 1) && (![shortPathFromUD isEqualToString:[Templater cutShortPathFrom:fullPath]])) {
       
        NSError* error = [Templater replaceTemplateDirectoryAtPath:fullPath];
        if (error) NSLog(@"error: %@",error);
        
    }
    // We write the value
    [Templater saveAnyPathToUserDefault:fullPath];
    
    //Set the value to property
    _pathToTemplateDirectory = fullPath;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______.___________..______       __  .__   __.   _______      _______.
     /       |           ||   _  \     |  | |  \ |  |  /  _____|    /       |
    |   (----`---|  |----`|  |_)  |    |  | |   \|  | |  |  __     |   (----`
     \   \       |  |     |      /     |  | |  . `  | |  | |_ |     \   \
 .----)   |      |  |     |  |\  \----.|  | |  |\   | |  |__| | .----)   |
 |_______/       |__|     | _| `._____||__| |__| \__|  \______| |_______/
 
  __        ______     _______  __    ______
 |  |      /  __  \   /  _____||  |  /      |
 |  |     |  |  |  | |  |  __  |  | |  ,----'
 |  |     |  |  |  | |  | |_ | |  | |  |
 |  `----.|  `--'  | |  |__| | |  | |  `----.
 |_______| \______/   \______| |__|  \______|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Strings / Logics / UserDefault

/*--------------------------------------------------------------------------------------------------------------
 The method unpacks an archive with a folder of standard json files (responses from the server).
 If you specify nil in the 'atPath' argument, then the algorithm will automatically unzip the folder to the 'Templater.pathToTemplateDirectory' path.
 You can call this method every time you start the application inside the +APIManager.prepareBeforeUsing: method,
 inside built-in protection against repeated unzipping.
 --------------------------------------------------------------------------------------------------------------*/

+ (void) unarchiveFolderWithDefaultTemplates:(nullable NSString*)atPath
                                  completion:(nullable void(^)(NSError* error))completion
{
    // Check if the archive was previously unzipped
    BOOL wasZipExtractedEarly = [[NSUserDefaults standardUserDefaults] boolForKey:wasArchiveExtractedUserDefaultKey];
    if (wasZipExtractedEarly){
        return;
    }
    
    // Set the path where the unzip will be performed
    if (atPath.length < 1){
        atPath = Templater.pathToTemplateDirectory;
    } else {
        [Templater setNewPathToTemplateDirectory:atPath];
    }
    
    // Delete the folder name at the end of the line
    atPath = [Templater removeDefaultFolderNameToPathIfItNeeded:atPath];
    
    // We are looking for the path to the archive in the bundle of the application
    NSString *localPathAtZip = [[NSBundle mainBundle] pathForResource:@"APIManagerResponseDefaultTemplates" ofType:@"zip"];
    if (localPathAtZip.length < 1){
        if (completion)
            completion([NSError errorWithDomain:@"APIManagerResponseDefaultTemplates.zip wasn't find in bundle" code:0 userInfo:nil]);
        return;
    }
    
    // Unzip the archive
    [SSZipArchive unzipFileAtPath:localPathAtZip
                    toDestination:atPath
                  progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                      
                  } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable errorUnpackZip) {
                      
                      if (errorUnpackZip){
                          if (completion) { completion(errorUnpackZip); };
                      }else if (succeeded){
                          if (completion) completion(nil);
                          
                          // We write down the flag indicating that the unpacking was carried out
                          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:wasArchiveExtractedUserDefaultKey];
                          [[NSUserDefaults standardUserDefaults] synchronize];
                      }
    }];
}



/*--------------------------------------------------------------------------------------------------------------
  Cuts the long path by returning only 'Documents / API Manager Response Templates'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) cutShortPathFrom:(NSString*)fullPath
{
    if (fullPath.length < 1) return nil;
    
    fullPath = [Templater appendDefaultFolderNameToPathIfItNeeded:fullPath];
    
    NSRange  range = [fullPath rangeOfString:NSHomeDirectory()];
    if (range.location == NSNotFound) return fullPath;
    NSString* pathToTemplateDirFromHomeDir = [fullPath substringFromIndex:range.length+1];
    
    return pathToTemplateDirFromHomeDir;
}


/*--------------------------------------------------------------------------------------------------------------
 Concatenates the NSHomeDirectory () string with 'Documents / APIManagerResponseTemplates' (if required), and returns
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) buildFullPathFrom:(NSString*)shortPath
{
    if (shortPath.length < 1) return nil;

    shortPath = [Templater appendDefaultFolderNameToPathIfItNeeded:shortPath];
    
    NSRange  range = [shortPath rangeOfString:NSHomeDirectory()];
    if (range.location != NSNotFound) return shortPath;
    
    
    NSString* fullPath = [NSHomeDirectory() stringByAppendingPathComponent:shortPath];
    return fullPath;
}

/*--------------------------------------------------------------------------------------------------------------
 Adds the folder name 'APIManagerResponseTemplates' to the passed path (if it is not there)
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) appendDefaultFolderNameToPathIfItNeeded:(NSString*)path
{
    if (path.length < 1) return nil;

    NSRange templateFolder_range = [path rangeOfString:@"/APIManagerResponseTemplates"];
    if (templateFolder_range.location == NSNotFound){
        path = [path stringByAppendingPathComponent:@"/APIManagerResponseTemplates"];
    }
    return path;
}

/*--------------------------------------------------------------------------------------------------------------
 Removes the name of the folder 'APIManagerResponseTemplates' to the given path (if it is present there)
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) removeDefaultFolderNameToPathIfItNeeded:(NSString*)path
{
    if (path.length < 1) return nil;
    
    NSRange templateFolder_range = [path rangeOfString:@"/APIManagerResponseTemplates"];
    if (templateFolder_range.location != NSNotFound){
        path = [path substringToIndex:templateFolder_range.location];
    }
    return path;
}



/*--------------------------------------------------------------------------------------------------------------
 Saves the path to UserDefault. Can accept any modification of shortPath / fullPath
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) saveAnyPathToUserDefault:(NSString*)path
{
    if (path.length < 1) return NO;

    path = [Templater appendDefaultFolderNameToPathIfItNeeded:path];
    path = [Templater cutShortPathFrom:path];
    
    // Write valu
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:templateDirectoryUserDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}

/*--------------------------------------------------------------------------------------------------------------
  Extracts from UserDefault and returns the short string 'Documents / APIManagerResponseTemplates'.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) shortPathFromUserDefault
{
    return  [[NSUserDefaults standardUserDefaults] stringForKey:templateDirectoryUserDefaultKey];
}


/*--------------------------------------------------------------------------------------------------------------
 Retrieves the short string 'Documents / APIManagerResponseTemplates' from UserDefault.
 Modifies 'NSHomeDirectory ()' + 'Documents / APIManagerResponseTemplates' and returns the full path
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) fullPathFromUserDefault
{
    NSString* path = [Templater shortPathFromUserDefault];
    NSString* full = [Templater buildFullPathFrom:path];
    return full;
}


@end
