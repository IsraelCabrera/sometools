# Scripts for anything

These are some scripts that help on daily basis.

### Create certificates for esphome docker

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout nginx/ssl/esphome.local.key \
-out nginx/ssl/esphome.local.crt \
-subj "/C=US/ST=California/L=SanDiego/O=DevOmoikane/CN=localhost"
```
