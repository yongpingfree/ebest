XPATH=~/Downloads/Tang/Stocks/eBest/security
SERVER=ubuntu@52.62.119.114
REMOTE=/var/www/vms
files=(
.env.example
bootstrap/app.php
routes/web.php
config/app.php
config/filesystems.php
config/vms.php
lang/en.json
lang/en/validation.php
lang/zh/validation.php
database/migrations/2026_11_27_000001_create_vms_brands_categories.php
database/migrations/2026_11_27_000002_add_post_listing_flag_to_items.php
storage/app/categories/categories.csv
database/oms/export_categories.sql
storage/app/categories/.gitignore
app/Console/Commands/LoadCategories.php
app/Http/Controllers/BrandController.php
app/Http/Controllers/ItemController.php
app/Http/Controllers/ProfileController.php
app/Http/Controllers/PurchaseOrderController.php
app/Http/Controllers/VendorAuthController.php
app/Http/Controllers/Staff/BrandController.php
app/Http/Controllers/Staff/ItemController.php
app/Http/Controllers/Staff/VendorController.php
app/Http/Middleware/EnsureVendorApproved.php
app/Http/Middleware/SetVmsLocale.php
app/Mail/VendorSubmittedMail.php
app/Mail/VerificationCodeMail.php
app/Models/Brand.php
app/Models/Category.php
app/Models/Item.php
app/Models/ItemImage.php
app/Models/PurchaseOrder.php
app/Models/Vendor.php
app/Services/ExportService.php
app/Services/ImageService.php
app/Services/ItemService.php
app/Services/PurchaseOrderService.php
resources/views/auth/login.blade.php
resources/views/auth/register.blade.php
resources/views/auth/verify.blade.php
resources/views/brands/_manager.blade.php
resources/views/brands/index.blade.php
resources/views/dashboard.blade.php
resources/views/items/_field.blade.php
resources/views/items/_images.blade.php
resources/views/items/_lightbox.blade.php
resources/views/items/limited.blade.php
resources/views/items/_trim.blade.php
resources/views/items/form.blade.php
resources/views/items/index.blade.php
resources/views/items/show.blade.php
resources/views/layouts/base.blade.php
resources/views/layouts/staff.blade.php
resources/views/layouts/vendor.blade.php
resources/views/pos/_summary.blade.php
resources/views/pos/form.blade.php
resources/views/pos/index.blade.php
resources/views/pos/show.blade.php
resources/views/profile.blade.php
resources/views/staff/brands/index.blade.php
resources/views/staff/items/index.blade.php
resources/views/staff/items/show.blade.php
resources/views/staff/vendors/index.blade.php
resources/views/staff/vendors/show.blade.php
public/vms/css/vms.css
public/vms/images/ebest.png
public/vms/images/logo.png
)
# 自动创建远端目录
dirs=$(for f in "${files[@]}"; do echo "$REMOTE/$(dirname "$f")"; done | sort -u | tr '\n' ' ')
ssh -i $XPATH/SecurityInformServer.pem $SERVER "mkdir -p $dirs"
for file in "${files[@]}"
do
echo "filename: $file"
scp -i $XPATH/SecurityInformServer.pem $file $SERVER:$REMOTE/$file
done
echo "On the server (cd $REMOTE), run:"
echo "  php artisan migrate --force"
echo "  php artisan optimize:clear"
echo "  php artisan queue:restart"
echo "First time only (categories): put the CSV exported by database/oms/export_categories.sql at storage/app/categories/categories.csv, then run:"
echo "  php artisan vms:load-categories"
