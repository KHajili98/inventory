# Deployment Guide

## Build and Deploy to Server

### 1. Build the Flutter Web App

```bash
# Clean previous builds
flutter clean

# Build for production
flutter build web --release
```

### 2. Deploy to Server

The `build/web` folder contains all the files needed for deployment. Upload the entire contents of this folder to your web server.

**Important files in build/web:**
- `index.html` - Main entry point
- `main.dart.js` - Compiled Dart application (4.3MB+)
- `flutter_service_worker.js` - Service worker for caching
- `flutter_bootstrap.js` - Bootstrap script
- `flutter.js` - Flutter engine
- `assets/` - All app assets (fonts, images, etc.)
- `canvaskit/` - CanvasKit rendering engine files
- `icons/` - App icons
- `manifest.json` - Web app manifest

### 3. Server Configuration

#### For Apache (.htaccess)
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>

# Enable compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json
</IfModule>

# Set proper MIME types
AddType application/javascript .js
AddType text/css .css
AddType image/png .png
AddType image/jpeg .jpg
AddType application/json .json
AddType application/wasm .wasm
```

#### For Nginx
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    root /path/to/build/web;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|wasm)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Compress responses
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

### 4. Troubleshooting

If `main.dart.js` is not loading on the server:

1. **Check file upload**: Ensure ALL files from `build/web/` are uploaded, not just some
2. **Check file permissions**: Files should have read permissions (644 for files, 755 for directories)
3. **Check MIME types**: Server must serve `.js` files with `application/javascript` content-type
4. **Check browser console**: Open DevTools to see any 404 or loading errors
5. **Check file size**: `main.dart.js` should be several MB (in this build it's 4.3MB)
6. **Check paths**: Ensure `index.html` correctly references `main.dart.js`
7. **Clear cache**: Clear browser cache and try again
8. **Check .htaccess**: If using Apache, ensure `.htaccess` file is uploaded and mod_rewrite is enabled

### 5. Quick Deployment Commands

```bash
# Build and prepare for deployment
flutter clean && flutter build web --release

# If using rsync to deploy to server:
rsync -avz --delete build/web/ user@yourserver.com:/var/www/html/

# If using FTP, upload the entire build/web/ folder contents
```

### 6. Verify Deployment

After deployment, check:
- Visit your website URL
- Open browser DevTools (F12) → Network tab
- Verify `main.dart.js` loads with HTTP 200 status
- Check file size matches the built file (~4.3MB)
- Ensure no 404 errors in console

### 7. Git Workflow

```bash
# Build the app
flutter build web --release

# Add build files to git
git add -f build/web/

# Commit
git commit -m "Build: Update web build for deployment"

# Push to repository
git push origin main
```

## Notes

- The `build/web/` folder is tracked in git (see `.gitignore`)
- Always run `flutter build web --release` before deploying
- The build is optimized with tree-shaking (fonts reduced by 98%+)
- Some warnings about WebAssembly compatibility are expected (using dart:html)
