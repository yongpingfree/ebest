#ubuntu@ip-172-31-200-201:/var/www/fileshare$ sh create_api_token.sh "apiadmin@ebest.com.au" ebest-admin123
#Token valid until 2046-11-10 17:33:52
#Shown once, store it safely:
#1|47QRZ7eGz025bTMrlEHQpFr84DTRAsCb6bcFtuF490a99c2a
#minimall.donkibuy.com
IP=52.62.119.114
curl -s -X GET \
  "https://$IP/apptest/api/v1/items/1" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "User-Agent: okhttp/4.12.0" \
  -H "X-Requested-With: cXom.donkibuy.ebest"

curl -s -X GET \
  "https://$IP/apptest/api/v1/items/1" \
  -H "Authorization: Bearer 47QRZ7eGz025bTMrlEHQpFr84DTRAsCb6bcFtuF490a99c2a" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "User-Agent: okhttp/4.12.0" \
  -H "X-Requested-With: cXom.donkibuy.ebest"
