#Использовать fs
#Использовать gitrunner

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ОписаниеКоманды(Команда) Экспорт

	Команда.Аргумент("REPO", , 
				"Путь к git-репозиторию для установки hook pre-commit")
				.ТСтрока()
				.Обязательный(Истина);

	Команда.Опция("src", "src", 
				"Путь к каталогу исходников src")
				.ТСтрока();

	Команда.Опция("file", "Ext/ParentConfigurations.bin", 
				"Относительный путь к файлу ParentConfigurations.bin внутри каталога исходников")
				.ТСтрока();

КонецПроцедуры

// Выполняет логику команды
Процедура ВыполнитьКоманду(Знач Команда) Экспорт

	ПутьКГитРепозиторию = Команда.ЗначениеАргумента("REPO");
	КаталогИсходников   = Команда.ЗначениеОпции("src");
	ПутьКФайлуПоддержки = Команда.ЗначениеОпции("file");

	ФайлПуть = Новый Файл(ПутьКГитРепозиторию);
	Если НЕ ФайлПуть.ЭтоКаталог() Тогда
		ВызватьИсключение СтрШаблон("Путь %1 не является каталогом. Укажите каталог репозитория", ПутьКГитРепозиторию);
	КонецЕсли;

	Файлы = НайтиФайлы(ПутьКГитРепозиторию, ".git", Истина);
	Если Файлы.Количество() = 0 Тогда
		ВызватьИсключение СтрШаблон("GIT-репозиторий не найден или не инициализирован: %1", ФайлПуть.ПолноеИмя);
	
	ИначеЕсли Файлы.Количество() > 1 Тогда
		ТекстОшибки = Новый Массив();
		ТекстОшибки.Добавить(СтрШаблон("Обнаружено более одного GIT-репозитория в папке: %1", ФайлПуть.ПолноеИмя));
		Для каждого Файл Из Файлы Цикл
			ТекстОшибки.Добавить(Файл.ПолноеИмя);
		КонецЦикла;
		ВызватьИсключение СтрСоединить(ТекстОшибки, Символы.ПС);
	
	ИначеЕсли НЕ Файлы[0].ЭтоКаталог() Тогда
		ВызватьИсключение "Файл .git не является каталогом"

	КонецЕсли;

	ПутьКГитРепозиторию = Файлы[0].Путь; // Путь - это родитель .git
	ПутьКHooks = ОбъединитьПути(Файлы[0].ПолноеИмя, "hooks");
	ПутьКШаблонам = ПараметрыПриложения.ПутьКШаблонам();
	ПутьКPrecommit = ОбъединитьПути(ПутьКHooks, "pre-commit");

	// ИмяФайлаИсполнителяХука = "v8-ParentConfigConvertеr.os";
	// НазначениеИсполнителяХука = ОбъединитьПути(ПутьКHooks, ИмяФайлаИсполнителяХука);
	// КопироватьФайл(ОбъединитьПути(ПутьКШаблонам, ИмяФайлаИсполнителяХука), ОбъединитьПути(ПутьКHooks, ИмяФайлаИсполнителяХука));
	// Сообщить("Создан файл исполнителя хука: " + НазначениеИсполнителяХука);

	Если ФС.ФайлСуществует(ПутьКPrecommit) Тогда
		Текст = ОбщегоНазначения.ПрочитатьФайлВТекст(ПутьКPrecommit);
		НовыйТекст = Новый Массив();
		Для НомерСтроки = 1 По СтрЧислоСтрок(Текст) Цикл
			Строка = СтрПолучитьСтроку(Текст, НомерСтроки);
			Если НЕ ПустаяСтрока(Строка) И СтрНайти(Строка, ПараметрыПриложения.Имя()) = 0 Тогда
				НовыйТекст.Добавить(Строка);
			КонецЕсли;
		КонецЦикла;
		ТекстШаблона = ОбщегоНазначения.ПрочитатьФайлВТекст(ОбъединитьПути(ПутьКШаблонам, "pre-commit"));
		Для НомерСтроки = 2 По СтрЧислоСтрок(ТекстШаблона) Цикл
			НовыйТекст.Добавить(СтрПолучитьСтроку(ТекстШаблона, НомерСтроки));
		КонецЦикла;
		ТекстФайла = СтрСоединить(НовыйТекст, Символы.ПС);
		Сообщить("Дополнен файл хука: " + ПутьКPrecommit);
	Иначе
		ТекстФайла = ОбщегоНазначения.ПрочитатьФайлВТекст(ОбъединитьПути(ПутьКШаблонам, "pre-commit"));
		Сообщить("Создан файл хука: " + ПутьКPrecommit);
	КонецЕсли;
	ТекстФайла = СтрЗаменить(ТекстФайла, "{src}", КаталогИсходников);
	ТекстФайла = СтрЗаменить(ТекстФайла, "{file}", ПутьКФайлуПоддержки);
	ОбщегоНазначения.ЗаписатьТекстВФайл(ПутьКPrecommit, ТекстФайла);
	
	Сообщить("Хук pre-commit установлен");

	СисИнфо = Новый СистемнаяИнформация;
	ЭтоWindows = Найти(НРег(СисИнфо.ВерсияОС), "windows") > 0;
	Если НЕ ЭтоWindows Тогда
		ЗапуститьПриложение("chmod +x " + ПутьКPrecommit);
	КонецЕсли;

КонецПроцедуры