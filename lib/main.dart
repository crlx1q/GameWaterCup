import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const WaterCupApp());
}

class WaterCupApp extends StatelessWidget {
  const WaterCupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Cup',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const SplashScreen(),
    );
  }
}

class AppStorage {
  static const _starsKey = 'level_stars';
  static const _soundKey = 'sound_enabled';
  static const _vibrationKey = 'vibration_enabled';

  Future<Map<int, int>> loadStars() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_starsKey) ?? <String>[];
    final map = <int, int>{};
    for (final item in raw) {
      final parts = item.split(':');
      if (parts.length == 2) {
        map[int.tryParse(parts[0]) ?? 0] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return map;
  }

  Future<void> saveStar(int level, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await loadStars();
    map[level] = math.max(map[level] ?? 0, stars);
    final list = map.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_starsKey, list);
  }

  Future<bool> soundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  Future<bool> vibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }
}

class AudioService {
  AudioService._();
  static final instance = AudioService._();
  final _player = AudioPlayer();
  bool soundEnabled = true;

  Future<void> play(String file) async {
    if (!soundEnabled) return;
    await _player.play(AssetSource(file), volume: 0.8);
  }

  Future<void> loop(String file) async {
    if (!soundEnabled) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(file), volume: 0.6);
  }

  Future<void> stop() async {
    await _player.stop();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      final storage = AppStorage();
      AudioService.instance.soundEnabled = await storage.soundEnabled();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_rounded, size: 96, color: Colors.lightBlueAccent),
              SizedBox(height: 16),
              Text('WATER CUP', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Water Cup', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                ),
                child: const Text('Играть'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: const Text('Настройки'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sound = true;
  bool vibro = true;
  final storage = AppStorage();

  @override
  void initState() {
    super.initState();
    () async {
      sound = await storage.soundEnabled();
      vibro = await storage.vibrationEnabled();
      if (mounted) setState(() {});
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Column(
        children: [
          SwitchListTile(
            value: sound,
            title: const Text('Звук'),
            onChanged: (v) async {
              setState(() => sound = v);
              AudioService.instance.soundEnabled = v;
              await storage.setSoundEnabled(v);
            },
          ),
          SwitchListTile(
            value: vibro,
            title: const Text('Вибрация'),
            onChanged: (v) async {
              setState(() => vibro = v);
              await storage.setVibrationEnabled(v);
            },
          ),
        ],
      ),
    );
  }
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  final storage = AppStorage();
  Map<int, int> stars = {};

  @override
  void initState() {
    super.initState();
    storage.loadStars().then((value) {
      setState(() => stars = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор уровня')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: levels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final levelNumber = index + 1;
          final starCount = stars[levelNumber] ?? 0;
          return InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GameScreen(levelIndex: index)))
                .then((_) => storage.loadStars().then((v) => setState(() => stars = v))),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$levelNumber', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < starCount ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final int levelIndex;
  const GameScreen({super.key, required this.levelIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late WaterPuzzleGame game;

  @override
  void initState() {
    super.initState();
    game = WaterPuzzleGame(levelData: levels[widget.levelIndex], levelIndex: widget.levelIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          ValueListenableBuilder<GameHudState>(
            valueListenable: game.hud,
            builder: (_, hud, __) {
              return UILayer(
                state: hud,
                onStart: game.startWater,
              );
            },
          ),
          ValueListenableBuilder<GameResult?>(
            valueListenable: game.result,
            builder: (_, result, __) {
              if (result == null) return const SizedBox.shrink();
              return ResultDialog(
                result: result,
                onRetry: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => GameScreen(levelIndex: widget.levelIndex)),
                  );
                },
                onMenu: () => Navigator.of(context).pop(),
                onNext: () {
                  final next = (widget.levelIndex + 1) % levels.length;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => GameScreen(levelIndex: next)),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class UILayer extends StatelessWidget {
  final GameHudState state;
  final VoidCallback onStart;
  const UILayer({super.key, required this.state, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final ratio = (state.usedLength / state.maxLength).clamp(0.0, 1.0);
    final firstTick = state.star3Threshold / state.maxLength;
    final secondTick = state.star2Threshold / state.maxLength;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Нарисуйте траекторию и нажмите Пуск', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 14,
                  backgroundColor: Colors.white24,
                  color: ratio > secondTick ? Colors.redAccent : Colors.lightBlueAccent,
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * firstTick - 32,
                  child: const Text('|', style: TextStyle(color: Colors.amber)),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * secondTick - 32,
                  child: const Text('|', style: TextStyle(color: Colors.orangeAccent)),
                ),
              ],
            ),
            const Spacer(),
            if (!state.started)
              ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Пуск воды'),
              ),
          ],
        ),
      ),
    );
  }
}

class ResultDialog extends StatefulWidget {
  final GameResult result;
  final VoidCallback onRetry;
  final VoidCallback onMenu;
  final VoidCallback onNext;

  const ResultDialog({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onMenu,
    required this.onNext,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
    return Material(
      color: Colors.black54,
      child: Center(
        child: ScaleTransition(
          scale: Tween(begin: .5, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: controller,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.result.win ? 'Победа!' : 'Поражение', style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        i < widget.result.stars ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(onPressed: widget.onRetry, child: const Text('Повторить')),
                      ElevatedButton(onPressed: widget.onMenu, child: const Text('В меню')),
                      if (widget.result.win) ElevatedButton(onPressed: widget.onNext, child: const Text('Следующий')),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameHudState {
  final double usedLength;
  final double maxLength;
  final double star3Threshold;
  final double star2Threshold;
  final bool started;

  const GameHudState({
    required this.usedLength,
    required this.maxLength,
    required this.star3Threshold,
    required this.star2Threshold,
    required this.started,
  });
}

class GameResult {
  final bool win;
  final int stars;
  const GameResult({required this.win, required this.stars});
}

class WaterPuzzleGame extends Forge2DGame with PanDetector {
  WaterPuzzleGame({required this.levelData, required this.levelIndex})
      : super(gravity: Vector2(0, 18), zoom: 10);

  final LevelData levelData;
  final int levelIndex;
  final hud = ValueNotifier<GameHudState>(const GameHudState(
    usedLength: 0,
    maxLength: 1,
    star3Threshold: 0,
    star2Threshold: 0,
    started: false,
  ));
  final result = ValueNotifier<GameResult?>(null);

  final storage = AppStorage();
  final List<WaterParticle> droplets = [];
  final List<BarrierSegment> barriers = [];
  Vector2? _lastPoint;
  double usedLength = 0;
  bool started = false;
  bool finalized = false;
  int reachedCup = 0;
  int fallenOut = 0;

  static const spawnDrops = 60;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport.add(BackgroundComponent());
    await world.add(ScreenBounds());
    await world.add(PipeComponent(position: levelData.waterStart));
    await world.add(CupComponent(levelData: levelData));
    for (final o in levelData.obstacles) {
      await world.add(StaticObstacle(o));
    }
    await world.add(WaterGooRenderer(this));
    _syncHud();
  }

  void _syncHud() {
    hud.value = GameHudState(
      usedLength: usedLength,
      maxLength: levelData.maxLine,
      star3Threshold: levelData.star3Limit,
      star2Threshold: levelData.star2Limit,
      started: started,
    );
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (started || usedLength >= levelData.maxLine) return;
    _lastPoint = info.eventPosition.game;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (started || usedLength >= levelData.maxLine || _lastPoint == null) return;
    final current = info.eventPosition.game;
    final delta = current - _lastPoint!;
    final distance = delta.length;
    if (distance < 0.35) return;

    final remaining = levelData.maxLine - usedLength;
    final actualDistance = math.min(distance, remaining);
    final dir = delta.normalized();
    final endpoint = _lastPoint! + dir * actualDistance;

    final segment = BarrierSegment(start: _lastPoint!, end: endpoint);
    world.add(segment);
    barriers.add(segment);

    usedLength += actualDistance;
    _lastPoint = endpoint;
    _syncHud();
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _lastPoint = null;
  }

  Future<void> startWater() async {
    if (started) return;
    started = true;
    _syncHud();
    for (int i = 0; i < spawnDrops; i++) {
      Future.delayed(Duration(milliseconds: i * 35), () {
        if (finalized) return;
        final pos = levelData.waterStart + Vector2((math.Random().nextDouble() - .5) * .5, 0);
        final drop = WaterParticle(
          gameRef: this,
          startPosition: pos,
        );
        droplets.add(drop);
        world.add(drop);
      });
    }
  }

  void registerCupHit(WaterParticle drop) {
    if (drop.inCup) return;
    drop.inCup = true;
    reachedCup++;
    _checkState();
  }

  void registerOut(WaterParticle drop) {
    if (drop.outside) return;
    drop.outside = true;
    fallenOut++;
    _checkState();
  }

  void _checkState() {
    if (finalized) return;
    if (reachedCup >= (spawnDrops * 0.5).round() || _topCupReached()) {
      _finish(true);
      return;
    }
    if (fallenOut > (spawnDrops * 0.55).round()) {
      _finish(false);
    }
  }

  bool _topCupReached() {
    final cup = levelData.cupPosition;
    const cupW = 3.2;
    const cupH = 3.8;
    for (final d in droplets) {
      final p = d.body.position;
      if (p.x > cup.x - cupW / 2 && p.x < cup.x + cupW / 2 && p.y < cup.y - cupH + 0.5) {
        return true;
      }
    }
    return false;
  }

  Future<void> _finish(bool win) async {
    finalized = true;
    final stars = win
        ? usedLength <= levelData.star3Limit
            ? 3
            : usedLength <= levelData.star2Limit
                ? 2
                : 1
        : 0;
    if (win) {
      await storage.saveStar(levelIndex, stars);
      if (await AppStorage().vibrationEnabled() && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 80);
      }
    }
    result.value = GameResult(win: win, stars: stars);
  }
}

class BackgroundComponent extends Component with HasGameRef<Forge2DGame> {
  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(gameRef.size.x, gameRef.size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF111827)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }
}

class ScreenBounds extends BodyComponent {
  @override
  Body createBody() {
    final shape = ChainShape();
    shape.createLoop([
      Vector2.zero(),
      Vector2(40, 0),
      Vector2(40, 80),
      Vector2(0, 80),
    ]);
    final bodyDef = BodyDef()..position = Vector2.zero();
    final body = world.createBody(bodyDef);
    body.createFixture(FixtureDef(shape));
    return body;
  }
}

class PipeComponent extends PositionComponent {
  PipeComponent({required this.position});
  final Vector2 position;

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = Colors.blueGrey.shade300;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(position.x * 10 - 20, position.y * 10 - 6, 40, 24), const Radius.circular(8)),
      p,
    );
  }
}

class CupComponent extends BodyComponent {
  CupComponent({required this.levelData});
  final LevelData levelData;

  @override
  Body createBody() {
    final pos = levelData.cupPosition;
    final body = world.createBody(BodyDef()..position = pos);

    final wallLeft = PolygonShape()..setAsBoxXY(0.15, 2, Vector2(-1.6, -1.8), 0);
    final wallRight = PolygonShape()..setAsBoxXY(0.15, 2, Vector2(1.6, -1.8), 0);
    final bottom = PolygonShape()..setAsBoxXY(1.6, 0.15, Vector2(0, 0), 0);

    body.createFixture(FixtureDef(wallLeft));
    body.createFixture(FixtureDef(wallRight));
    body.createFixture(FixtureDef(bottom));
    return body;
  }

  @override
  void render(Canvas canvas) {
    final c = levelData.cupPosition;
    final r = Rect.fromCenter(center: Offset(c.x * 10, c.y * 10 - 18), width: 36, height: 42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white70,
    );
  }
}

class StaticObstacle extends BodyComponent {
  final ObstacleData obstacle;
  StaticObstacle(this.obstacle);

  @override
  Body createBody() {
    final bodyDef = BodyDef()..position = Vector2(obstacle.x, obstacle.y);
    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBoxXY(
        obstacle.w / 2,
        obstacle.h / 2,
        Vector2.zero(),
        obstacle.angle,
      );
    body.createFixture(FixtureDef(shape, friction: 0.2, restitution: 0.05));
    return body;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(obstacle.x * 10, obstacle.y * 10);
    canvas.rotate(obstacle.angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: obstacle.w * 10, height: obstacle.h * 10),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white12,
    );
    canvas.restore();
  }
}

class BarrierSegment extends BodyComponent {
  final Vector2 start;
  final Vector2 end;
  BarrierSegment({required this.start, required this.end});

  @override
  Body createBody() {
    final mid = (start + end) / 2;
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final len = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);

    final body = world.createBody(BodyDef()
      ..position = mid
      ..type = BodyType.static);

    final shape = PolygonShape()..setAsBoxXY(len / 2, 0.12, Vector2.zero(), 0);
    body.createFixture(FixtureDef(shape, friction: 0.08, restitution: 0.01));
    body.angle = angle;
    return body;
  }

  @override
  void render(Canvas canvas) {
    final mid = (start + end) / 2;
    canvas.save();
    canvas.translate(mid.x * 10, mid.y * 10);
    canvas.rotate(math.atan2(end.y - start.y, end.x - start.x));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: (end - start).length * 10, height: 4),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white70,
    );
    canvas.restore();
  }
}

class WaterParticle extends BodyComponent {
  final WaterPuzzleGame gameRef;
  final Vector2 startPosition;
  bool inCup = false;
  bool outside = false;

  WaterParticle({required this.gameRef, required this.startPosition});

  @override
  Body createBody() {
    final body = world.createBody(BodyDef()
      ..type = BodyType.dynamic
      ..position = startPosition
      ..linearDamping = 0.03);
    body.createFixture(
      FixtureDef(
        CircleShape()..radius = 0.18,
        density: 1,
        friction: 0.02,
        restitution: 0.02,
      ),
    );
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (body.position.y > 75) {
      gameRef.registerOut(this);
    }
    final cup = gameRef.levelData.cupPosition;
    if (body.position.x > cup.x - 1.5 &&
        body.position.x < cup.x + 1.5 &&
        body.position.y < cup.y &&
        body.position.y > cup.y - 3.6) {
      gameRef.registerCupHit(this);
    }
  }

  @override
  void render(Canvas canvas) {}
}

class WaterGooRenderer extends Component {
  final WaterPuzzleGame game;
  WaterGooRenderer(this.game);

  @override
  void render(Canvas canvas) {
    final layerRect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    canvas.saveLayer(
      layerRect,
      Paint()
        ..imageFilter = ImageFilter.blur(sigmaX: 6, sigmaY: 6)
        ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcOver),
    );
    for (final d in game.droplets) {
      final p = d.body.position;
      final shader = const LinearGradient(
        colors: [Color(0xFF7DD3FC), Color(0xFF2563EB)],
      ).createShader(Rect.fromCircle(center: Offset(p.x * 10, p.y * 10), radius: 8));
      canvas.drawCircle(
        Offset(p.x * 10, p.y * 10),
        3.2,
        Paint()..shader = shader,
      );
    }
    canvas.restore();
  }
}

class LevelData {
  final Vector2 waterStart;
  final Vector2 cupPosition;
  final List<ObstacleData> obstacles;
  final double maxLine;
  final double star3Limit;
  final double star2Limit;

  const LevelData({
    required this.waterStart,
    required this.cupPosition,
    required this.obstacles,
    required this.maxLine,
    required this.star3Limit,
    required this.star2Limit,
  });
}

class ObstacleData {
  final double x;
  final double y;
  final double w;
  final double h;
  final double angle;
  const ObstacleData(this.x, this.y, this.w, this.h, this.angle);
}

List<LevelData> buildLevels() {
  final data = <LevelData>[];
  for (int i = 0; i < 50; i++) {
    final tier = i ~/ 10;
    final waterX = 5 + (i % 5) * 1.5;
    final cupX = 7 + ((i * 3) % 8);
    final cupY = 70 - (i % 3) * 2;
    final obstacles = <ObstacleData>[];

    obstacles.add(ObstacleData(10, 18 + (i % 5), 8, 0.6, (i % 2 == 0 ? 0.18 : -0.18)));

    if (tier >= 1) {
      obstacles.add(ObstacleData(16, 28, 7, 0.6, -0.4));
      obstacles.add(ObstacleData(5, 34, 5, 0.6, 0.35));
    }
    if (tier >= 2) {
      obstacles.add(ObstacleData(11, 42, 10, 0.6, 0.08));
      obstacles.add(ObstacleData(3 + (i % 4), 50, 6, 0.6, -0.5));
      obstacles.add(ObstacleData(18 - (i % 4), 56, 6, 0.6, 0.5));
    }
    if (tier >= 3) {
      obstacles.add(ObstacleData(8, 24, 0.6, 12, 0));
      obstacles.add(ObstacleData(14, 35, 0.6, 12, 0));
      obstacles.add(ObstacleData(10, 46, 0.6, 10, 0));
      obstacles.add(ObstacleData(12, 57, 0.6, 10, 0));
    }
    if (tier >= 4) {
      for (int s = 0; s < 7; s++) {
        obstacles.add(ObstacleData(4 + (s % 3) * 6, 20 + s * 7, 5.5, 0.6, s.isEven ? 0.55 : -0.55));
      }
    }

    data.add(
      LevelData(
        waterStart: Vector2(waterX, 6),
        cupPosition: Vector2(cupX, cupY),
        obstacles: obstacles,
        maxLine: 26 - tier * 2.5,
        star3Limit: 12 - tier * 0.9,
        star2Limit: 18 - tier * 1.1,
      ),
    );
  }
  return data;
}

final levels = buildLevels();
