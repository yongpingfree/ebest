php artisan tinker --execute="
\$u = App\Models\User::where('email','tester1@ebest.com.au')->first();
dump(\$u?->only('id','email','is_admin','is_active'));
dump(Illuminate\Support\Facades\Hash::check('Test1234', \$u->password));
dump(\$u->canAccessPanel(Filament\Facades\Filament::getPanel('app')));
"
