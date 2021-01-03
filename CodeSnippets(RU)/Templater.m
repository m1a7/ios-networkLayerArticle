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
 🖨🧾 'Templater' - восстанавливает образцы ответов сервера в формате .json с диска устройства.
 ---------------
 Главная задача предоставлять пользователю экземпляры NSDictionary инициализированные с помощью json файлов
 хранящихся на диске.
 ---------------
 [⚖️] Duties:
 - Взаимодействовать с классом 'TemplaterFileManager' который осуществляет управление песочницей.
 - Записывать/Читать значения из NSUserDefault.
 - Осуществлять работу со строками (редактирование путей для папок в песочнице).
 ---------------
 The class provides the following features:
 - Инициализировать словари из json файлов находящихся в песочнице приложения.
 - Записывать шаблоны в песочницу по имени API метода, по которому был совершен запрос.
 - Удалять конкретный шаблон, по имени API метода, по которому был совершен запрос.
 - Удалять все шаблоны с диска.
 - Возможность безопастно перемещать папку с шаблонами в другие лоакции.
 ---------------
 Additionally:
 (⚠️) Архитектура класса была спланирована таким образом, чтобы во время использования приложения, можно было
      динмачески добавлять новые и изменять старые шаблоны.
 Такая возможность имеется только при работе с песочницей, поскольку в bundle приложения файлы добавить кодом нельзя.
 
 Из этого следует следующая проблема, -"Откуда Templater должен брать файлы для Валидатора, если только что скаченное
 приложения из AppStore имеет чистую песочницу ?".
 
 Одним из возможных решения может быть сохранение архива шаблонов с именем 'APIManagerResponseDefaultTemplates.zip'
 в bundle приложения, а затем во время первого запуска нужно вызывать метод +unarchiveFolderWithDefaultTemplates:..,
 который разархивиет папку в нужную директорию (по умолчанию в 'pathToTemplateDirectory').
 
 В последующим использовании приложения вы получать json файлы с диска, а также модифицировать их.
 --------------------------------------------------------------------------------------------------------------*/


@interface Templater ()

/*--------------------------------------------------------------------------------------------------------------
 Переменная содержит путь к папке 'APIManagerResponseTemplates' на диске устройства.
 Если вы вызовите переменную впервый раз, то внутренний алгоритм автоматически создаст папку на диске.
 Если вы захотите переместить папку в другое место, вызовите метод +setNewPathToTemplateDirectory:
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, readwrite, class) NSString* pathToTemplateDirectory;

/*--------------------------------------------------------------------------------------------------------------
 Словарь содержит в себе ранне загруженные json файлы по ключам apiMethod.
 После первой загрузки с диска, шаблон автоматический добавлется в словарь.
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, class) NSMutableDictionary<NSString*,NSDictionary*>* templates;

/*--------------------------------------------------------------------------------------------------------------
 Последовательная очередь, которая непозволяет совершить изменения значения в проперти 'pathToTemplateDirectory'
 и последующего переноса папки с шаблонами в другую директорию.
 Методы перечисленные ниже выполняют свой код внутри блок который вставляется в данную очередь.
 
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
Восстанавливает ранее записанный json файл с диска или возвращает его из RAM памяти.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) templateForAPIMethod:(APIMethod)method
{
    __block NSDictionary* template = nil;
    
    dispatch_sync(self.serialDispatchQueue, ^{

        if (method == APIMethod_Unknow){
            return;
        }
        NSString* apiMethod = [APIManager convertAPIMethodToString:method];

        // Если шаблон ранее инициализировался с диска, то пытаемся достать его из RAM
           template = self.templates[apiMethod];
        if (template) return;
        
        NSData* data =  nil;
       
        if (self.loadTemplateFromBundle){
            // Загрузка с Bundle
            NSString *localPathBundle = [[NSBundle mainBundle] pathForResource:apiMethod ofType:@"json"];
            data = [NSData dataWithContentsOfFile:localPathBundle];
        } else {
           //  Загрузка с диска
            NSString* localPath = [NSString stringWithFormat:@"%@/%@.json",self.pathToTemplateDirectory,apiMethod];
           data = [NSData dataWithContentsOfFile:localPath];
        }
        
        if (!data) return;
        
        NSError* error;
        template = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error){
            NSLog(@"+templateForAPIMethod recovered invalid error from disk. By APIMethod(%@)| error: %@",apiMethod,error);
        }
        // Заносим в RAM память
        if ((template) && (!error)){
            [self.templates setObject:template forKey:apiMethod];
        }
    });
    return template;
}


/*--------------------------------------------------------------------------------------------------------------
 Записывает образец файла с именем API метода
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
        
 
        // Если по ключу 'apiMethod' в словаре 'templates' уже хранился образец,
        // то его нужно обновить
        if (self.templates[apiMethod]){
            self.templates[apiMethod] = template;
        }
    });
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Удаляет образец файла с диска и из RAM по имени API метода
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
        
        // Удаляем с диска
        NSString* localPath = [NSString stringWithFormat:@"%@/%@.json",self.pathToTemplateDirectory,apiMethod];
        [TemplaterFileManager removeItemAtPath:localPath error:&error];

        // Удаляем из RAM
        [self.templates removeObjectForKey:apiMethod];
    });
    return error;
}


/*--------------------------------------------------------------------------------------------------------------
 Позволяет безопасно удалить папку со всеми шаблонами одновременно
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
 Создает папку если она не существует по переданному пути
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
  Перемещает папку 'APIManagerResponseTemplates' по новому адресу
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
  Метод позволяет изменить расположение папки с шаблонами.
  Блок 'dispatch_barrier_sync' позволяет сначала дождаться выполениния всех остальных операций, а потом выполнить
  переименования.
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
    // Восстанавливаем из UserDefault
    if ((!_pathToTemplateDirectory) && ([Templater shortPathFromUserDefault].length > 0)) {
          _pathToTemplateDirectory = [Templater fullPathFromUserDefault];
    }
    
    // Если в UserDefault ничего не было, то устанавливаем значение по-умолчанию и записываем
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
 Сюда должен приходить целый путь ДО папки, например:
 '/Users/Containers/Data/Application/.../Library/' имя 'APIManagerResponseTemplates' будет подставленно автоматически.
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setPathToTemplateDirectory:(NSString*)pathToTemplateDirectory
{
    if (pathToTemplateDirectory.length < 1){
        _pathToTemplateDirectory = nil;
        return;
    }

    NSString* fullPath        = [Templater buildFullPathFrom:pathToTemplateDirectory];
    NSString* shortPathFromUD = [Templater shortPathFromUserDefault];
    
    // Если проперти уже имеет значение
    if ((_pathToTemplateDirectory.length > 0) && (fullPath.length > 0))
    {
        // Тогда проверяем что-бы значения были не одинаковые
        if ([_pathToTemplateDirectory isEqualToString:fullPath]){
            // Если значения одинаковые то прерываем выполнение
            return;
        } else {
            // Если значения разные. То:
            // 1. Перенести папку из старой локации в новую
            // 2. Записать новый путь в UserDefault
            NSError* error = [Templater replaceTemplateDirectoryAtPath:fullPath];
            //[TemplaterFileManager moveItemAtPath:_pathToTemplateDirectory toPath:fullPath error:&error];
            if (error) NSLog(@"error: %@",error);
            else {
                // и записываем новое значение в UserDefault
                [Templater saveAnyPathToUserDefault:fullPath];
            }
            _pathToTemplateDirectory = fullPath;
        }
        return;
    }

    // Если в UserDefault что-то было. И значение из аргумента полностью индетично, то устанавливаем значение и выходим
    if ([[Templater cutShortPathFrom:fullPath] isEqualToString:[Templater shortPathFromUserDefault]])
    {
        _pathToTemplateDirectory = fullPath;
        return;
    }

    
    // Если в UserDefault пусто
    if (shortPathFromUD.length < 1){
        // Создаем папку
        [self createFolderIfItDoesntExitByPath:fullPath];

    // Если в UserDefault что-то было, то просто перемещаем в новую локацию
    } else if ((shortPathFromUD.length > 1) && (![shortPathFromUD isEqualToString:[Templater cutShortPathFrom:fullPath]])) {
       
        NSError* error = [Templater replaceTemplateDirectoryAtPath:fullPath];
        if (error) NSLog(@"error: %@",error);
        
    }
    // Записываем значение
    [Templater saveAnyPathToUserDefault:fullPath];
    
    // Устанавливаем значение в проперти
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
 Метод распаковывает архив с папкой стандартных json файлов (ответов от сервера).
 Если укажите nil в аргумент 'atPath', тогда алгоритм автоматический разархиврует папку по пути 'Templater.pathToTemplateDirectory'.
 Данный метод вы можете вызывать каждый раз при запуске приложения внутри метода +APIManager.prepareBeforeUsing:,
 внутри встроена защита от повторных разархиврований.
 --------------------------------------------------------------------------------------------------------------*/

+ (void) unarchiveFolderWithDefaultTemplates:(nullable NSString*)atPath
                                  completion:(nullable void(^)(NSError* error))completion
{
    // Проверяем был ли ранее архив разрахивирован
    BOOL wasZipExtractedEarly = [[NSUserDefaults standardUserDefaults] boolForKey:wasArchiveExtractedUserDefaultKey];
    if (wasZipExtractedEarly){
        return;
    }
    
    // Устанавливаем путь куда будет произведена разархивация
    if (atPath.length < 1){
        atPath = Templater.pathToTemplateDirectory;
    } else {
        [Templater setNewPathToTemplateDirectory:atPath];
    }
    
    // Удаляем на конце строки названия папки
    atPath = [Templater removeDefaultFolderNameToPathIfItNeeded:atPath];
    
    // Ищем путь к архиву в bundle приложения
    NSString *localPathAtZip = [[NSBundle mainBundle] pathForResource:@"APIManagerResponseDefaultTemplates" ofType:@"zip"];
    if (localPathAtZip.length < 1){
        if (completion)
            completion([NSError errorWithDomain:@"APIManagerResponseDefaultTemplates.zip wasn't find in bundle" code:0 userInfo:nil]);
        return;
    }
    
    // Разархивируем архив
    [SSZipArchive unzipFileAtPath:localPathAtZip
                    toDestination:atPath
                  progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
                      
                  } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable errorUnpackZip) {
                      
                      if (errorUnpackZip){
                          if (completion) { completion(errorUnpackZip); };
                      }else if (succeeded){
                          if (completion) completion(nil);
                          
                          // Записываем флаг говорящий о том, что разархивация была проведена
                          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:wasArchiveExtractedUserDefaultKey];
                          [[NSUserDefaults standardUserDefaults] synchronize];
                      }
    }];
}



/*--------------------------------------------------------------------------------------------------------------
Обрезает длинный путь, возвращая только 'Documents/API Manager Response Templates'
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
 Соединяет строку NSHomeDirectory() c 'Documents/APIManagerResponseTemplates' (если это требуется), и возвращает
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
  Добавляет название папки 'APIManagerResponseTemplates' в переданный путь (если оно там отсуствует)
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
 Удаляет название папки 'APIManagerResponseTemplates' в переданный путь (если оно там присутствует)
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) removeDefaultFolderNameToPathIfItNeeded:(NSString*)path
{
    if (path.length < 1) return nil;
    
    NSRange templateFolder_range = [path rangeOfString:@"/APIManagerResponseTemplates"];
    if (templateFolder_range.location != NSNotFound){
        path = [path substringToIndex:templateFolder_range.location];
        //path = [path stringByAppendingPathComponent:@"/APIManagerResponseTemplates"];
    }
    return path;
}



/*--------------------------------------------------------------------------------------------------------------
 Сохраняет путь в UserDefault. Может принять любую модификацию shortPath/fullPath
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) saveAnyPathToUserDefault:(NSString*)path
{
    if (path.length < 1) return NO;

    path = [Templater appendDefaultFolderNameToPathIfItNeeded:path];
    path = [Templater cutShortPathFrom:path];
    
    // Записываем значение
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:templateDirectoryUserDefaultKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}

/*--------------------------------------------------------------------------------------------------------------
 Извлекает из UserDefault и возвращает короткую строку 'Documents/APIManagerResponseTemplates'.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) shortPathFromUserDefault
{
    return  [[NSUserDefaults standardUserDefaults] stringForKey:templateDirectoryUserDefaultKey];
}


/*--------------------------------------------------------------------------------------------------------------
 Извлекает из UserDefault короткую строку 'Documents/APIManagerResponseTemplates'.
 Модифицирует 'NSHomeDirectory()'+'Documents/APIManagerResponseTemplates' и возвращает полный путь
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSString*) fullPathFromUserDefault
{
    NSString* path = [Templater shortPathFromUserDefault];
    NSString* full = [Templater buildFullPathFrom:path];
    return full;
}


@end
