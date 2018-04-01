# thin

Минималистичный инструмент деплоя для приложений в Docker контейнерах.
 
## Функциональность
 
* Запускает Docker контейнеры приложения на узлах.
* Предоставляет актуальные конфигурации приложения из Consul.
* Генерирует настройки для Nginx прокси. 
 
## Зависимости

* [Consul](https://www.consul.io/) должен быть установлен на хосте, на который будет происходить развертывание. Можно сделать с помощью соответствующего Chef [рецепта](https://github.com/LiveTex/Livetex-Platform/tree/master/cookbooks/consul). 
* [Docker](https://www.docker.com/) можно установить с помощью [рецепта](https://github.com/LiveTex/Livetex-Platform/tree/master/cookbooks/docker). 
* [git2consul](https://github.com/Cimpress-MCP/git2consul) должен быть установлен на один из продакшен серверов. В тестовых средах, можно установить на машину тестировщика/разработчика.

## Подготовка приложения к развертыванию

* Если приложению требуется слушать TCP/UDP соединения, слушать необходимо на ip 0.0.0.0.
* Приложение самостоятельно должно [регистрироваться](https://github.com/LiveTex/Livetex-Model/tree/master/docs/service-announcement.md) в Consul.
* IP адрес узла на котором происходит развертывание передаются в приложение переменными окружения. По этому адресу будет доступен Consul Agent:

  ```bash
  $ env
  HOST_IP_ADDRESS=10.0.2.15
  ```

## Подготовка инфраструктуры для развертывания

1. Создать репозиторий с конфигурациями приложений. Структура каталогов репозитория:

 ```bash
 <service-name>/<profile_name>/<config_file>
 ```
2. Устанавливаем:

 ```bash
 $ npm install -g git2consul
 ```
3. Создать конфигурационный файл для `git2consul` - `git2consul.json`

  ```javascript
  {
    "version": "1.0",
    "repos" : [{
      "name" : "configs",
      "url" : "https://github.com/LiveTex/Configurations",
      "branches" : ["master"],
      "hooks": [{
        "type" : "polling",
        "interval" : "1"
      }]
    }]
  }
  ```
4. Запускаем:

 ```bash
 $ git2consul --endpoint consul.service.consul --port 3004 --config-file ./git2consul.json
 ```

## Добавление сервиса для развертывания

1. Конечным артефактом сборки сервиса должен быть `docker` образ. Задается параметром `image` в Chef роли.  
2. Запускаемое приложени должно самостоятельно регистрироваться в `consul` кластере и 
искать там свои зависимости. Требования по формату регистрации описаны 
[здесь](https://github.com/LiveTex/Livetex-Model/edit/master/docs/service-discovery-and-balancing.md).
3. Приложение должно получать свои конфигурационные файлы из одной директории. 
Задается параметром `conf_path` в Chef роли. 
4. Приложение должно записывать свои логи в одну директорию. 
Задается параметром `log_path` в Chef роли.
5. Приложение должно записывать свои персистентные данные в одну директорию. 
Задается параметром `data_path` в Chef роли.
6. Конфигурационные файлы приложения для сред должны храниться в git репозитории 
[LiveTex/Configurations](https://github.com/LiveTex/Configurations).
7. Имена конфигурационных файлов, которые необходимо передать приложению задаются переметром `configs` в Chef роли.
8. Для каждого профиля развертывания сервиса создается отдельная Chef-роль следующего содержания:

  ```javascript
  {
    "name": "<service-name>-<profile-name>",
    "description": "Deployment profile <profile-name> for <service-name>",
    "json_class": "Chef::Role",
    
    "override_attributes": {
      "thin": {
        "<service-name>": {
          "<profile-name>": {
            "image": "dh.livetex.ru/service/scala-deploy",  
            "version": "0.0.1",
            "command": "/bin/bash start_service.sh",
            "conf_path": "/app/etc",
            "log_path": "/app/log",
            "data_path": "/app/data",
            "configs": [
              "application.conf",
              "logging.xml"  
            ]
          }  
        }        
      }  
    },
    "chef_type": "role",
    "run_list": [
      "recipe[thin::deploy]"
    ]
  }
  ```

## Подготовка узла к развертыванию 
Выполняется системными администраторами.

1. Установка Chef-Client'а.
2. Установка Docker, Nginx, Consul. Можно сделать Chef-рецептами:

  ```javascript
  "run_list": [
    "recipe[ltx_base]",
    "recipe[docker]",
    "recipe[docker_proxy]",
    "recipe[consul::standalone]"
  ]
  ```
3. Добавит хосту соответствующие атрибуты:

  ```javascript
  "default_attributes": {
    "deploy": {
      "path": "/home/livetex/chef",
      "user": "livetex",
      "group": "livetex",
      "nginx_path": "/etc/nginx",
      "consul_url": "http://consul.service.consul:3004/v1/kv/configs/master"
    }
  }
  ```

* `path` - путь к директории, которая будет использована в процессе работы приложения. 
Туда будут сохранятся конфигурации, записываться логи и персистентные данные.
* `user` - пользователь использующийся в процессе деплоя.
* `group` - группа использующаяся в процессе деплоя.
* `nginx_path` - путь к конфигурации nginx.
* `consul_url` - префикс адреса конфигурационных файлов в Consul.

## Развертывание сервиса 
Выполняется разработчиками в тестовых окружениях. Системными администраторами в продакшен окружениях.

1. Закоммитить конфигурационные файлы в [LiveTex/Livetex-Chef/thin](https://github.com/LiveTex/Livetex-Chef/tree/master/thin).
2. Обновить конфигурации в Consul с помощью утилиты `git2consul`.
3. Добаваляем обновленную роль в Chef-Server.
4. Выполняем chef-client на сервере.
