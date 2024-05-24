### Сервис для сбора пожертвований и распределения собранных средств

В репозитории находится два файла. 

Файл Donor представляет из себя два смарт-контракта: **Первый Donor**, в нём реализована логика контракта для сбора пожертвований. Также в нём подключен оракул из remix, 
который собирает информацию о цене. С его помощью реализована функция просмотра цены контракта в долларах. Помимо основного контракта с логикой, в данном контракте также реализован прокси-контракт, 
основная функция которого — это дать возможность обновления текущей логике основного контракта. 

Для распределения пожертвований, используется контракт в другом файле - **Payout**. В нём реализована логика для распределеня токенов между участниками из списка. 
Функция распределения вызывается из контракта donor, что позволяет сохранить в данный контракт новый баланс и возможность у учатников распределения портебовать данный баланс.
 