files=(
database/migrations/2026_11_10_120000_add_permissions_to_users_table.php app/Support/Permissions.php settings/permissions.json
config/fileshare.php app/Models/User.php app/Filament/Resources/Users/Schemas/UserForm.php app/Filament/Resources/Users/Pages/ListUsers.php
)
files_old=(
app/Providers/Filament/AdminPanelProvider.php
app/Providers/Filament/AppPanelProvider.php
app/Providers/AppServiceProvider.php
app/Filament/Auth/Login.php
app/Filament/Auth/AppLogin.php
app/Models/User.php
app/Models/PdfSetting.php
app/Models/PdfSettingHistory.php
app/Services/PdfSettingsService.php
app/Console/Commands/CheckUser.php
app/Console/Commands/RotatePdfPasswords.php
app/Filament/Resources/Users/UserResource.php
app/Filament/Resources/Users/Pages/ListUsers.php
app/Filament/Resources/Users/Pages/CreateUser.php
app/Filament/Resources/Users/Pages/EditUser.php
app/Filament/Resources/Users/Schemas/UserForm.php
app/Filament/Resources/Users/Tables/UsersTable.php
app/Filament/Pages/PdfSettings.php
app/Filament/Pages/UploadFiles.php
app/Filament/App/Pages/Files.php
app/Http/Controllers/AdminUploadController.php
app/Http/Controllers/BulkDownloadController.php
app/Jobs/ProcessSharedFile.php
config/logging.php
routes/console.php
routes/web.php
resources/views/filament/pages/pdf-settings.blade.php
resources/views/filament/pages/upload-files.blade.php
resources/views/filament/app/pages/files.blade.php
database/migrations/2026_11_10_000001_create_pdf_settings_tables.php
database/migrations/2026_11_10_100000_add_role_to_users_table.php
database/migrations/2026_11_10_110000_add_last_login_at_to_users_table.php
)
for file in "${files[@]}"
do
echo "filename: $file"
scp -i SecurityInformServer.pem fileshare/$file ubuntu@52.62.119.114:/var/www/fileshare/$file
done
