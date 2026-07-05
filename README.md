# docker_vpn_infrastructure
Набор VPN для установки на новую машину

1) amnezia-xray - разворачивается из клинета Amnezia
2) amnezia-awg2 - разворачивается из клиента Amnezia
3) telemt - Telegram MTProxy
4) dante + stunnel - Socks5 + TLS Proxy
5) naive - NaiveProxy (Caddy + forwardproxy)
6) mieru - MieruProxy (mita)
7) trojan - Trojan (trojan-gfw)
8) node-exporter + cadvisor - Prometheus метрики хоста и контейнеров

## Trojan

Trojan маскирует трафик под обычный HTTPS и работает на TLS-сертификате, который уже выпускает контейнер `naive` для домена `NAIVE_DOMAIN`. Отдельный домен/почта для trojan не нужны — сертификат и ключ монтируются из тома `naive-data` в режиме только для чтения.

### Настройка

1. В `.env` укажите:
   - `TROJAN_PORT` — порт, на котором слушает trojan (по умолчанию `40443`);
   - `TROJAN_USER_PASSWORD` — пароль первого пользователя. Trojan аутентифицирует только по паролю (поле `password` — массив строк в конфиге), логина/имени пользователя у него нет. Если пароль не задан, при первом запуске он будет сгенерирован автоматически и выведен в лог контейнера (`docker compose logs trojan`).
2. Убедитесь, что `naive` запущен и уже получил сертификат для `NAIVE_DOMAIN` — `trojan` при старте ждёт появления файлов сертификата (до ~4 минут), после чего завершится с ошибкой, если сертификат так и не появился.
3. Запустите сервис: `docker compose up -d naive trojan`.

Параметры подключения клиента: адрес — `NAIVE_DOMAIN`, порт — `TROJAN_PORT`, пароль — `TROJAN_USER_PASSWORD`, SNI — `NAIVE_DOMAIN`.

### Как добавить пользователя

Trojan поддерживает несколько паролей одновременно (без привязки к имени пользователя). Чтобы добавить ещё одного пользователя:

1. Откройте `trojan/config.json.tmpl` и добавьте ещё одну строку в массив `password`, например:
   ```json
   "password": [
       "TROJAN_USER_PASSWORD",
       "пароль-второго-пользователя"
   ],
   ```
2. Пересоздайте контейнер: `docker compose up -d --build trojan`.

`TROJAN_USER_PASSWORD` (первый пользователь) продолжит браться из `.env`, остальные пароли — это просто статичные строки в шаблоне.