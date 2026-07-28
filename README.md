# docker_vpn_infrastructure
Набор VPN для установки на новую машину

1) amnezia-xray - разворачивается из клинета Amnezia
2) amnezia-awg2 - разворачивается из клиента Amnezia
3) telemt - Telegram MTProxy
4) dante + stunnel - Socks5 + TLS Proxy
5) naive - NaiveProxy (Caddy + forwardproxy)
6) mieru - MieruProxy (mita)
7) trojan - Trojan (trojan-gfw)
8) hysteria2 - Hysteria2 (apernet/hysteria)
9) node-exporter + cadvisor (+ cadvisor-proxy) - Prometheus метрики хоста и контейнеров

## Мониторинг (node-exporter + cadvisor)

- `node-exporter` отдаёт метрики хоста без авторизации — секретов в них нет, поэтому порт (`NODE_EXPORTER_PORT`, по умолчанию `59900`) публикуется открыто, чтобы внешний Prometheus мог их собирать.
- `cadvisor` (метрики контейнеров) сам по себе наружу не публикуется вообще — доступ к нему только через `cadvisor-proxy`, который поднимает basic-auth перед ним. Логин/пароль задаются в `.env`: `CADVISOR_AUTH_USER` / `CADVISOR_AUTH_PASSWORD`. Наружу опубликован порт `CADVISOR_PORT` (по умолчанию `59901`) уже на `cadvisor-proxy`, а не на `cadvisor`.
- Для Prometheus-конфига, который скрейпит cadvisor, потребуется указать `basic_auth: {username: ..., password: ...}` с этими же значениями.
