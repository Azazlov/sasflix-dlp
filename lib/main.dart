import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

void main() => runApp(const CupertinoApp(home: DownloaderPage()));

class DownloaderPage extends StatefulWidget {
  const DownloaderPage({super.key});
  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  double progress = 0.0;
  String status = '';
  bool isDownloading = false;
  Directory? saveDir;

  DateTime? startTime;
  Duration? totalDuration;

  Process? _ffmpegProcess;

  void pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => saveDir = Directory(result));
    }
  }

  Future<bool> _onWillPop() async {
    if (isDownloading) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Загрузка не завершена'),
              content: const Text('Вы уверены, что хотите выйти? Загрузка будет прервана.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Выйти'),
                  onPressed: () {
                    _ffmpegProcess?.kill();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  Future<void> startDownload() async {
    String url = urlController.text.trim();
    final idMatch = RegExp(r'(\d+)$').firstMatch(url);
    final id = idMatch?.group(1) ?? '';
    url = "https://free-sasflix.com/api/VideoStream/hls-playlist/$id";
    
    final name = nameController.text.trim();


    if (url.isEmpty || name.isEmpty || saveDir == null) {
      setState(() => status = 'Укажите название, ссылку и директорию');
      return;
    }

    setState(() {
      isDownloading = true;
      status = 'Инициализация...';
      progress = 0.0;
      startTime = DateTime.now();
      totalDuration = null;
    });

    String sanitizeFileName(String input, {String replacement = "_"}) {
      // Заменяем недопустимые символы
      final regex = RegExp(r'[<>:"/\\|?*\x00-\x1F]|[\s]+');
      final sanitized = input.replaceAll(regex, replacement);

      // Удаляем ведущие и завершающие точки/пробелы (актуально для Windows)
      final trimmed = sanitized.replaceAll(RegExp(r'^[\.\s]+|[\.\s]+$'), '');

      // Ограничиваем длину имени (например, 255 символов)
      const maxLength = 255;
      return trimmed.length > maxLength 
          ? trimmed.substring(0, maxLength) 
          : trimmed;
    }

    final outputPath = p.join(saveDir!.path, sanitizeFileName("$name.mp4"));

    _ffmpegProcess = await Process.start('ffmpeg', [
      '-http_persistent', '1',
      '-i', url,
      '-c', 'copy',
      outputPath,
    ]);

    _ffmpegProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.contains('Duration:')) {
        final match = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)').firstMatch(line);
        if (match != null) {
          totalDuration = Duration(
            hours: int.parse(match.group(1)!),
            minutes: int.parse(match.group(2)!),
            seconds: double.parse(match.group(3)!).floor(),
            milliseconds: ((double.parse(match.group(3)!) % 1) * 1000).toInt(),
          );
        }
      }

      if (line.contains('time=')) {
        final match = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)').firstMatch(line);
        if (match != null && totalDuration != null && startTime != null) {
          final current = Duration(
            hours: int.parse(match.group(1)!),
            minutes: int.parse(match.group(2)!),
            seconds: double.parse(match.group(3)!).floor(),
            milliseconds: ((double.parse(match.group(3)!) % 1) * 1000).toInt(),
          );

          final newProgress =
              current.inMilliseconds / totalDuration!.inMilliseconds;

          final elapsed = DateTime.now().difference(startTime!);
          final estimatedTotal = elapsed.inMilliseconds / (newProgress + 0.001);
          final eta = Duration(milliseconds: (estimatedTotal - elapsed.inMilliseconds).toInt());

          setState(() {
            progress = newProgress.clamp(0.0, 1.0);
            status =
                'Скачано: ${(progress * 100).toStringAsFixed(1)}%'
                ' | ETA: ${_formatDuration(eta)}'
                ' | Время: ${_formatDuration(current)} / ${_formatDuration(totalDuration!)}';
          });
        }
      }
    });

    final code = await _ffmpegProcess!.exitCode;

    setState(() {
      isDownloading = false;
      _ffmpegProcess = null;
      progress = code == 0 ? 1.0 : 0.0;
      status = code == 0
          ? '✅ Готово! Сохранено в: $outputPath'
          : '❌ Ошибка: код $code';
    });
  }

  void cancelDownload() {
    _ffmpegProcess?.kill();
    setState(() {
      status = '❌ Загрузка отменена';
      isDownloading = false;
      progress = 0.0;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${h > 0 ? '$h:' : ''}${twoDigits(m)}:${twoDigits(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Скачать .m3u8 видео'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Название видео',
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: urlController,
                  placeholder: 'Ссылка на видео (https://.../video/123)',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: pickDirectory,
                      child: const Text('📁 Папка'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        saveDir?.path ?? 'Не выбрано',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                isDownloading
                    ? Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.destructiveRed,
                              onPressed: cancelDownload,
                              child: const Text('Отмена'),
                            ),
                          ),
                        ],
                      )
                    : CupertinoButton.filled(
                        onPressed: startDownload,
                        child: const Text('Скачать'),
                      ),
                const SizedBox(height: 20),
                if (isDownloading)
                  Column(
                    children: [
                      CupertinoProgressBar(progress: progress),
                      const SizedBox(height: 8),
                      Text(status),
                    ],
                  )
                else
                  Text(status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CupertinoProgressBar extends StatelessWidget {
  final double progress;
  const CupertinoProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
