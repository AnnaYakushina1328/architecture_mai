workspace {
    name "Система заказа такси"
    description "ДЗ1 - Документирование архитектуры в Structurizr (вариант 16)"

    model {
        // роли
        passenger = person "Пассажир" "Зарегистрированный пользователь. Создаёт заказы на поездки, отслеживает статус, просматривает историю."
        driver = person "Водитель" "Зарегистрированный водитель. Получает доступные заказы, принимает и выполняет поездки."
        admin = person "Администратор" "Сотрудник поддержки/админ. Управляет пользователями, водителями, мониторит систему."


        // внешние системы
        paymentGateway = softwareSystem "Платёжный шлюз" "Внешняя система обработки платежей (карты, электронные кошельки)." "External"
        mapsService = softwareSystem "Сервис карт и геолокации" "Внешний API для геопозиционирования, построения маршрутов, расчёта времени/стоимости." "External"
        smsGateway = softwareSystem "SMS-шлюз" "Внешний сервис отправки SMS-уведомлений." "External"
        emailService = softwareSystem "Email-сервис" "Внешний сервис отправки электронных писем и чеков." "External"
        pushService = softwareSystem "Push-уведомления" "Firebase Cloud Messaging / APNS для мгновенных уведомлений." "External"

        // основная система
        taxiSystem = softwareSystem "Система заказа такси" "Платформа заказа такси: регистрация пассажиров и водителей, создание и управление заказами, трекинг поездок, оплата, уведомления."{
        
            // клиенты
            passengerApp = container "Мобильное приложение пассажира" "Интерфейс для заказа поездок, отслеживания водителя, истории поездок." "Mobile UI (iOS/Android)"
            driverApp = container "Мобильное приложение водителя" "Интерфейс для получения заказов, навигации, управления статусом." "Mobile UI (iOS/Android)"
            adminWeb = container "Веб-панель администратора" "Интерфейс для управления пользователями, мониторинга заказов, аналитики." "Web UI"

            // точка входа
            apiGateway = container "API Gateway" "Единая точка входа: маршрутизация, аутентификация, ограничение частоты запросов, проксирование к микросервисам." "Nginx / Kong"

            // сервисы
            authService = container "Auth Service" "Регистрация, вход, валидация токенов, управление сессиями." "FastAPI"
            userService = container "User Service" "Профили пассажиров: данные, поиск пользователей, настройки." "FastAPI"
            driverService = container "Driver Service" "Профили водителей: документы, рейтинг, геопозиция." "FastAPI"
            orderService = container "Order Service" "Создание заказов, поиск ближайших водителей, сопоставление, управление жизненным циклом поездки." "FastAPI"
            paymentService = container "Payment Service" "Интеграция с платёжным шлюзом: привязка карт, списание, возвраты, чеки." "FastAPI"
            notificationService = container "Notification Service" "Агрегатор уведомлений: выбор канала (push/SMS/email), отправка через внешние провайдеры." "FastAPI"

            // хранилища
            authDb = container "Auth DB" "Учетные данные, хеши паролей, refresh-токены, сессии." "PostgreSQL"
            userDb = container "User DB" "Профили пассажиров, предпочтения, адреса." "PostgreSQL"
            driverDb = container "Driver DB" "Данные водителей: документы, авто, рейтинг, текущая геопозиция." "PostgreSQL + PostGIS"
            orderDb = container "Order DB" "Заказы, статусы, маршруты, история поездок." "PostgreSQL"
            redis = container "Redis" "Кеширование: доступные водители, активные заказы, геопозиции в реальном времени." "Redis"

            // Взаимодействие пользователей с клиентами
            passenger -> passengerApp "Использует приложение" "HTTPS"
            driver -> driverApp "Использует приложение" "HTTPS"
            admin -> adminWeb "Использует панель управления" "HTTPS"

            // Клиенты -> gateway
            passengerApp -> apiGateway "Вызывает API" "HTTPS/REST"
            driverApp -> apiGateway "Вызывает API" "HTTPS/REST"
            adminWeb -> apiGateway "Вызывает API" "HTTPS/REST"

            // Gateway -> сервисы
            apiGateway -> authService "API аутентификации (/auth/*)" "HTTPS/REST"
            apiGateway -> userService "API пользователей (/users/*)" "HTTPS/REST"
            apiGateway -> driverService "API водителей (/drivers/*)" "HTTPS/REST"
            apiGateway -> orderService "API заказов (/orders/*)" "HTTPS/REST"
            apiGateway -> paymentService "API платежей (/payments/*)" "HTTPS/REST"
            apiGateway -> notificationService "API уведомлений (/notifications/*)" "HTTPS/REST"

            // Сервисы -> БД
            authService -> authDb "Данные аутентификации" "SQL"
            userService -> userDb "Профили пассажиров" "SQL"
            driverService -> driverDb "Данные водителей и геопозиции" "SQL + PostGIS"
            orderService -> orderDb "Данные заказов и поездок" "SQL"

            // Сервисы -> Redis
            driverService -> redis "Обновление геопозиции водителя" "RESP"
            orderService -> redis "Поиск ближайших доступных водителей" "RESP"
            orderService -> redis "Кеширование активных заказов" "RESP"
            userService -> redis "Кеширование поиска пользователей" "RESP"

            // Межсервисные взаимодействия
            orderService -> userService "Получение данных пассажира" "HTTPS/REST"
            orderService -> driverService "Поиск и бронирование водителя" "HTTPS/REST"
            orderService -> paymentService "Инициация платежа после завершения поездки" "HTTPS/REST"
            orderService -> notificationService "Уведомление о статусе заказа" "HTTPS/REST"
            driverService -> notificationService "Уведомление водителя о новом заказе" "HTTPS/REST"
            paymentService -> notificationService "Отправка чека пассажиру" "HTTPS/REST"

            // Интеграции с внешними системами
            orderService -> mapsService "Расчёт маршрута, расстояния, времени и стоимости" "HTTPS/REST"
            driverService -> mapsService "Отправка/обновление геопозиции водителя" "HTTPS/REST"
            paymentService -> paymentGateway "Обработка платежей" "HTTPS/REST"
            notificationService -> smsGateway "Отправка SMS" "HTTPS API"
            notificationService -> emailService "Отправка email и чеков" "SMTP/REST"
            notificationService -> pushService "Отправка push-уведомлений" "FCM/APNS"
        }
    }

    views {
    systemContext taxiSystem "C1-SystemContext" {
      include passenger
      include driver
      include admin
      include taxiSystem
      include paymentGateway
      include mapsService
      include smsGateway
      include emailService
      include pushService
      autolayout lr
      title "C1 – Контекст системы: Система заказа такси"
      description "Пассажир и водитель взаимодействуют с системой через мобильные приложения. Администратор использует веб-панель. Система интегрируется с внешними сервисами: платежи, карты, уведомления."
    }

    container taxiSystem "C2-Containers" {
      include *
      autolayout lr
      title "C2 – Диаграмма контейнеров: Система заказа такси"
      description "Контейнеры отражают ключевые подсистемы: аутентификация, управление пользователями и водителями, заказы, платежи, уведомления. Каждый сервис имеет собственное хранилище. Redis используется для кеширования геоданных и активных заказов."
    }

    dynamic taxiSystem "D1-CreateOrder" {
      title "D1 – Динамика: создание заказа пассажиром"
      description "Пассажир создаёт заказ через мобильное приложение. Order Service находит ближайших водителей через Redis, отправляет уведомления, фиксирует заказ в БД."

      passenger -> passengerApp "Вводит маршрут и нажимает «Заказать»"
      passengerApp -> apiGateway "POST /orders {from, to, passengerId}" "HTTPS/REST"
      apiGateway -> orderService "Маршрутизация запроса /orders" "HTTPS/REST"
      orderService -> mapsService "Расчёт стоимости и времени поездки" "HTTPS/REST"
      orderService -> redis "Поиск доступных водителей в радиусе" "RESP"
      orderService -> driverService "Получение деталей найденных водителей" "HTTPS/REST"
      orderService -> notificationService "Уведомление водителей о новом заказе" "HTTPS/REST"
      notificationService -> pushService "Push: «Новый заказ рядом»" "FCM/APNS"
      orderService -> orderDb "Сохранение заказа со статусом «searching»" "SQL"
      orderService -> apiGateway "200 OK {orderId, estimatedPrice}" "HTTPS/REST"
      apiGateway -> passengerApp "200 OK {orderId, estimatedPrice}" "HTTPS/REST"

      autolayout lr
    }

    dynamic taxiSystem "D2-CompleteTrip" {
      title "D2 – Динамика: завершение поездки и оплата"
      description "Водитель завершает поездку. Order Service обновляет статус, Payment Service списывает средства, Notification Service отправляет чек."

      driver -> driverApp "Нажимает «Завершить поездку»"
      driverApp -> apiGateway "POST /orders/{orderId}/complete" "HTTPS/REST"
      apiGateway -> orderService "Маршрутизация запроса" "HTTPS/REST"
      orderService -> orderDb "Обновление статуса заказа на «completed»" "SQL"
      orderService -> paymentService "Инициация платежа {orderId, amount}" "HTTPS/REST"
      paymentService -> paymentGateway "Списание средств с карты пассажира" "HTTPS/REST"
      paymentGateway -> paymentService "Подтверждение транзакции" "HTTPS/REST"
      paymentService -> notificationService "Отправка чека пассажиру" "HTTPS/REST"
      notificationService -> emailService "Email с чеком" "SMTP/REST"
      notificationService -> pushService "Push: «Поездка оплачена»" "FCM/APNS"
      paymentService -> orderService "Платёж успешен" "HTTPS/REST"
      orderService -> apiGateway "200 OK {receiptId}" "HTTPS/REST"
      apiGateway -> driverApp "200 OK" "HTTPS/REST"

      autolayout lr
    }
  }
}