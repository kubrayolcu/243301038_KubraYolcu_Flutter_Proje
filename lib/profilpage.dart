import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'wave_header.dart';
import 'package:mobil_app_edu/log_service.dart'; // 🎯 Log servisini buraya import ettik kanka!

class ProfilPage extends StatefulWidget {
  final String kullaniciAdi;
  final String kullaniciEmail;
  final String kullaniciRol;

  const ProfilPage({
    super.key,
    required this.kullaniciAdi,
    required this.kullaniciEmail,
    required this.kullaniciRol,
  });

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Veritabanından veriler çekilene kadar ekranda duracak alanlar
  String dinamikAdSoyad = "Yükleniyor...";
  String dinamikTelefon = "Yükleniyor...";
  String dinamikCinsiyet = "Yükleniyor...";
  String dinamikYas = "Yükleniyor...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _kullaniciBilgileriniGetir();
  }

  // 🎯 VERİTABANINA TAM UYUMLU DURUMA GETİRİLEN SİHİRLİ FONKSİYON
  Future<void> _kullaniciBilgileriniGetir() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.kullaniciEmail.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userData = querySnapshot.docs.first.data();
        setState(() {
          // 🎯 Firestore'daki field isimlerine (%100 uyuşacak şekilde) bağladık kanka:
          String isim = userData['name'] ?? '';
          String soyisim = userData['surname'] ?? '';

          if (isim.isEmpty && soyisim.isEmpty) {
            dinamikAdSoyad = widget.kullaniciAdi;
          } else {
            dinamikAdSoyad = "$isim $soyisim".trim();
          }

          dinamikTelefon = userData['tel_no'] ?? "Belirtilmemiş";
          dinamikCinsiyet = userData['gender'] ?? "Belirtilmemiş";

          // age alanı int olduğu için çökmesin diye .toString() yapıyoruz
          dinamikYas = userData['age'] != null
              ? userData['age'].toString()
              : "Belirtilmemiş";
          _isLoading = false;
        });
      } else {
        setState(() {
          dinamikAdSoyad = widget.kullaniciAdi;
          dinamikTelefon = "Belirtilmemiş";
          dinamikCinsiyet = "Belirtilmemiş";
          dinamikYas = "Belirtilmemiş";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        dinamikAdSoyad = widget.kullaniciAdi;
        dinamikTelefon = "Hata oluştu";
        dinamikCinsiyet = "Hata oluştu";
        dinamikYas = "Hata oluştu";
        _isLoading = false;
      });
    }
  }

  void _oturumuSonlandir(BuildContext context) async {
    // 🎯 EN KRİTİK NOKTA: Oturum kapanmadan hemen önce "Çıkış Yapıldı" logunu fırlatıyoruz kanka
    try {
      await LogService.logYaz(
        email: widget.kullaniciEmail,
        adSoyad: dinamikAdSoyad == "Yükleniyor..."
            ? widget.kullaniciAdi
            : dinamikAdSoyad,
        islem: "Çıkış Yapıldı",
        detay:
            "Kullanıcı güvenli bir şekilde oturumunu sonlandırarak sistemden çıkış yaptı.",
      );
    } catch (e) {
      print("Log yazma hatası (Çıkış): $e");
    }

    // 🚪 Log yazıldıktan sonra normal çıkış işlemlerine devam ediyoruz kanka:
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print("Çıkış hatası güvenli modu: $e");
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print("Hafıza temizleme hatası: $e");
    }

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(title: 'RezervEdu'),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rolAltGrubu = widget.kullaniciRol.toLowerCase();
    final bool isOgretmen =
        rolAltGrubu == 'teacher' || rolAltGrubu == 'öğretmen';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const WaveHeader(height: 200),
            const SizedBox(height: 10),
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 14),

            // 🎯 İstediğin gibi Ad Soyad öğretmen hesabının üstünde, burada büyük yazıyor!
            Center(
              child: Text(
                _isLoading ? "Yükleniyor..." : dinamikAdSoyad,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                isOgretmen ? "Öğretmen Hesabı" : "Öğrenci Hesabı",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(14),
                ),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol Taraf: Bilgi Başlıkları (Kutunun içinden ad soyad silindi)
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "E-posta:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Telefon No:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Cinsiyet:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Yaş:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sağ Taraf: Veritabanındaki alanlardan çekilen dinamik veriler
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.kullaniciEmail,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dinamikTelefon,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dinamikCinsiyet,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dinamikYas,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _oturumuSonlandir(context),
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Oturumu Sonlandır",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
