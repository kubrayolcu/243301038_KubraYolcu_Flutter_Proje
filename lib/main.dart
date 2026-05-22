import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'password_reset.dart';
import 'wave_header.dart';
import 'package:mobil_app_edu/register_page.dart';
import 'package:flutter/gestures.dart';
import 'package:mobil_app_edu/log_service.dart'; // 🎯 Log servisini buraya import ettik kanka!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RezervEdu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 108, 221, 74),
        ),
      ),
      home: const MyHomePage(title: 'RezervEdu'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _otomatikGirisKontrolEt();
  }

  Future<void> _otomatikGirisKontrolEt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hatirla = prefs.getBool('beni_hatirla');
    String? kayitliEmail = prefs.getString('kayitli_email');
    String? kayitliSifre = prefs.getString('kayitli_sifre');

    if (hatirla == true && kayitliEmail != null && kayitliSifre != null) {
      _emailController.text = kayitliEmail;
      _passwordController.text = kayitliSifre;
      setState(() {
        _rememberMe = true;
      });
      _loginWithFirebase(
        isAutomatic: true,
      ); // Otomatik giriş olduğunu belirtiyoruz kanka
    } else {
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _rememberMe = false;
      });
    }
  }

  // 🎯 Log sistemine uyumlu giriş fonksiyonu
  Future<void> _loginWithFirebase({bool isAutomatic = false}) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Lütfen tüm alanları doldurun!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        String name = "Kullanıcı";
        String role = "student";

        if (querySnapshot.docs.isNotEmpty) {
          var userData = querySnapshot.docs.first.data();
          name = userData['name'] ?? userData['kullaniciAdi'] ?? 'Kullanıcı';
          role = userData['role'] ?? userData['rol'] ?? 'student';
        } else {
          name = email.split('@').first;
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('beni_hatirla', true);
          await prefs.setString('kayitli_email', email);
          await prefs.setString('kayitli_sifre', password);
        } else {
          await prefs.remove('beni_hatirla');
          await prefs.remove('kayitli_email');
          await prefs.remove('kayitli_sifre');
        }

        if (mounted) {
          // 🎯 EN KRİTİK NOKTA: Sayfa yönlenmeden hemen önce log kaydını basıyoruz kanka
          LogService.logYaz(
            email: email,
            adSoyad: name,
            islem: isAutomatic ? "Otomatik Giriş Yapıldı" : "Giriş Yapıldı",
            detay: isAutomatic
                ? "$name ($email) 'Beni Hatırla' ile otomatik giriş yaptı."
                : "$name ($email) sisteme başarılı bir şekilde giriş yaptı.",
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePages(
                kullaniciAdi: name,
                kullaniciEmail: email,
                kullaniciRol: role,
              ),
            ),
          ).then((_) {
            _otomatikGirisKontrolEt();
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        _showErrorSnackBar('Hatalı e-posta veya şifre girdiniz!');
      } else {
        _showErrorSnackBar('Giriş başarısız: ${e.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WaveHeader(height: 280, icon: Icons.person),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const Text(
                    "Giriş Yap",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-posta Adresi",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Şifre",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text("Beni hatırla"),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PasswordReset(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            108,
                            221,
                            74,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        child: const Text("Şifremi Unuttum?"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _loginWithFirebase(isAutomatic: false),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: const Color.fromARGB(255, 108, 221, 74),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("GİRİŞ YAP"),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                      children: [
                        const TextSpan(text: "Hesabınız yoksa "),
                        TextSpan(
                          text: "kaydolun",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 80, 123, 80),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          recognizer: TapGestureRecognizer()
                            ?..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
