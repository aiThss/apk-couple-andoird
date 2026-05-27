# Couple Snap - Huong Dan Su Dung Va Deploy

Tai lieu nay ghi lai cach dua app Couple Snap vao su dung that: deploy backend tren Dokploy, cai APK, setup couple code, gui anh, va dung trang admin.

## 1. Thanh Phan Can Co

- MongoDB: luu users, couples, photos metadata.
- API server: thu muc `server/`, deploy bang Docker/Dokploy.
- Admin web: thu muc `admin/`, deploy bang Docker/Dokploy.
- APK Android: file build nam o `build/app/outputs/flutter-apk/app-release.apk`.
- Domain/API URL: nen co dang `https://api.tenmiencuaban.com/api`.

## 2. Deploy Tren Dokploy

### Cach nhanh bang Docker Compose

1. Tao project/app trong Dokploy tu repo nay.
2. Dung file [docker-compose.yml](docker-compose.yml).
3. Tao bien moi truong tu [.env.example](.env.example):

```env
MONGO_ROOT_USERNAME=couple_snap
MONGO_ROOT_PASSWORD=mat-khau-mongo-that-manh
JWT_SECRET=chuoi-random-dai-it-nhat-32-ky-tu
PUBLIC_BASE_URL=https://api.tenmiencuaban.com
ADMIN_EMAIL=admin@tenmiencuaban.com
ADMIN_PASSWORD=mat-khau-admin-that-manh
```

4. Gan domain cho service API, vi du:

```text
https://api.tenmiencuaban.com
```

5. Gan domain cho service admin, vi du:

```text
https://admin.tenmiencuaban.com
```

6. Mo API health check:

```text
https://api.tenmiencuaban.com/api/health
```

Neu tra ve JSON `ok: true` la API da chay.

## 3. Cai App Android

1. Lay APK tai:

```text
build/app/outputs/flutter-apk/app-release.apk
```

2. Chuyen APK sang dien thoai Android va cai dat.
3. Neu Android can quyen, bat `Install unknown apps` cho app file manager/browser dang dung.

## 4. Setup Lan Dau Trong App

Tren man hinh onboarding:

1. `API URL`: nhap URL API cua ban, bat buoc co `/api` o cuoi.

```text
https://api.tenmiencuaban.com/api
```

2. `Ten cua ban`: ten nguoi dang dung may nay.
3. `Ten nguoi ay`: ten partner.
4. `Couple code`: ma rieng cua 2 nguoi, vi du:

```text
MINA-JUN-2026
```

5. `Ngay yeu nhau`: chon ngay bat dau yeu nhau.
6. Bam `Vao app khong can email`, hoac nhap email/mat khau de dung tai khoan co the dang nhap lai.

De 2 may thay anh cua nhau, ca hai phai nhap cung mot `Couple code`.

## 5. Cach Dung App

- Home: hien anh moi nhat tu nguoi yeu.
- Nut camera tron lon: chon/chup anh va gui snap.
- Memories: xem grid anh ky niem da gui.
- Profile: xem avatar 2 nguoi, so ngay yeu, couple code, API URL.
- Nut edit o Profile: sua ten va ngay yeu nhau.
- Dang xuat: Profile -> `Dang xuat`.

## 6. Dung Trang Admin

Mo admin domain, vi du:

```text
https://admin.tenmiencuaban.com
```

Trong o `API URL`, nhap:

```text
https://api.tenmiencuaban.com/api
```

Dang nhap bang:

- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`

Admin co the:

- Xem so luong users/couples/photos.
- Xem danh sach user.
- Block/unblock user.
- Sua ngay yeu nhau cua couple.
- Xoa mem anh khong mong muon.

## 7. Icon Va Store Asset

Icon goc:

```text
logo-heart-pixel.png
```

Regenerate icon app/store:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\tools\generate_brand_assets.ps1
```

Output quan trong:

- `store_assets/play_store_icon_512.png`: icon store nen trong suot.
- `store_assets/app_icon_1024.png`: icon lon nen trong suot.
- `store_assets/feature_graphic_1024x500.png`: anh feature graphic.
- `android/app/src/main/res/mipmap-*/ic_launcher.png`: launcher icon Android.
- `android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png`: adaptive icon foreground da tach nen.

Luu y: Android adaptive icon van co background layer rieng de launcher cat mask icon dung chuan. Foreground trai tim da duoc tach nen den.

## 8. Build APK Moi

Build release:

```powershell
& 'C:\Users\Admin\Downloads\flutter\bin\flutter.bat' build apk --release --dart-define=API_BASE_URL=https://api.tenmiencuaban.com/api
```

Neu chua co domain that, co the build default local:

```powershell
& 'C:\Users\Admin\Downloads\flutter\bin\flutter.bat' build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 9. Loi Thuong Gap

### App bao loi ket noi API

- Kiem tra API URL co `/api` o cuoi chua.
- Mo URL `/api/health` tren trinh duyet.
- Kiem tra domain Dokploy da tro dung service API chua.
- Neu dung HTTP khong phai HTTPS, Android co the chan tren mot so moi truong.

### Hai may khong thay anh cua nhau

- Kiem tra ca hai may co cung `Couple code`.
- Gui anh tu may A, may B bam refresh Home/Memories.
- Kiem tra admin xem photo co duoc tao chua.

### Khong upload duoc anh

- Kiem tra API co volume `UPLOAD_DIR`.
- Kiem tra `PUBLIC_BASE_URL` dung domain API that.
- Kiem tra file anh khong vuot gioi han 10MB.

### MongoDB co can domain rieng khong?

Khong. MongoDB chi nen chay noi bo trong Docker network. Khong gan domain va khong publish port MongoDB ra internet.

### Quen mat khau admin

- Doi `ADMIN_PASSWORD` trong Dokploy env.
- Redeploy API.
