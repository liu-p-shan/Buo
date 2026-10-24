import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const SafeMateApp());
}

class SafeMateApp extends StatelessWidget {
  const SafeMateApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF6900),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6900)),
      ),
      home: const LockPage(),
    );
  }
}

class LockPage extends StatefulWidget {
  const LockPage({super.key});
  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> with WidgetsBindingObserver {
  final _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AuthService.instance.lock(); 
    }
  }

  Future<void> _tryUnlock() async {
    final err = await AuthService.instance.unlockWithPin(_pinCtrl.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err == 'Wrong PIN' ? '密码错误' : err)));
    }
  }

  Future<void> _tryBiometric() async {
    final err = await AuthService.instance.unlockWithBiometric();
    if (!mounted) return;
    if (err == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err == 'No biometrics' ? '设备不支持指纹' : '取消或失败')));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Color(0xFFFF6900)),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: '输入 PIN 码', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6900), foregroundColor: Colors.white),
              onPressed: _tryUnlock, 
              child: const Text('PIN 解锁')
            ),
            TextButton(onPressed: _tryBiometric, child: const Text('指纹解锁')),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _notes = [];
  final List<String> _tips = ["定期更换密码", "API Key 千万别截图", "开启双重认证", "警惕钓鱼链接", "数据备份很重要"];
  String _todayTip = "";

  @override
  void initState() {
    super.initState();
    _todayTip = _tips[DateTime.now().day % _tips.length];
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await DbHelper.instance.getAllNotes();
      setState(() => _notes = notes);
    } catch (e) {}
  }

  void _showCompanionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("安全助手"),
        content: const Text("主人，今天也要注意数据安全哦！", textAlign: TextAlign.center),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buo"), backgroundColor: const Color(0xFFFF6900), foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showCompanionDialog,
                    child: TweenAnimationBuilder(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (_, val, child) => Transform.scale(scale: val, child: child),
                      child: const CircleAvatar(radius: 30, backgroundColor: Color(0xFFFF6900), child: Icon(Icons.face, color: Colors.white, size: 40)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text("每日安全提示：\n$_todayTip", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: _notes.isEmpty 
              ? const Center(child: Text("暂无笔记，点击右下角添加"))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, i) => Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(_notes[i]['title']),
                      subtitle: Text(_notes[i]['content']),
                    ),
                  ),
                ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6900),
        foregroundColor: Colors.white,
        onPressed: () async {
          await DbHelper.instance.insertNote("测试笔记", "这是一条加密内容");
          _loadNotes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
