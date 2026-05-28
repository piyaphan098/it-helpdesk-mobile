# IT Support Helpdesk - Setup Script (Windows PowerShell)
# Run this after installing Flutter: https://docs.flutter.dev/get-started/install

Write-Host "=== IT Support Helpdesk Setup ===" -ForegroundColor Cyan

# Step 1: Generate platform folders (android, ios, web, etc.)
Write-Host "`n[1/4] Generating Flutter platform files..." -ForegroundColor Yellow
flutter create . --org com.ithelpdesk --project-name it_support_helpdesk

# Step 2: Install dependencies
Write-Host "`n[2/4] Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# Step 3: Analyze code
Write-Host "`n[3/4] Running static analysis..." -ForegroundColor Yellow
flutter analyze

# Step 4: Done
Write-Host "`n[4/4] Setup complete!" -ForegroundColor Green
Write-Host @"

NEXT STEPS:
1. Create a Supabase project at https://supabase.com
2. Run supabase/migrations/001_initial_schema.sql in SQL Editor
3. Update lib/core/constants/supabase_constants.dart with your URL and anon key
4. Run: flutter run

"@ -ForegroundColor White
