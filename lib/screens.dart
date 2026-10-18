import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';

const telegramUrl = 'https://t.me/forgeXplatform';
Future<void> openTelegram() =>
    launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication);

String today() {
  final d = DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

int levelOf(int xp) => xp ~/ 100 + 1;

class Quest {
  final String id, title, hint;
  final int xp;
  const Quest(this.id, this.title, this.hint, this.xp);
}

const quests = [
  Quest('checkin', 'Daily check-in', 'Show up today', 20),
  Quest('post', 'Post in the community', 'Share something with members', 30),
  Quest('like3', 'Like 3 posts', 'Support other members', 15),
];

class Perk {
  final int level;
  final String title, desc;
  const Perk(this.level, this.title, this.desc);
}

const perks = [
  Perk(2, 'Ember badge', 'Orange badge next to your name'),
  Perk(3, 'Early access', 'Try new features before everyone'),
  Perk(5, 'Inner circle', 'Join the members-only room'),
  Perk(8, 'Founder status', 'Gold badge and a say in what we build'),
];

class Post {
  final String author, text;
  final int level;
  const Post(this.author, this.text, this.level);
}

const seedPosts = [
  Post('Nova', 'Just hit level 5. Inner circle is a different vibe.', 5),
  Post('Tunde', 'What are you all building this week?', 3),
  Post('Ada', 'Small wins count. Finished my quests before lunch.', 4),
  Post('Kito', 'Welcome to all the new members, glad you are here.', 2),
];

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final c = TextEditingController();
  int step = 0;
  Future<void> go() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', c.text.trim());
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => Shell(name: c.text.trim())));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Center(child: Image.asset('assets/icon.png', width: 180, semanticLabel: 'ForgeX logo')),
              const Spacer(),
              if (step == 0) ...[
                Text('Join the forge.', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Be part of the community. Complete quests, gain XP, level up and unlock perks.',
                    style: TextStyle(color: FX.muted, fontSize: 16)),
                const SizedBox(height: 20),
                TextField(
                    controller: c,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Your name')),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity,
                    child: GradButton('Continue',
                        onTap: c.text.trim().isEmpty ? null : () => setState(() => step = 1))),
              ] else ...[
                Text('Join our Telegram', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Updates, drops and the community live there.',
                    style: TextStyle(color: FX.muted, fontSize: 16)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity,
                    child: GradButton('Join Telegram', icon: Icons.send_rounded, onTap: openTelegram)),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity,
                    child: TextButton(onPressed: go,
                        child: const Text('Continue to ForgeX',
                            style: TextStyle(color: FX.amber, fontSize: 16)))),
              ],
            ]),
          ),
        ),
      );
}

class Shell extends StatefulWidget {
  final String name;
  const Shell({super.key, required this.name});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0, xp = 0, likesToday = 0;
  late SharedPreferences p;
  bool ready = false;
  Set<String> done = {};
  Set<String> liked = {};
  List<Post> mine = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((v) {
      p = v;
      xp = p.getInt('xp') ?? 0;
      done = (p.getStringList('q_${today()}') ?? []).toSet();
      likesToday = p.getInt('l_${today()}') ?? 0;
      mine = (p.getStringList('posts') ?? []).map((t) => Post(widget.name, t, 1)).toList();
      setState(() => ready = true);
    });
  }

  void complete(String id) {
    if (done.contains(id)) return;
    final q = quests.firstWhere((q) => q.id == id);
    final before = levelOf(xp);
    setState(() { done.add(id); xp += q.xp; });
    p.setInt('xp', xp);
    p.setStringList('q_${today()}', done.toList());
    final msg = levelOf(xp) > before
        ? 'Level ${levelOf(xp)} reached!'
        : '+${q.xp} XP  ${q.title}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void like(String key) {
    if (liked.contains(key)) return;
    setState(() { liked.add(key); likesToday++; });
    p.setInt('l_${today()}', likesToday);
    if (likesToday >= 3) complete('like3');
  }

  void addPost(String t) {
    setState(() => mine.insert(0, Post(widget.name, t, levelOf(xp))));
    p.setStringList('posts', mine.map((e) => e.text).toList());
    complete('post');
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator(color: FX.orange)));
    final pages = [
      Community(posts: [...mine, ...seedPosts], liked: liked, onLike: like, onPost: addPost),
      Quests(done: done, xp: xp, onDone: complete),
      Ranks(name: widget.name, xp: xp),
      Me(name: widget.name, xp: xp),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: FX.bg,
        titleSpacing: 16,
        title: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', width: 32, height: 32, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          Text('ForgeX', style: Theme.of(context).textTheme.titleLarge),
        ]),
        actions: [
          IconButton(
              tooltip: 'Telegram community',
              onPressed: openTelegram,
              icon: const Icon(Icons.send_rounded, color: FX.orange)),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: FX.surface2, borderRadius: BorderRadius.circular(20)),
            child: Text('Lv ${levelOf(xp)}  ·  $xp XP',
                style: const TextStyle(fontWeight: FontWeight.w700, color: FX.amber)),
          ),
        ],
      ),
      body: pages[i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum_rounded), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.flag_rounded), label: 'Quests'),
          NavigationDestination(icon: Icon(Icons.leaderboard_rounded), label: 'Ranks'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Me'),
        ],
      ),
    );
  }
}

Widget card({required Widget child, bool glow = false}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: FX.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: glow ? FX.orange : FX.border)),
      child: child,
    );

class Community extends StatelessWidget {
  final List<Post> posts;
  final Set<String> liked;
  final void Function(String) onLike, onPost;
  const Community({super.key, required this.posts, required this.liked,
      required this.onLike, required this.onPost});

  void compose(BuildContext context) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FX.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c, autofocus: true, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Share with the community')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
              child: GradButton('Post', onTap: () {
                if (c.text.trim().isEmpty) return;
                onPost(c.text.trim());
                Navigator.pop(context);
              })),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
            backgroundColor: FX.orange, foregroundColor: Colors.black,
            onPressed: () => compose(context),
            icon: const Icon(Icons.edit_rounded), label: const Text('Post')),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, k) {
            final po = posts[k];
            final key = '${po.author}:${po.text}';
            final l = liked.contains(key);
            return card(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(backgroundColor: FX.orange,
                    child: Text(po.author[0].toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(po.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('Lv ${po.level}', style: const TextStyle(color: FX.amber, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Text(po.text, style: const TextStyle(fontSize: 15)),
                ])),
                IconButton(
                  tooltip: l ? 'Liked' : 'Like',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => onLike(key),
                  icon: Icon(l ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                      color: l ? FX.orange : FX.muted),
                ),
              ]),
            );
          },
        ),
      );
}

class Quests extends StatelessWidget {
  final Set<String> done;
  final int xp;
  final void Function(String) onDone;
  const Quests({super.key, required this.done, required this.xp, required this.onDone});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        Text('Daily quests', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text('Resets every day. XP gets you levels and perks.',
            style: TextStyle(color: FX.muted)),
        const SizedBox(height: 16),
        for (final q in quests)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: card(
              glow: done.contains(q.id),
              child: Row(children: [
                Icon(done.contains(q.id) ? Icons.check_circle_rounded : Icons.flag_outlined,
                    color: done.contains(q.id) ? FX.orange : FX.muted),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(q.hint, style: const TextStyle(color: FX.muted, fontSize: 13)),
                ])),
                if (q.id == 'checkin' && !done.contains('checkin'))
                  TextButton(onPressed: () => onDone('checkin'),
                      child: Text('+${q.xp} XP', style: const TextStyle(color: FX.orange, fontWeight: FontWeight.w800)))
                else
                  Text('+${q.xp} XP', style: const TextStyle(color: FX.amber, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]);
}

class Ranks extends StatelessWidget {
  final String name;
  final int xp;
  const Ranks({super.key, required this.name, required this.xp});
  @override
  Widget build(BuildContext context) {
    final rows = [('Nova', 820), ('Tunde', 510), ('Ada', 430), ('Kito', 190), (name, xp)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Top members', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      for (var k = 0; k < rows.length; k++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: card(
            glow: rows[k].$1 == name,
            child: Row(children: [
              SizedBox(width: 32, child: Text('${k + 1}',
                  style: GoogleFonts.exo2(fontSize: 20, fontWeight: FontWeight.w800, color: FX.amber))),
              Expanded(child: Text(rows[k].$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              Text('${rows[k].$2} XP', style: const TextStyle(color: FX.muted)),
            ]),
          ),
        ),
    ]);
  }
}

class Me extends StatelessWidget {
  final String name;
  final int xp;
  const Me({super.key, required this.name, required this.xp});
  @override
  Widget build(BuildContext context) {
    final lv = levelOf(xp);
    return ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: CircleAvatar(radius: 44, backgroundColor: FX.orange,
          child: Text(name[0].toUpperCase(), style: const TextStyle(
              color: Colors.black, fontSize: 36, fontWeight: FontWeight.w800)))),
      const SizedBox(height: 12),
      Center(child: Text(name, style: Theme.of(context).textTheme.headlineMedium)),
      Center(child: Text('Level $lv', style: const TextStyle(color: FX.amber, fontWeight: FontWeight.w700))),
      const SizedBox(height: 16),
      ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: (xp % 100) / 100, minHeight: 10,
              backgroundColor: FX.surface2, color: FX.orange)),
      const SizedBox(height: 6),
      Center(child: Text('${100 - xp % 100} XP to level ${lv + 1}', style: const TextStyle(color: FX.muted))),
      const SizedBox(height: 20),
      GradButton('Join our Telegram', icon: Icons.send_rounded, onTap: openTelegram),
      const SizedBox(height: 24),
      Text('Perks', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final pk in perks)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: card(
            glow: lv >= pk.level,
            child: Row(children: [
              Icon(lv >= pk.level ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: lv >= pk.level ? FX.orange : FX.muted),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pk.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(pk.desc, style: const TextStyle(color: FX.muted, fontSize: 13)),
              ])),
              Text('Lv ${pk.level}', style: const TextStyle(color: FX.amber)),
            ]),
          ),
        ),
    ]);
  }
}
