import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StorageService();
  await store.init();
  runApp(QuranLiveApp(store: store));
}

class QuranLiveApp extends StatefulWidget {
  final StorageService store;
  const QuranLiveApp({super.key, required this.store});

  @override
  State<QuranLiveApp> createState() => _QuranLiveAppState();
}

class _QuranLiveAppState extends State<QuranLiveApp> {
  final ApiService api = ApiService();
  final QuranAudioService audio = QuranAudioService();
  int tab = 0;

  final titles = const [
    'QuranLive', 'السور', 'المصحف', 'القراء', 'الصلاة', 'الراديو',
    'البث المباشر', 'المفضلة', 'حسابي', 'الإعدادات', 'المساعد الإسلامي'
  ];

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  void go(int index) => setState(() => tab = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(api: api, store: widget.store, go: go),
      SurahsScreen(api: api, audio: audio, store: widget.store),
      MushafScreen(api: api),
      RecitersScreen(api: api, audio: audio),
      PrayerScreen(api: api, store: widget.store),
      RadioScreen(api: api, audio: audio),
      LiveTvScreen(api: api),
      FavoritesScreen(api: api, audio: audio, store: widget.store),
      ProfileScreen(store: widget.store),
      SettingsScreen(store: widget.store, onChanged: () => setState(() {})),
      AiScreen(store: widget.store),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuranLive',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.store.theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: Row(children: const [
            Icon(Icons.mosque), SizedBox(width: 8), Text('QuranLive')
          ]),
          actions: [
            IconButton(
              tooltip: 'المساعد الإسلامي',
              onPressed: () => go(10),
              icon: const Icon(Icons.smart_toy_outlined),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mosque, size: 58),
                      SizedBox(height: 8),
                      Text('QuranLive', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('القرآن الكريم بين يديك'),
                    ],
                  ),
                ),
                for (int i = 0; i < pages.length; i++)
                  ListTile(
                    selected: tab == i,
                    leading: Icon(_icon(i)),
                    title: Text(titles[i]),
                    onTap: () {
                      Navigator.pop(context);
                      go(i);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab <= 4 ? tab : 0,
          onDestinationSelected: (i) => go(i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'السور'),
            NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'المصحف'),
            NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'القراء'),
            NavigationDestination(icon: Icon(Icons.access_time), label: 'الصلاة'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'المساعد الإسلامي',
          onPressed: () => go(10),
          child: const Icon(Icons.smart_toy),
        ),
      ),
    );
  }

  IconData _icon(int i) {
    const icons = [
      Icons.home, Icons.menu_book, Icons.auto_stories, Icons.mic,
      Icons.access_time, Icons.radio, Icons.live_tv, Icons.star,
      Icons.person, Icons.settings, Icons.smart_toy,
    ];
    return icons[i];
  }
}

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xff1a7a2e),
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xffe8f5e9),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xff2ecc71),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xff0a120a),
  );
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final int ayahs;
  final String revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.ayahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    number: j['number'] ?? 0,
    name: j['name'] ?? '',
    englishName: j['englishName'] ?? '',
    ayahs: j['numberOfAyahs'] ?? 0,
    revelationType: j['revelationType'] ?? '',
  );
}

class Reciter {
  final int id;
  final String name;
  final List<Moshaf> moshafs;

  const Reciter({required this.id, required this.name, required this.moshafs});

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
    id: j['id'] ?? 0,
    name: j['name'] ?? '',
    moshafs: ((j['moshaf'] ?? []) as List)
        .map((x) => Moshaf.fromJson(Map<String, dynamic>.from(x)))
        .toList(),
  );
}

class Moshaf {
  final String name, server, surahList, rewaya;
  const Moshaf({required this.name, required this.server, required this.surahList, required this.rewaya});

  factory Moshaf.fromJson(Map<String, dynamic> j) => Moshaf(
    name: j['name'] ?? '',
    server: j['server'] ?? '',
    surahList: j['surah_list'] ?? '',
    rewaya: j['rewaya'] ?? '',
  );
}

class PrayerTimes {
  final String fajr, sunrise, dhuhr, asr, maghrib, isha;
  const PrayerTimes({
    required this.fajr, required this.sunrise, required this.dhuhr,
    required this.asr, required this.maghrib, required this.isha,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> j) {
    final t = j['timings'] ?? j;
    String v(String k) => (t[k] ?? '--:--').toString().split(' ').first;
    return PrayerTimes(
      fajr: v('Fajr'), sunrise: v('Sunrise'), dhuhr: v('Dhuhr'),
      asr: v('Asr'), maghrib: v('Maghrib'), isha: v('Isha'),
    );
  }
}

class StorageService {
  late SharedPreferences p;

  Future<void> init() async => p = await SharedPreferences.getInstance();

  String get theme => p.getString('theme') ?? 'light';
  set theme(String v) => p.setString('theme', v);

  String get language => p.getString('lang') ?? 'ar';
  set language(String v) => p.setString('lang', v);

  String get city => p.getString('city') ?? 'Cairo';
  set city(String v) => p.setString('city', v);

  bool get autoplay => p.getBool('autoplay') ?? false;
  set autoplay(bool v) => p.setBool('autoplay', v);

  List<int> get favorites => p.getStringList('favorites')?.map(int.parse).toList() ?? [];
  set favorites(List<int> v) => p.setStringList('favorites', v.map((e) => '$e').toList());

  Map<String, dynamic> get bookmark {
    final s = p.getString('bookmark');
    return s == null ? {} : Map<String, dynamic>.from(jsonDecode(s));
  }
  set bookmark(Map<String, dynamic> v) => p.setString('bookmark', jsonEncode(v));

  List<Map<String, dynamic>> get chats {
    final s = p.getString('chats');
    if (s == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(s));
  }
  set chats(List<Map<String, dynamic>> v) => p.setString('chats', jsonEncode(v));
}

class ApiService {
  static const mp3 = 'https://mp3quran.net/api/v3';
  static const alquran = 'https://api.alquran.cloud/v1';

  Future<List<Surah>> surahs() async {
    final r = await http.get(Uri.parse('$alquran/surah/quran-uthmani'));
    if (r.statusCode != 200) throw Exception('تعذر تحميل السور');
    final j = jsonDecode(r.body);
    return (j['data'] as List).map((x) => Surah.fromJson(Map<String, dynamic>.from(x))).toList();
  }

  Future<List<Reciter>> reciters(String lang) async {
    final r = await http.get(Uri.parse('$mp3/reciters?language=$lang'));
    if (r.statusCode != 200) throw Exception('تعذر تحميل القراء');
    final j = jsonDecode(r.body);
    return (j['reciters'] as List).map((x) => Reciter.fromJson(Map<String, dynamic>.from(x))).toList();
  }

  Future<Map<String, dynamic>> surahText(int id) async {
    final r = await http.get(Uri.parse('$alquran/surah/$id/quran-uthmani'));
    if (r.statusCode != 200) throw Exception('تعذر تحميل المصحف');
    return Map<String, dynamic>.from(jsonDecode(r.body));
  }

  Future<PrayerTimes> prayerByCity(String city, {String country = 'Egypt'}) async {
    final u = Uri.parse(
      'https://api.aladhan.com/v1/timingsByCity?city=${Uri.encodeComponent(city)}&country=${Uri.encodeComponent(country)}&method=5',
    );
    final r = await http.get(u);
    if (r.statusCode != 200) throw Exception('تعذر تحميل مواقيت الصلاة');
    return PrayerTimes.fromJson(Map<String, dynamic>.from(jsonDecode(r.body)['data']));
  }

  Future<PrayerTimes> prayerByCoords(double lat, double lon) async {
    final u = Uri.parse('https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=5');
    final r = await http.get(u);
    if (r.statusCode != 200) throw Exception('تعذر تحميل مواقيت الصلاة');
    return PrayerTimes.fromJson(Map<String, dynamic>.from(jsonDecode(r.body)['data']));
  }

  Future<List<Map<String, dynamic>>> radios(String lang) async {
    final r = await http.get(Uri.parse('$mp3/radios?language=$lang'));
    if (r.statusCode != 200) throw Exception('تعذر تحميل الإذاعات');
    final j = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(j['radios'] ?? []);
  }

  Future<List<Map<String, dynamic>>> liveTv(String lang) async {
    final r = await http.get(Uri.parse('$mp3/live-tv?language=$lang'));
    if (r.statusCode != 200) throw Exception('تعذر تحميل البث المباشر');
    final j = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(j['livetv'] ?? j['channels'] ?? []);
  }
}

class QuranAudioService {
  final AudioPlayer player = AudioPlayer();
  String? currentTitle;
  String? currentArtist;

  Future<void> play(String url, {String? title, String? artist}) async {
    currentTitle = title;
    currentArtist = artist;
    await player.setUrl(url);
    await player.play();
  }

  Future<void> pause() => player.pause();
  Future<void> resume() => player.play();
  Future<void> stop() => player.stop();
  Future<void> seek(Duration d) => player.seek(d);
  Future<void> dispose() => player.dispose();
}

class HomeScreen extends StatefulWidget {
  final ApiService api;
  final StorageService store;
  final void Function(int) go;
  const HomeScreen({super.key, required this.api, required this.store, required this.go});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerTimes? prayer;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      prayer = await widget.api.prayerByCity(widget.store.city);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🕌 قرآنك معاك في كل وقت', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('استمع للقرآن الكريم، اقرأ المصحف، تابع مواقيت الصلاة واكتشف القراء والإذاعات.'),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => widget.go(1), icon: const Icon(Icons.menu_book), label: const Text('السور')),
            OutlinedButton.icon(onPressed: () => widget.go(2), icon: const Icon(Icons.auto_stories), label: const Text('المصحف')),
            OutlinedButton.icon(onPressed: () => widget.go(4), icon: const Icon(Icons.access_time), label: const Text('الصلاة')),
          ]),
        ],
      ))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text('🌿 آية اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 14),
          Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('سورة الشرح • آية 6', textAlign: TextAlign.center),
        ],
      ))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('🕌 مواقيت الصلاة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextButton(onPressed: () => widget.go(4), child: const Text('التفاصيل')),
          ]),
          if (error != null) Text(error!),
          if (prayer != null)
            Wrap(spacing: 10, runSpacing: 8, children: [
              _chip('الفجر', prayer!.fajr), _chip('الظهر', prayer!.dhuhr), _chip('العصر', prayer!.asr),
              _chip('المغرب', prayer!.maghrib), _chip('العشاء', prayer!.isha),
            ])
          else if (error == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ))),
    ]),
  );

  Widget _chip(String a, String b) => Chip(label: Text('$a  $b'));
}

class SurahsScreen extends StatefulWidget {
  final ApiService api; final QuranAudioService audio; final StorageService store;
  const SurahsScreen({super.key, required this.api, required this.audio, required this.store});

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  late Future<List<Surah>> future;
  String q = '';

  @override
  void initState() {
    super.initState();
    future = widget.api.surahs();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث عن سورة...', border: OutlineInputBorder()),
      onChanged: (v) => setState(() => q = v),
    )),
    Expanded(child: FutureBuilder<List<Surah>>(
      future: future,
      builder: (context, s) {
        if (s.hasError) return Center(child: Text('حدث خطأ: ${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final list = s.data!.where((x) => x.name.contains(q) || x.englishName.toLowerCase().contains(q.toLowerCase())).toList();
        return ListView.builder(itemCount: list.length, itemBuilder: (context, i) {
          final x = list[i];
          final fav = widget.store.favorites.contains(x.number);
          return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(
            leading: CircleAvatar(child: Text('${x.number}')),
            title: Text(x.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${x.englishName} • ${x.ayahs} آية • ${x.revelationType == 'Meccan' ? 'مكية' : 'مدنية'}'),
            trailing: Wrap(children: [
              IconButton(icon: Icon(fav ? Icons.star : Icons.star_border), onPressed: () {
                final f = List<int>.from(widget.store.favorites);
                fav ? f.remove(x.number) : f.add(x.number);
                widget.store.favorites = f;
                setState(() {});
              }),
              IconButton(icon: const Icon(Icons.play_circle), onPressed: () => _play(x)),
            ]),
            onTap: () => _play(x),
          ));
        });
      },
    )),
  ]);

  Future<void> _play(Surah s) async {
    final url = 'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/${s.number}.mp3';
    try {
      await widget.audio.play(url, title: s.name, artist: 'مشاري العفاسي');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التشغيل: $e')));
    }
  }
}

class MushafScreen extends StatefulWidget {
  final ApiService api;
  const MushafScreen({super.key, required this.api});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  int surah = 1;
  Map<String, dynamic>? data;
  double size = 25;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      data = await widget.api.surahText(surah);
    } catch (_) {
      data = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = (data?['data']?['ayahs'] ?? []) as List;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: DropdownButton<int>(
          isExpanded: true,
          value: surah,
          items: List.generate(114, (i) => DropdownMenuItem(value: i + 1, child: Text('سورة ${i + 1}'))),
          onChanged: (v) {
            if (v != null) {
              surah = v;
              load();
            }
          },
        )),
        IconButton(onPressed: () => setState(() => size = (size - 2).clamp(16, 42)), icon: const Text('A-')),
        IconButton(onPressed: () => setState(() => size = (size + 2).clamp(16, 42)), icon: const Text('A+')),
      ])),
      Expanded(child: ayahs.isEmpty ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        itemCount: ayahs.length,
        itemBuilder: (context, i) {
          final a = ayahs[i] as Map;
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text('${a['text']}  ﴿${a['numberInSurah']}﴾', textAlign: TextAlign.right, textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: size, height: 2.0, fontWeight: FontWeight.w500)),
          );
        },
      )),
    ]);
  }
}

class RecitersScreen extends StatefulWidget {
  final ApiService api; final QuranAudioService audio;
  const RecitersScreen({super.key, required this.api, required this.audio});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  late Future<List<Reciter>> f;

  @override
  void initState() {
    super.initState();
    f = widget.api.reciters('ar');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Reciter>>(
    future: f,
    builder: (context, s) {
      if (s.hasError) return Center(child: Text('حدث خطأ: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(itemCount: s.data!.length, itemBuilder: (context, i) {
        final r = s.data![i];
        return Card(margin: const EdgeInsets.all(6), child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.mic)),
          title: Text(r.name),
          subtitle: Text('${r.moshafs.length} رواية/مصدر'),
          trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _play(r)),
        ));
      });
    },
  );

  Future<void> _play(Reciter r) async {
    if (r.moshafs.isEmpty) return;
    final m = r.moshafs.first;
    final base = m.server.endsWith('/') ? m.server : '${m.server}/';
    try {
      await widget.audio.play('${base}001.mp3', title: 'الفاتحة', artist: r.name);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التشغيل: $e')));
    }
  }
}

class PrayerScreen extends StatefulWidget {
  final ApiService api; final StorageService store;
  const PrayerScreen({super.key, required this.api, required this.store});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  PrayerTimes? t;
  String city = 'Cairo';
  String? err;
  final cities = const ['Cairo','Alexandria','Giza','Port Said','Suez','Luxor','Aswan','Mansoura','Tanta','Makkah','Madinah','Riyadh','Jeddah','Dubai','Abu Dhabi','Muscat','Doha','Manama'];

  @override
  void initState() {
    super.initState();
    city = widget.store.city;
    load();
  }

  String _country(String city) {
    if (['Makkah','Madinah','Riyadh','Jeddah'].contains(city)) return 'Saudi Arabia';
    if (['Dubai','Abu Dhabi'].contains(city)) return 'United Arab Emirates';
    if (city == 'Muscat') return 'Oman';
    if (city == 'Doha') return 'Qatar';
    if (city == 'Manama') return 'Bahrain';
    return 'Egypt';
  }

  Future<void> load() async {
    try {
      t = await widget.api.prayerByCity(city, country: _country(city));
      err = null;
    } catch (e) {
      err = e.toString();
    }
    if (mounted) setState(() {});
  }

  Future<void> location() async {
    try {
      var p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final x = await Geolocator.getCurrentPosition();
      t = await widget.api.prayerByCoords(x.latitude, x.longitude);
      err = null;
    } catch (e) {
      err = e.toString();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [
        const Icon(Icons.location_on), const SizedBox(width: 8),
        Expanded(child: DropdownButton<String>(
          isExpanded: true,
          value: cities.contains(city) ? city : cities.first,
          items: cities.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) {
            if (v != null) {
              city = v;
              widget.store.city = v;
              load();
            }
          },
        )),
        IconButton(onPressed: location, icon: const Icon(Icons.my_location)),
      ]),
      if (err != null) Text(err!),
    ]))),
    const SizedBox(height: 12),
    if (t != null)
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _row('الفجر', t!.fajr), _row('الشروق', t!.sunrise), _row('الظهر', t!.dhuhr),
        _row('العصر', t!.asr), _row('المغرب', t!.maghrib), _row('العشاء', t!.isha),
      ])))
    else
      const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
  ]);

  Widget _row(String a, String b) => ListTile(leading: const Icon(Icons.access_time), title: Text(a), trailing: Text(b, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));
}

class RadioScreen extends StatefulWidget {
  final ApiService api; final QuranAudioService audio;
  const RadioScreen({super.key, required this.api, required this.audio});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  late Future<List<Map<String, dynamic>>> f;

  @override
  void initState() {
    super.initState();
    f = widget.api.radios('ar');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: f,
    builder: (context, s) {
      if (s.hasError) return Center(child: Text('حدث خطأ: ${s.error}'));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, childAspectRatio: 3.3),
        itemCount: s.data!.length,
        itemBuilder: (context, i) {
          final x = s.data![i];
          return Card(child: ListTile(
            leading: const Icon(Icons.radio),
            title: Text('${x['name'] ?? 'إذاعة'}'),
            trailing: IconButton(icon: const Icon(Icons.play_circle), onPressed: () {
              final u = x['url'] ?? x['radio_url'];
              if (u != null) widget.audio.play(u.toString(), title: x['name']?.toString() ?? 'إذاعة');
            }),
          ));
        },
      );
    },
  );
}

class LiveTvScreen extends StatefulWidget {
  final ApiService api;
  const LiveTvScreen({super.key, required this.api});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  late Future<List<Map<String, dynamic>>> f;
  VideoPlayerController? ctl;

  @override
  void initState() {
    super.initState();
    f = widget.api.liveTv('ar');
  }

  Future<void> play(String url) async {
    try {
      await ctl?.dispose();
      ctl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctl!.initialize();
      await ctl!.play();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تشغيل القناة: $e')));
    }
  }

  @override
  void dispose() {
    ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    if (ctl != null && ctl!.value.isInitialized)
      AspectRatio(aspectRatio: ctl!.value.aspectRatio, child: Stack(children: [
        VideoPlayer(ctl!),
        Positioned(bottom: 8, right: 8, child: FloatingActionButton.small(
          onPressed: () => ctl!.value.isPlaying ? ctl!.pause() : ctl!.play(),
          child: Icon(ctl!.value.isPlaying ? Icons.pause : Icons.play_arrow),
        )),
      ]))
    else
      const SizedBox(height: 220, child: Center(child: Text('اختر قناة واضغط تشغيل'))),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
      future: f,
      builder: (context, s) {
        if (s.hasError) return Center(child: Text('حدث خطأ: ${s.error}'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(itemCount: s.data!.length, itemBuilder: (context, i) {
          final x = s.data![i];
          final u = (x['url'] ?? x['stream_url'] ?? x['link'] ?? '').toString();
          return Card(child: ListTile(
            leading: const Icon(Icons.live_tv),
            title: Text('${x['name'] ?? 'قناة'}'),
            trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: u.isEmpty ? null : () => play(u)),
          ));
        });
      },
    )),
  ]);
}

class FavoritesScreen extends StatefulWidget {
  final ApiService api; final QuranAudioService audio; final StorageService store;
  const FavoritesScreen({super.key, required this.api, required this.audio, required this.store});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Surah>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.surahs();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Surah>>(
    future: future,
    builder: (context, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final ids = widget.store.favorites.toSet();
      final list = s.data!.where((x) => ids.contains(x.number)).toList();
      if (list.isEmpty) return const Center(child: Text('لا توجد سور في المفضلة بعد'));
      return ListView.builder(itemCount: list.length, itemBuilder: (context, i) {
        final x = list[i];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text('${x.number}')),
          title: Text(x.name),
          subtitle: Text('${x.ayahs} آية'),
          trailing: IconButton(icon: const Icon(Icons.play_circle), onPressed: () => widget.audio.play(
            'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/${x.number}.mp3', title: x.name, artist: 'مشاري العفاسي')),
          onLongPress: () {
            final f = List<int>.from(widget.store.favorites)..remove(x.number);
            widget.store.favorites = f;
            setState(() {});
          },
        ));
      });
    },
  );
}

class ProfileScreen extends StatelessWidget {
  final StorageService store;
  const ProfileScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const CircleAvatar(radius: 40, child: Icon(Icons.mosque, size: 38)),
      const SizedBox(height: 12),
      const Text('مستخدم QuranLive', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const Text('بياناتك الأساسية محفوظة محلياً على جهازك.'),
      const SizedBox(height: 16),
      Wrap(spacing: 10, children: [
        _stat('⭐', 'المفضلة', '${store.favorites.length}'),
        _stat('📖', 'علامة الحفظ', store.bookmark.isEmpty ? '0' : '1'),
      ]),
    ]))),
  ]);

  static Widget _stat(String icon, String title, String value) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
    Text(icon, style: const TextStyle(fontSize: 25)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(title),
  ])));
}

class SettingsScreen extends StatelessWidget {
  final StorageService store; final VoidCallback onChanged;
  const SettingsScreen({super.key, required this.store, required this.onChanged});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Column(children: [
      ListTile(
        title: const Text('🎨 الوضع'),
        trailing: DropdownButton<String>(value: store.theme, items: const [
          DropdownMenuItem(value: 'light', child: Text('☀️ نهاري')),
          DropdownMenuItem(value: 'dark', child: Text('🌙 ليلي')),
        ], onChanged: (v) {
          if (v != null) {
            store.theme = v;
            onChanged();
          }
        }),
      ),
      ListTile(
        title: const Text('🌐 اللغة'),
        trailing: DropdownButton<String>(value: store.language, items: const [
          DropdownMenuItem(value: 'ar', child: Text('العربية')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ], onChanged: (v) {
          if (v != null) {
            store.language = v;
            onChanged();
          }
        }),
      ),
      SwitchListTile(
        title: const Text('▶️ تشغيل السورة التالية تلقائياً'),
        value: store.autoplay,
        onChanged: (v) {
          store.autoplay = v;
          onChanged();
        },
      ),
    ])),
    Card(child: ListTile(leading: const Icon(Icons.privacy_tip), title: const Text('الخصوصية'), subtitle: const Text('المفضلة والإعدادات محفوظة محلياً على الجهاز.'))),
  ]);
}

class AiScreen extends StatefulWidget {
  final StorageService store;
  const AiScreen({super.key, required this.store});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final input = TextEditingController();
  late List<Map<String, String>> msgs;
  bool loading = false;
  static const endpoint = String.fromEnvironment('QURANLIVE_AI_ENDPOINT', defaultValue: '');

  @override
  void initState() {
    super.initState();
    msgs = widget.store.chats.map((x) => {'role': '${x['role']}', 'content': '${x['content']}'}).toList();
  }

  Future<void> send() async {
    final q = input.text.trim();
    if (q.isEmpty || loading) return;
    setState(() {
      msgs.add({'role': 'user', 'content': q});
      loading = true;
      input.clear();
    });
    try {
      if (endpoint.isEmpty) throw Exception('لم يتم ضبط QURANLIVE_AI_ENDPOINT');
      final r = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': q, 'history': msgs}),
      );
      if (r.statusCode < 200 || r.statusCode >= 300) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(r.body);
      if (j['success'] == false) throw Exception(j['error'] ?? 'خطأ');
      msgs.add({'role': 'assistant', 'content': '${j['answer'] ?? j['message'] ?? ''}'});
      widget.store.chats = msgs.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      msgs.add({'role': 'assistant', 'content': 'تعذر الاتصال بالمساعد. اربط API الخاص بك عبر:\n--dart-define=QURANLIVE_AI_ENDPOINT=https://your-api.example'});
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Expanded(child: msgs.isEmpty ? const Center(child: Text('اسأل عن القرآن أو السور أو أحكام التلاوة')) : ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: msgs.length,
      itemBuilder: (context, i) {
        final user = msgs[i]['role'] == 'user';
        return Align(
          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            color: user ? Theme.of(context).colorScheme.primaryContainer : null,
            child: Padding(padding: const EdgeInsets.all(12), child: Text(msgs[i]['content'] ?? '')),
          ),
        );
      },
    )),
    Padding(padding: const EdgeInsets.all(10), child: Row(children: [
      Expanded(child: TextField(controller: input, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'اسأل مساعد QuranLive...', border: OutlineInputBorder()))),
      const SizedBox(width: 6),
      IconButton(onPressed: loading ? null : send, icon: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
    ])),
  ]);
}
