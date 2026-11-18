# SSL keystore / truststore for fileshare

Cert: CN=ebest.com.au (SAN: ebest.com.au, *.ebest.com.au), Amazon RSA 2048 M04 → Amazon Root CA 1, valid until 2027-03-16.
The private key (`1私钥.txt`) is password-encrypted, so it must be built with your password.

## Generate (on your Mac)
    cd ssl_certs && ./build_keystore.sh
Outputs in `ssl_certs/out/` (git-ignored): `keystore.p12` (key+cert+chain), `truststore.p12` (Amazon CAs), `fullchain.pem`, `privkey.pem`.

## Deploy to the fileshare server (ubuntu, /var/www/fileshare)
fileshare is Laravel (PHP) behind a web server, which uses the PEM files; the .p12 files are for Java clients (e.g. Android/OMS/WMS) and are only stored.

1. Copy: `scp out/fullchain.pem out/privkey.pem out/keystore.p12 out/truststore.p12 ubuntu@52.62.119.114:/tmp/`
2. On server: `sudo mkdir -p /etc/ssl/ebest && sudo mv /tmp/{fullchain.pem,privkey.pem,*.p12} /etc/ssl/ebest/`
   `sudo chown root:root /etc/ssl/ebest/* && sudo chmod 600 /etc/ssl/ebest/privkey.pem /etc/ssl/ebest/*.p12`
3. Nginx site config (`/etc/nginx/sites-enabled/*`):
       ssl_certificate     /etc/ssl/ebest/fullchain.pem;
       ssl_certificate_key /etc/ssl/ebest/privkey.pem;
   (Apache: `SSLCertificateFile` / `SSLCertificateKeyFile`.)
4. `sudo nginx -t && sudo systemctl reload nginx`
5. Laravel: set `APP_URL=https://<your host under ebest.com.au>` in `.env`, then
   `php artisan optimize:clear && php artisan queue:restart`
6. Java clients: `-Djavax.net.ssl.keyStore=/etc/ssl/ebest/keystore.p12 -Djavax.net.ssl.keyStorePassword=*** -Djavax.net.ssl.keyStoreType=PKCS12`
   and `-Djavax.net.ssl.trustStore=/etc/ssl/ebest/truststore.p12 ... -Djavax.net.ssl.trustStoreType=PKCS12`
7. Verify: `openssl s_client -connect <host>:443 -servername <host> | openssl x509 -noout -dates`

Notes: the current URL uses IP 52.62.119.114, which this cert does not cover; use a *.ebest.com.au hostname (DNS A record → server) or browsers will warn. Renew before 2027-03-16.
