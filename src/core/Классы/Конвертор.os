
Перем КаталогРепозитория;

Процедура ПриСозданииОбъекта(Знач ПутьККаталогуРепозитория) Экспорт
	
	КаталогРепозитория = ПутьККаталогуРепозитория;

	Если НЕ ЗначениеЗаполнено(КаталогРепозитория) Тогда
		ВызватьИсключение "Каталог репозитория не указан";
	КонецЕсли;
	Файл = Новый Файл(КаталогРепозитория);
	Если НЕ Файл.Существует() Или НЕ Файл.ЭтоКаталог() Тогда
		ВызватьИсключение "Каталог репозитория не существует: " + Файл.ПолноеИмя;
	КонецЕсли;

КонецПроцедуры

Функция ВыполнитьКонвертацию(Метаданные, Источник, Приемник, ОчищатьГуидыБезСопоставлений) Экспорт
	
	СоответствиеИменID = Метаданные.СоответствиеИменID();

	ТекстСодержимогоФайла = ОбщегоНазначения.ПрочитатьФайлВТекст(Источник);
	Если СтрЧислоСтрок(ТекстСодержимогоФайла) > 1 Тогда
		Возврат "Конвертация файла поддержки не требуется. Файл уже сконвентирован.";
	КонецЕсли;

	РВ = Новый РегулярноеВыражение("(\d,-?\d,)(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},)\2");  // парные повторяющиеся гуиды
	ТекстИзмененный = РВ.Заменить(ТекстСодержимогоФайла, Символы.ПС + "$1$2 #" + Символы.ПС);
	
	РВ = Новый РегулярноеВыражение("(\d,-?\d,)(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},){2}"); // не парные гуиды
	ТекстИзмененный = РВ.Заменить(ТекстИзмененный, Символы.ПС + "$0 #" + Символы.ПС);
	
	мТекстИзмененный = СтрРазделить(ТекстИзмененный, Символы.ПС, Ложь);
	
	СконвертированныйТекст = Новый Массив();

	// подстановка имен в парные гуиды
	РВ_ПарныеГуиды = Новый РегулярноеВыражение("\d,-?\d,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}), #");
	РВ_РазныеГуиды = Новый РегулярноеВыражение("\d,-?\d,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}), #");
	Для Каждого Стр Из мТекстИзмененный Цикл
		Совпадения1 = РВ_ПарныеГуиды.НайтиСовпадения(Стр);
		Если Совпадения1.Количество() Тогда
			ID      = Совпадения1[0].Группы[1].Значение;
			ИмяМета = СоответствиеИменID[ID];
			Если ИмяМета = Неопределено Тогда
				Если ОчищатьГуидыБезСопоставлений Тогда
					Продолжить;
				КонецЕсли;
				ИмяМета = "";
			КонецЕсли;
			Если ЗначениеЗаполнено(ИмяМета) Тогда
				Стр = Стр + " " + ИмяМета;
			КонецЕсли;
		Иначе
			Совпадения2 = РВ_РазныеГуиды.НайтиСовпадения(Стр);
			Если Совпадения2.Количество() Тогда
				ID1 = Совпадения2[0].Группы[1].Значение;
				ID2 = Совпадения2[0].Группы[2].Значение;
				Если СоответствиеИменID[ID1] <> Неопределено Тогда
					ИмяМета  = СоответствиеИменID[ID1];
					НомерИдентификатора = "1";
				ИначеЕсли СоответствиеИменID[ID2] <> Неопределено Тогда
					ИмяМета  = СоответствиеИменID[ID2];
					НомерИдентификатора = "2";
				ИначеЕсли ОчищатьГуидыБезСопоставлений Тогда
					Продолжить;
				Иначе
					ИмяМета = "";
				КонецЕсли;
				Если ЗначениеЗаполнено(ИмяМета) Тогда
					Стр = СтрШаблон("%1 %2:%3", Стр, НомерИдентификатора, ИмяМета);
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;
		СконвертированныйТекст.Добавить(Стр);
	КонецЦикла;

	ОбщегоНазначения.ЗаписатьТекстВФайл(Приемник, СтрСоединить(СконвертированныйТекст, Символы.ПС));
	
	Возврат "";

КонецФункции

Функция ВыполнитьВосстановление(Источник, Приемник) Экспорт

	ЧтениеТекста = Новый ЧтениеТекста();
	ЧтениеТекста.Открыть(Источник, КодировкаТекста.UTF8);

	ВосстановленныйТекст = Новый Массив();
	ЕстьВосстановленныеСтроки = Ложь;

	РВ_ПарныеГуиды = Новый РегулярноеВыражение("\d,-?\d,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},)( #.*)");
	РВ_РазныеГуиды = Новый РегулярноеВыражение("\d,-?\d,(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},){2}( #.*)");
	Стр = ЧтениеТекста.ПрочитатьСтроку();
	Пока Стр <> Неопределено Цикл
		Совпадения1 = РВ_ПарныеГуиды.НайтиСовпадения(Стр);
		Если Совпадения1.Количество() Тогда
			ID = Совпадения1[0].Группы[1].Значение;
			ИмяМета = Совпадения1[0].Группы[2].Значение;
			Стр = СтрЗаменить(Стр, ИмяМета, ID);
			ЕстьВосстановленныеСтроки = Истина;
		Иначе
			Совпадения2 = РВ_РазныеГуиды.НайтиСовпадения(Стр);
			Если Совпадения2.Количество() Тогда
				ИмяМета = Совпадения2[0].Группы[2].Значение;
				Стр = СтрЗаменить(Стр, ИмяМета, "");
				ЕстьВосстановленныеСтроки = Истина;
			КонецЕсли;
		КонецЕсли;
		ВосстановленныйТекст.Добавить(Стр);
		Стр = ЧтениеТекста.ПрочитатьСтроку();
	КонецЦикла;

	ЧтениеТекста.Закрыть();

	Если ЕстьВосстановленныеСтроки Тогда
		ОбщегоНазначения.ЗаписатьТекстВФайл(Приемник, СтрСоединить(ВосстановленныйТекст, ""));
	КонецЕсли;

	Возврат ЕстьВосстановленныеСтроки;

КонецФункции
	
Функция ПолучитьТаблицуОбъектовНаПоддержке(Источник) Экспорт
	
	Таблица = Новый ТаблицаЗначений();
	Таблица.Колонки.Добавить("ГУИД");  // Основной идентификатор
	Таблица.Колонки.Добавить("Режим"); // Режим поддержки 0,0
	Таблица.Колонки.Добавить("Имя");   // Имя объекта 1С

	ТекстСодержимогоФайла = ОбщегоНазначения.ПрочитатьФайлВТекст(Источник);
	Если СтрЧислоСтрок(ТекстСодержимогоФайла) > 1 Тогда
		// конвертированный файл

		РВ_ПарныеГуиды = Новый РегулярноеВыражение("(\d,-?\d),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12}), #(.*)");
		РВ_РазныеГуиды = Новый РегулярноеВыражение("(\d,-?\d),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},\w{8}-\w{4}-\w{4}-\w{4}-\w{12}), #(.*)");
		МассивСтрок = СтрРазделить(ТекстСодержимогоФайла, Символы.ПС);
		Для каждого Стр Из МассивСтрок Цикл
			Совпадения1 = РВ_ПарныеГуиды.НайтиСовпадения(Стр);
			Если Совпадения1.Количество() Тогда
				СтрТаблицы = Таблица.Добавить();
				СтрТаблицы.Режим = Совпадения1[0].Группы[1].Значение;
				СтрТаблицы.ГУИД  = Совпадения1[0].Группы[2].Значение;
				СтрТаблицы.Имя   = СокрЛП(Совпадения1[0].Группы[3].Значение);
			Иначе
				Совпадения2 = РВ_РазныеГуиды.НайтиСовпадения(Стр);
				Если Совпадения2.Количество() Тогда
					СтрТаблицы = Таблица.Добавить();
					СтрТаблицы.Режим = Совпадения1[0].Группы[1].Значение;
					СтрТаблицы.ГУИД  = Совпадения1[0].Группы[2].Значение;
					СтрТаблицы.Имя   = СокрЛП(Совпадения1[0].Группы[3].Значение);
				КонецЕсли;
			КонецЕсли;
		КонецЦикла;

	Иначе
		// оригинальный файл

		РВ = Новый РегулярноеВыражение("(\d,-?\d),(\w{8}-\w{4}-\w{4}-\w{4}-\w{12},){2}");
		Совпадения = РВ.НайтиСовпадения(ТекстСодержимогоФайла);
		Для каждого Совпадение Из Совпадения Цикл
			СтрТаблицы = Таблица.Добавить();
			СтрТаблицы.Режим = Совпадение.Группы[1].Значение;
			ГУИД  = Совпадение.Группы[2].Значение;
			СтрТаблицы.ГУИД = Лев(ГУИД, СтрДлина(ГУИД) - 1);
		КонецЦикла;

	КонецЕсли;

	Возврат Таблица;

КонецФункции

