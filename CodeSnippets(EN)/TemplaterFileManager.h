//
//  FCFileManager.h
//
//  Created by Fabio Caccamo on 28/01/14.
//  Copyright (c) 2014 Fabio Caccamo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*--------------------------------------------------------------------------------------------------------------
  🗃 'TemplaterFileManager' - a class that works with the sandbox. Original name 'FCFileManager'.
     The name was changed to prevent name conflicts with other libraries.
 --------------------------------------------------------------------------------------------------------------*/

@interface TemplaterFileManager : NSObject

+(id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key;
+(id)attributeOfItemAtPath:(NSString *)path forKey:(NSString *)key error:(NSError **)error;

+(NSDictionary *)attributesOfItemAtPath:(NSString *)path;
+(NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath;
+(BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath error:(NSError **)error;

+(BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite;
+(BOOL)copyItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite error:(NSError **)error;

+(BOOL)createDirectoriesForFileAtPath:(NSString *)path;
+(BOOL)createDirectoriesForFileAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)createDirectoriesForPath:(NSString *)path;
+(BOOL)createDirectoriesForPath:(NSString *)path error:(NSError **)error;

+(BOOL)createFileAtPath:(NSString *)path;
+(BOOL)createFileAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)createFileAtPath:(NSString *)path overwrite:(BOOL)overwrite;
+(BOOL)createFileAtPath:(NSString *)path overwrite:(BOOL)overwrite error:(NSError **)error;

+(BOOL)createFileAtPath:(NSString *)path withContent:(NSObject *)content;
+(BOOL)createFileAtPath:(NSString *)path withContent:(NSObject *)content error:(NSError **)error;

+(BOOL)createFileAtPath:(NSString *)path withContent:(NSObject *)content overwrite:(BOOL)overwrite;
+(BOOL)createFileAtPath:(NSString *)path withContent:(NSObject *)content overwrite:(BOOL)overwrite error:(NSError **)error;

+(NSDate *)creationDateOfItemAtPath:(NSString *)path;
+(NSDate *)creationDateOfItemAtPath:(NSString *)path error:(NSError **)error;

+(NSDate *)modificationDateOfItemAtPath:(NSString *)path;
+(NSDate *)modificationDateOfItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)emptyCachesDirectory;
+(BOOL)emptyTemporaryDirectory;

+(BOOL)existsItemAtPath:(NSString *)path;

+(BOOL)isDirectoryItemAtPath:(NSString *)path;
+(BOOL)isDirectoryItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)isEmptyItemAtPath:(NSString *)path;
+(BOOL)isEmptyItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)isFileItemAtPath:(NSString *)path;
+(BOOL)isFileItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)isExecutableItemAtPath:(NSString *)path;
+(BOOL)isReadableItemAtPath:(NSString *)path;
+(BOOL)isWritableItemAtPath:(NSString *)path;

+(NSArray *)listDirectoriesInDirectoryAtPath:(NSString *)path;
+(NSArray *)listDirectoriesInDirectoryAtPath:(NSString *)path deep:(BOOL)deep;

+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path;
+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path deep:(BOOL)deep;

+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension;
+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension deep:(BOOL)deep;

+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix;
+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix deep:(BOOL)deep;

+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix;
+(NSArray *)listFilesInDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix deep:(BOOL)deep;

+(NSArray *)listItemsInDirectoryAtPath:(NSString *)path deep:(BOOL)deep;

+(BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath;
+(BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath error:(NSError **)error;

+(BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite;
+(BOOL)moveItemAtPath:(NSString *)path toPath:(NSString *)toPath overwrite:(BOOL)overwrite error:(NSError **)error;

+(NSString *)pathForApplicationSupportDirectory;
+(NSString *)pathForApplicationSupportDirectoryWithPath:(NSString *)path;

+(NSString *)pathForCachesDirectory;
+(NSString *)pathForCachesDirectoryWithPath:(NSString *)path;

+(NSString *)pathForDocumentsDirectory;
+(NSString *)pathForDocumentsDirectoryWithPath:(NSString *)path;

+(NSString *)pathForLibraryDirectory;
+(NSString *)pathForLibraryDirectoryWithPath:(NSString *)path;

+(NSString *)pathForMainBundleDirectory;
+(NSString *)pathForMainBundleDirectoryWithPath:(NSString *)path;

+(NSString *)pathForPlistNamed:(NSString *)name;

+(NSString *)pathForTemporaryDirectory;
+(NSString *)pathForTemporaryDirectoryWithPath:(NSString *)path;

+(NSString *)readFileAtPath:(NSString *)path;
+(NSString *)readFileAtPath:(NSString *)path error:(NSError **)error;

+(NSArray *)readFileAtPathAsArray:(NSString *)path;

+(NSObject *)readFileAtPathAsCustomModel:(NSString *)path;

+(NSData *)readFileAtPathAsData:(NSString *)path;
+(NSData *)readFileAtPathAsData:(NSString *)path error:(NSError **)error;

+(NSDictionary *)readFileAtPathAsDictionary:(NSString *)path;

+(NSJSONSerialization *)readFileAtPathAsJSON:(NSString *)path;
+(NSJSONSerialization *)readFileAtPathAsJSON:(NSString *)path error:(NSError **)error;

+(NSMutableArray *)readFileAtPathAsMutableArray:(NSString *)path;

+(NSMutableData *)readFileAtPathAsMutableData:(NSString *)path;
+(NSMutableData *)readFileAtPathAsMutableData:(NSString *)path error:(NSError **)error;

+(NSMutableDictionary *)readFileAtPathAsMutableDictionary:(NSString *)path;

+(NSString *)readFileAtPathAsString:(NSString *)path;
+(NSString *)readFileAtPathAsString:(NSString *)path error:(NSError **)error;

+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path;
+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension;
+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withExtension:(NSString *)extension error:(NSError **)error;

+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix;
+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withPrefix:(NSString *)prefix error:(NSError **)error;

+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix;
+(BOOL)removeFilesInDirectoryAtPath:(NSString *)path withSuffix:(NSString *)suffix error:(NSError **)error;

+(BOOL)removeItemsInDirectoryAtPath:(NSString *)path;
+(BOOL)removeItemsInDirectoryAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)removeItemAtPath:(NSString *)path;
+(BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;

+(BOOL)renameItemAtPath:(NSString *)path withName:(NSString *)name;
+(BOOL)renameItemAtPath:(NSString *)path withName:(NSString *)name error:(NSError **)error;

+(NSString *)sizeFormatted:(NSNumber *)size;

+(NSString *)sizeFormattedOfDirectoryAtPath:(NSString *)path;
+(NSString *)sizeFormattedOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

+(NSString *)sizeFormattedOfFileAtPath:(NSString *)path;
+(NSString *)sizeFormattedOfFileAtPath:(NSString *)path error:(NSError **)error;

+(NSString *)sizeFormattedOfItemAtPath:(NSString *)path;
+(NSString *)sizeFormattedOfItemAtPath:(NSString *)path error:(NSError **)error;

+(NSNumber *)sizeOfDirectoryAtPath:(NSString *)path;
+(NSNumber *)sizeOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

+(NSNumber *)sizeOfFileAtPath:(NSString *)path;
+(NSNumber *)sizeOfFileAtPath:(NSString *)path error:(NSError **)error;

+(NSNumber *)sizeOfItemAtPath:(NSString *)path;
+(NSNumber *)sizeOfItemAtPath:(NSString *)path error:(NSError **)error;

+(NSURL *)urlForItemAtPath:(NSString *)path;

+(BOOL)writeFileAtPath:(NSString *)path content:(NSObject *)content;
+(BOOL)writeFileAtPath:(NSString *)path content:(NSObject *)content error:(NSError **)error;

+(NSDictionary *)metadataOfImageAtPath:(NSString *)path;
+(NSDictionary *)exifDataOfImageAtPath:(NSString *)path;
+(NSDictionary *)tiffDataOfImageAtPath:(NSString *)path;

+(NSDictionary *)xattrOfItemAtPath:(NSString *)path;
+(NSString *)xattrOfItemAtPath:(NSString *)path getValueForKey:(NSString *)key;
+(BOOL)xattrOfItemAtPath:(NSString *)path hasValueForKey:(NSString *)key;
+(BOOL)xattrOfItemAtPath:(NSString *)path removeValueForKey:(NSString *)key;
+(BOOL)xattrOfItemAtPath:(NSString *)path setValue:(NSString *)value forKey:(NSString *)key;

@end


/*--------------------------------------------------------------------------------------------------------------
 (🤙🏻🛠) Работа с Templater и  TemplaterFileManager. Пример использования:
 
 //==================================== Загрузка из bundle по NSString ========================================//
 
 NSString *path = [[NSBundle mainBundle] pathForResource:@"users.get" ofType:@"json"];
 NSData   *data = [NSData dataWithContentsOfFile:path];
 NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
 NSLog(@"json %@",json);
 
 //==================================== Загрузка из bundle по NSURL ========================================//
 
 NSURL  *urlForPath = [[NSBundle mainBundle] URLForResource:@"users.get" withExtension:@"json"];
 NSData *data       = [NSData dataWithContentsOfURL:urlForPath];
 NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
 NSLog(@"json %@",json);
 
 //======================= Разархивирование APIManagerResponseDefaultTemplates.zip  =========================//
 
 [Templater unarchiveFolderWithDefaultTemplates:nil completion:^(NSError * _Nonnull error) {
     if (error) NSLog(@"error: %@",error);
     else NSLog(@"Все нормально");
 }];
 
 //==================================== Запись  ========================================//
 
 NSDictionary* myPrettyJSON = @{@"Hello" : @"World"};
 
 NSDictionary* recoveredJSON = [Templater templateForAPIMethod:APIMethod_UserGet];
 NSLog(@"recoveredJSON: %@",recoveredJSON);
 
 
 NSError* errorWriting = [Templater writeTemplate:myPrettyJSON forAPIMethod:APIMethod_UserGet];
 if (errorWriting){
    NSLog(@"errorWriting: %@",errorWriting);
 }
 
 recoveredJSON = [Templater templateForAPIMethod:APIMethod_UserGet];
 NSLog(@"recoveredJSON: %@",recoveredJSON);
 
 //==================================== Перемещение  ========================================//
 
 // Распечатываем текущий путь
 NSLog(@"Текущий путь: %@",Templater.pathToTemplateDirectory);
 
 // Меняем путь
 // NSDocumentDirectory NSLibraryDirectory
 NSString* pathToLibraryCaches = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES) firstObject];
 
 // !! В перемещении ошибка!
 [Templater setNewPathToTemplateDirectory:pathToLibraryCaches];
 
 // Проверяем изменился ли путь и фактический переместились ли папки
 NSLog(@"Изменнный путь: %@",Templater.pathToTemplateDirectory);
 
 //==================================== Удаление  ========================================//
 
 
 //NSError* error = [Templater removeTemplateForAPIMethod:APIMethod_UserGet];
 //NSError* error = [Templater removeAllTemplates];
 
 if (error){
    NSLog(@"error: %@",error);
 }
 --------------------------------------------------------------------------------------------------------------*/
