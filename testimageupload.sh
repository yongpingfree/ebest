HOST=https://minimall.donkibuy.com
echo "user: $1"
echo "password: $2"
curl -s -c cookies.txt -X POST "$HOST/mgt/api/v1/sessions/login_with_password" \
  -H "Content-Type: application/json" \
  -d '{"mobile":"$1","password":"$2"}'
