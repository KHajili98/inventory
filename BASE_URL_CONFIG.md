# Base URL Konfiqurasiyası

## Server-də Base URL Dəyişmək

`build/web` folder-i AWS server-ə deploy etdikdən sonra, base URL-i dəyişmək üçün:

1. Server-ə SSH ilə bağlanın
2. Deploy olunmuş `build/web/config.json` faylını açın:
   ```bash
   nano /path/to/build/web/config.json
   # və ya
   vi /path/to/build/web/config.json
   ```

3. `baseUrl` dəyərini dəyişin:
   ```json
   {
     "baseUrl": "http://yeni-server-adresi:8000"
   }
   ```

4. Faylı yadda saxlayın və bağlayın
5. Brauzerlərdə cache-i təmizləyin və ya səhifəni hard refresh edin (Ctrl+Shift+R / Cmd+Shift+R)

## Nümunə:

**Development server üçün:**
```json
{
  "baseUrl": "http://localhost:8000"
}
```

**Production server üçün:**
```json
{
  "baseUrl": "http://13.53.43.184:8000"
}
```

**Yeni server üçün:**
```json
{
  "baseUrl": "http://54.123.45.67:8000"
}
```

## Qeyd:
- Yenidən build etməyə ehtiyac yoxdur
- Sadəcə `config.json` faylını dəyişin və səhifəni yeniləyin
- Faylın yolunu serverdə tapmaq üçün: `find /var/www -name config.json` (və ya sizin deploy path-iniz)
