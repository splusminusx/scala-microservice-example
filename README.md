## Минимальны пример Scala-приложения для деплоя совместимого с Thin

* В приложении присутствует обязательный `reference.conf` содержащий все
настройки приложения по умолчанию. В идеале этих настроек достаточно, чтобы
запустить приложение в среде разработчика.
* Конечный артефакт поставки приложения в тестовые и продакшен среды -
Docker образ. Докер образ публикуется в реестр с именем `dh.livetex.ru/service/<имя сервиса>:<тэг>`.
Имя сервиса должно совпадать с именем проекта в `build.sbt`.
* При развертывании приложения в контенер прокидываются директории:
  * `/app/etc` - диретория, из котрой приложение забирает конфигурационные файлы.
  * `/app/data` - диретория, в которой приложении сохраняет персистентные данные.
  Содержимое директории гарантированно сохранается при выключении контейнера и
  запуске новой версии.
  * `/app/log` - директория, в которую приложение пришет журныл событий.
* При установке приложение в тестовые и продакшен среды соответствующие конфигурации
помещаются в директорию `/app/etc`. В конфиграции приложения `application.conf`
необходимо переопределять только специфичные для среды нсатройки. Нет необходимости
тащить туда все, что есть в `reference.conf`. `application.conf` переопределяет значения,
объявленные в `reference.conf`. Пример:

  ```scala
  val files = Set(
    "/app/etc/application.conf",
    "./etc/application.conf"
  ).map(new File(_))filter(_.exists())
  log.trace(s"Available configurations $files")

  // get reference config
  val default = ConfigFactory.defaultReference()

  // get config from custom location
  val custom = files.headOption match {
    case Some(file) => ConfigFactory.parseFile(file)
    case _ => ConfigFactory.empty()
  }

  // merge custom and reference config
  custom.withFallback(default).resolve()
  ```
* Все свои зависимости сервис должен находить через Consul.
Для поиска необходимо использовать точку входа `/v1/health/service`. Пример:

  ```scala
  val endpoints = Await.result(
    resolver.getEndpoints(
      name    = serviceName,
      circuit = Some(getConfig.getString("default_circuit")),
      version = None
    )
  )
  log.debug(s"$endpoints")
  ```
* Сервис должен анонсировать в Consul все точки входа, которые он предоставляет.
Анонсировать точку входа необходимо с указанием способа проверки её доступности.

  ```scala
  Await.result(registrator.registerEndpoint(
    id        = s"$serviceName-$profile",
    name      = serviceName,
    circuits  = getConfig.getStringList("circuits").asScala.toList,
    version   = Some(version),
    port      = port,
    address   = hostIpAddress,
    check     = HttpCheck(
      id    = s"$serviceName-$profile-http-check",
      name  = s"$serviceName-$profile-http-check",
      http  = s"http://$hostIpAddress:$port"
    )
  ))
  ```
* При развертывании сервису передаются переменные окружения:
  * `HOST_IP_ADDRESS` - IP адрес хоста, на котором происходит развертывание сервиса.
  По этому адресу можно найти консул.
  * `PROFILE`

