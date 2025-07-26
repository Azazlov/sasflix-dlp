# 🎬 Flutter Video Downloader (Sasflix-dlp)

Это простое Flutter-приложение для загрузки видео с сайта free-sasflix.com по ссылке на видео. Поддерживает выбор директории, отображение прогресса, скорости загрузки и примерного времени завершения.

## 🖥 Требования для Windows

Для корректной работы необходимо установить:

- Flutter SDK  
- ffmpeg (для скачивания и конвертации видео)

---

## ✅ Установка FFmpeg на Windows

1. Перейдите на официальный сайт загрузки FFmpeg:  
   👉 [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)

2. Найдите раздел Release builds и скачайте "ffmpeg-release-essentials.zip".

3. Распакуйте архив в любую удобную папку, например:  
   C:\ffmpeg

4. После распаковки, убедитесь, что внутри лежит путь:  
   C:\ffmpeg\bin\ffmpeg.exe

5. Добавьте ffmpeg в системный PATH:
   - Нажмите Win + S и найдите "Переменные среды" → нажмите "Изменить переменные среды системы"
   - В разделе "Системные переменные" найдите Path, нажмите Изменить
   - Нажмите Создать и вставьте путь:  
     C:\ffmpeg\bin
   - Нажмите ОК во всех окнах

6. Проверьте установку:
   - Откройте Командную строку (cmd)
   - Введите команду:  
     
     ffmpeg -version
     
   - Вы должны увидеть информацию о версии ffmpeg

---

## 🚀 Запуск Flutter-приложения

1. Установите Flutter SDK с сайта:  
   👉 [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)

2. Откройте проект в VS Code или через командную строку

3. Выполните:  
   ```bash
   flutter pub get
   flutter run
