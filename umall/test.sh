H=(-H 'User-Agent: okhttp/4.12.0' -H 'Accept: application/json' -H 'Accept-Language: zh-CN')
B=https://b.umall.com.au/api

# A. Most likely to hold the $45: shop-level and public
# 1. shop detail, with parameter and prefix variants
curl -s "${H[@]}" "$B/v1/shop/detail?shop_id=1"
curl -s "${H[@]}" "$B/v1/shop/detail?id=1"
curl -s "${H[@]}" "$B/v1/shop/detail?shopId=1"
curl -s "${H[@]}" "$B/h5app/wxapp/shop/detail?shop_id=1"
curl -s "${H[@]}" -X POST -H 'Content-Type: application/json' -d '{"shop_id":1}' "$B/v1/shop/detail"

# 2. storefront home (it may carry the shop or freight banner)
curl -s "${H[@]}" "$B/api/storefront/home"
curl -s "${H[@]}" "$B/storefront/home"

# 3. shop ratings and goods
curl -s "${H[@]}" "$B/v1/shop/ratings?shop_id=1"
curl -s "${H[@]}" "$B/v1/goods/recommendByShop?shop_id=1"

# B. Freight calculation: probably needs a login token and an address
T='Authorization: Bearer <token>'   # taken from a captured request
curl -s "${H[@]}" -H "$T" "$B/getFreightFee"
curl -s "${H[@]}" -H "$T" -X POST -H 'Content-Type: application/json' \
  -d '{"shop_id":1,"address_id":123}' "$B/getFreightFee"
curl -s "${H[@]}" -H "$T" "$B/orders/orderDeliveryAddr"

# C. Cart tips: the "还需购买 $X 即可包邮" text, needs login
curl -s "${H[@]}" -H "$T" "$B/user/getCartFreeShippingTips"
curl -s "${H[@]}" -H "$T" -X POST "$B/user/getCartFreeShippingTips"
curl -s "${H[@]}" -H "$T" "$B/user/getCartCouponTips"
curl -s "${H[@]}" -H "$T" "$B/v1/cart/list"
curl -s "${H[@]}" -H "$T" "$B/v1/cart/quantity"

# D. Web-side fallback: the same host your script already uses
echo "page size 1"
curl -s "${H[@]}" "$B/h5app/wxapp/goods/items?item_type=normal&is_point=false&approve_status=onsale%2Conly_show&goodsSort=1&page=1&page_size=1"
echo "free shipping"
curl -s "https://m.umall.com.au/others/pages/free-shipping/free-shipping"
