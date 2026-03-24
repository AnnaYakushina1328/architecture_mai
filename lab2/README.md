# Домашнее задание 02: Разработка REST API сервиса
Цель работы: Получить практические навыки разработки REST API сервиса с
использованием принципов REST, обработкой HTTP запросов, реализацией аутентификации
и документированием API.
## Задание
Выберите нужный вариант из файла `homework_variants.pdf` (варианты 1-24) и
выполните следующие задачи:
1. Проектирование REST API
 - Изучите выбранный вариант задания
 - Спроектируйте REST API endpoints для всех операций из вашего варианта
 - Используйте правильные HTTP методы (GET, POST, PUT, DELETE, PATCH)
 - Используйте правильные HTTP статус-коды
 - Спроектируйте структуру URL (ресурсы, вложенные ресурсы)
 - Определите структуру Request/Response для каждого endpoint
2. Реализация REST API сервиса
 - Реализуйте REST API сервис на выбранном языке и фреймворке (Python FastAPI,
C++ Poco, Yandex Userver)
 - Реализуйте минимум 5 API endpoints из вашего варианта задания
 - Используйте in-memory хранилище (списки, словари) или простую БД (SQLite)
 - Реализуйте обработку ошибок с правильными HTTP статус-кодами
 - Используйте DTO (Data Transfer Objects) для передачи данных
3. Реализация аутентификации
 - Реализуйте простую аутентификацию (можно использовать JWT токены или sessionbased)
 - Защитите минимум 2 endpoint с помощью аутентификации
 - Реализуйте endpoint для регистрации/логина пользователя
 - Добавьте middleware для проверки аутентификации
4. Документирование API
 - Создайте OpenAPI/Swagger спецификацию для вашего API
 - Опишите все endpoints с параметрами, request/response схемами
 - Добавьте примеры запросов и ответов
 - Если возможно, добавьте Swagger UI для интерактивного тестирования API
5. Тестирование
 - Создайте простые тесты для основных endpoints (можно использовать curl,
Postman или unit-тесты)
 - Протестируйте успешные сценарии
 - Протестируйте обработку ошибок (невалидные данные, отсутствующие ресурсы и
т.д.)

## Результат
# Вариант 16 - Система заказа такси https://www.uber.com/
Приложение должно содержать следующие данные:
- Пользователь
- Водитель
- Поездка
Реализовать API:
- Создание нового пользователя
- Поиск пользователя по логину
- Поиск пользователя по маске имя и фамилии
- Регистрация водителя
- Создание заказа поездки
- Получение активных заказов
- Принятие заказа водителем
- Получение истории поездок пользователя
- Завершение поездки

## Архитектура системы
Система реализована как набор микросервисов на Yandex Userver.

### Микросервисы

| Сервис | Порт | Назначение |
|--------|------|-----------|
| auth-service | 8081 | Аутентификация |
| user-service | 8082 | Пользователи |
| driver-service | 8083 | Водители |
| order-service | 8084 | Заказы |
| payment-service | 8085 | Платежи |


## REST API Endpoints по сервисам

### Auth Service (`:8081`)

**POST /auth/register**

Request:
```json
{
  "login": "passenger1",
  "password": "secret123",
  "full_name": "Иван Иванов"
}
```

Response:
```json
{
  "id": 1,
  "login": "passenger1"
}
```

**POST /auth/login**

Request:
```json
{
  "login": "passenger1",
  "password": "secret123"
}
```

Response:
```json
{
  "token": "123"
}
```

### User Service (:8082)

**POST /users**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```json
{
  "login": "passenger2",
  "full_name": "Петр Петров",
  "phone": "+79991234567"
}
```

Response:
```json
{
  "id": 2,
  "login": "passenger2"
}
```

**GET /users**
Headers: 
```
Authorization: Bearer <token>
```

Response:
```json
[
  {
    "id": 1,
    "login": "passenger1"
  },
  {
    "id": 2,
    "login": "passenger2"
  }
]
```

Поиск по логину: `GET /users?login=passenger1`
Поиск по маске: `GET /users?name=Иван`

**GET /users/{id}**
Headers: 
```
Authorization: Bearer <token>
```

Response:
```json
{
  "id": 2,
  "login": "passenger2",
  "full_name": "Петр Петров",
  "phone": "+79991234567"
}
```

### Driver Service (:8083)

**POST /drivers**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```json
{
  "user_id": 2,
  "car_model": "Toyota Camry",
  "car_number": "А123БВ777",
  "license_number": "77AB123456"
}
```

Response:
```json
{
  "id": 1,
  "user_id": 2,
  "status": "online"
}
```

**GET /drivers/available**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```
GET /drivers/available?lat=55.75&lng=37.61&radius=5
```

Response:
```json
[
  {
    "id": 1,
    "user_id": 2,
    "car_model": "Toyota Camry",
    "rating": 4.5,
    "distance": 1.2
  }
]
```

**PATCH /drivers/{id}/location**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```json
{
  "lat": 55.751244,
  "lng": 37.618423
}
```

Response:
```json
{
  "id": 1,
  "status": "ok"
}
```

**PATCH /drivers/{id}/status**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```json
{
  "status": "online"
}
```

Response:
```json
{
  "id": 1,
  "status": "online"
}
```

### Order Service (:8084)

**POST /orders**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```json
{
  "passenger_id": 1,
  "pickup": {
    "lat": 55.751244,
    "lng": 37.618423
  },
  "destination": {
    "lat": 55.755826,
    "lng": 37.617300
  }
}
```

Response:
```json
{
  "id": 1,
  "status": "searching"
}
```

**GET /orders/{id}**
Headers: 
```
Authorization: Bearer <token>
```

Response:
```json
{
  "id": 1,
  "passenger_id": 1,
  "driver_id": null,
  "status": "searching",
  "estimated_price": 350.50
}
```

**GET /orders**
Headers: 
```
Authorization: Bearer <token>
```

Request:
```
GET /orders?passenger_id=1
```

Response:
```json
[
  {
    "id": 1,
    "passenger_id": 1,
    "driver_id": 1,
    "status": "completed",
    "estimated_price": 350.50
  },
  {
    "id": 2,
    "passenger_id": 1,
    "driver_id": 2,
    "status": "completed",
    "estimated_price": 520.00
  }
]
```
Получение активных заказов: `GET /orders?status=active`

**PATCH /orders/{id}/status**
Headers: 
```
Authorization: Bearer <token>
```

Request (принятые заказы водителем):
```json
{
  "status": "accepted",
  "driver_id": 1
}
```

Response:
```json
{
  "id": 1,
  "status": "accepted",
  "driver_id": 1
}
```

Request (завершение поездки):
```json
{
  "status": "completed"
}
```

Response:
```json
{
  "id": 1,
  "status": "completed"
}
```

**DELETE /orders/{id}**

Headers: 
```
Authorization: Bearer <token>
```

Response: ```204 No Content```