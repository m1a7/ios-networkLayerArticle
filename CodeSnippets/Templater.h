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


@interface Templater : NSObject

/*--------------------------------------------------------------------------------------------------------------
 Возвращает адрес на папку, которая содержит файлы-шаблоны.
 Если вы измените значение папки, то папка вместе с файлами переместиться в другое место.
 --------------------------------------------------------------------------------------------------------------*/
@property (atomic, strong, readonly, class) NSString* pathToTemplateDirectory;


/*--------------------------------------------------------------------------------------------------------------
 По-умолчанию имеет значение 'NO'. Если заменить на 'YES', то требуемый файл будет искать в bundle приложения.
 --------------------------------------------------------------------------------------------------------------*/
@property (nonatomic, assign, class) BOOL loadTemplateFromBundle;

#pragma mark - Methods

/*--------------------------------------------------------------------------------------------------------------
 Позволяет безопастно изменить местоположение папки с шаблонами.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) setNewPathToTemplateDirectory:(NSString*)path;

/*--------------------------------------------------------------------------------------------------------------
 Востанавливает ранее записанный json файл с диска или возвращает его из RAM памяти.
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) templateForAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
 Записывает образец файла с именем API метода
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) writeTemplate:(NSDictionary*)template forAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
 Удаляет образец файла с диска и из RAM по имени API метода
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeTemplateForAPIMethod:(APIMethod)method;

/*--------------------------------------------------------------------------------------------------------------
 Позволяет безопастно удалить папку со всеми шаблонами одновременно
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSError*) removeAllTemplates;


/*--------------------------------------------------------------------------------------------------------------
 Метод распаковывает архив с папкой стандартных json файлов (ответов от сервера).
 Если укажите nil в аргумент 'atPath', тогда алгоритм автоматический разархиврует папку по пути 'Templater.pathToTemplateDirectory'.
 Данный метод вы можете вызывать каждый раз при запуске приложения внутри метода +APIManager.prepareBeforeUsing:,
 внутри встроена защита от повторных разархиврований.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) unarchiveFolderWithDefaultTemplates:(nullable NSString*)atPath
                                  completion:(nullable void(^)(NSError* error))completion;

@end

NS_ASSUME_NONNULL_END