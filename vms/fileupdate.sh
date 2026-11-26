XPATH=~/Downloads/Tang/Stocks/eBest/security
SERVER=ubuntu@52.62.119.114
REMOTE=/var/www/vms
files=(
routes/web.php
app/Services/ItemService.php
app/Models/ItemImage.php
app/Services/ImageService.php
config/filesystems.php
config/vms.php
resources/views/items/show.blade.php
resources/views/staff/items/show.blade.php
resources/views/layouts/base.blade.php
resources/views/items/form.blade.php
resources/views/items/_trim.blade.php
public/vms/css/vms.css
public/vms/images/ebest.png
public/vms/images/logo.png
)
ssh -i $XPATH/SecurityInformServer.pem $SERVER "mkdir -p $REMOTE/config $REMOTE/app/Services $REMOTE/app/Models $REMOTE/resources/views/staff/items $REMOTE/public/vms/css $REMOTE/public/vms/images $REMOTE/resources/views/layouts $REMOTE/resources/views/items"
for file in "${files[@]}"
do
echo "filename: $file"
scp -i $XPATH/SecurityInformServer.pem $file $SERVER:$REMOTE/$file
done
echo "On the server (cd $REMOTE), run:"
echo "  php artisan migrate --force"
echo "  php artisan optimize:clear"
echo "  php artisan queue:restart"
