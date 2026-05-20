import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key});

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isEmailVerified = false; //mail veri tabanında kayıtlı mı
  bool _isLoading = false;
  String? _userDocId;

  Future<void> _veritabanindaEmailAra() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      _mesajGoster("Lütfen e-posta adresinizi girin!", Colors.redAccent);
      return;
    } //email kısmı boş bırakılırsa

    setState(() {
      _isLoading = true;
    }); //mail girildiğinde yükleniyor demek için

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get(); //diyo ki kullanıcının mail kayıtlı mı bizde.Kullanıcı bulunursa _isEmailVerified true olacak

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _isEmailVerified = true;
          _userDocId = querySnapshot
              .docs
              .first
              .id; //kullanıcının veritabanındaki Id sini alıyoruz
        });
        _mesajGoster(
          "E-posta doğrulandı! Yeni şifrenizi belirleyin.",
          Colors.green,
        );
      } else {
        _mesajGoster("Kullanıcı bulunamadı!", Colors.redAccent);
      }
    } catch (e) {
      _mesajGoster("Hata: $e", Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sifreyiGuncelle() async {
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _mesajGoster("Lütfen alanları doldurun!", Colors.redAccent);
      return;
    }

    if (newPass != confirmPass) {
      _mesajGoster("Şifreler uyuşmuyor!", Colors.redAccent);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_userDocId != null) {
        await FirebaseFirestore.instance.collection('users').doc(_userDocId).update(
          {'password': newPass},
        ); //users tablosunda _userDocId si şu olan kullanıcının sadece şifresini güncelle

        _mesajGoster("Şifreniz güncellendi!", Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context); //sayfayı kapat
      }
    } catch (e) {
      _mesajGoster("Hata oluştu: $e", Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: renk));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şifre Yenileme"),
        backgroundColor: const Color.fromARGB(255, 108, 221, 74),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        //aşağı kaydırma overflow hatasını engeller
        child: Column(
          children: [
            ClipPath(
              clipper: ResetWaveClipper(),
              child: Container(
                height: 180,
                width: double.infinity,
                color: const Color.fromARGB(255, 108, 221, 74),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const Text(
                    "Şifremi Unuttum",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Visibility(
                    visible: !_isEmailVerified,
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "E-posta Adresi",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _veritabanindaEmailAra,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color.fromARGB(
                              255,
                              108,
                              221,
                              74,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("HESABI DOĞRULA"),
                        ),
                      ],
                    ),
                  ),

                  Visibility(
                    visible: _isEmailVerified, //mail kayıtlıysa
                    child: Column(
                      children: [
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Yeni Şifre",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Yeni Şifre (Tekrar)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                          ),
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sifreyiGuncelle,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color.fromARGB(
                              255,
                              108,
                              221,
                              74,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("ŞİFREYİ GÜNCELLE"),
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

class ResetWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(3 * size.width / 4, size.height - 70);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
