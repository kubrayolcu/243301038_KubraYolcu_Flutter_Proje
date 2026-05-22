import 'package:flutter/material.dart';
import 'package:mobil_app_edu/calendar.dart';
import 'package:mobil_app_edu/profilpage.dart';
import 'package:mobil_app_edu/lessons_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WavyHeader extends StatelessWidget {
  final String baslik;
  final double height;
  final bool showNotification;

  const WavyHeader({
    super.key,
    required this.baslik,
    this.height = 150,
    this.showNotification = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color.fromARGB(255, 108, 221, 74),
        child: Padding(
          padding: EdgeInsets.only(top: height * 0.25, left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 25,
                    color: Color.fromARGB(240, 255, 255, 255),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showNotification)
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(3 * size.width / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);
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

class HomePages extends StatefulWidget {
  final String kullaniciAdi;
  final String kullaniciEmail;
  final String kullaniciRol;

  const HomePages({
    super.key,
    required this.kullaniciAdi,
    required this.kullaniciEmail,
    required this.kullaniciRol,
  });

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  int _secilenIndeks = 0;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    if (widget.kullaniciRol != 'teacher') {
      _silinenDersleriTakipEt();
    }
  }

  void _silinenDersleriTakipEt() {
    FirebaseFirestore.instance
        .collection('registrations')
        .where('studentEmail', isEqualTo: widget.kullaniciEmail.trim())
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          var silinenler = snapshot.docs.where((doc) {
            var d = doc.data();
            return d.containsKey('isDeletedByTeacher') &&
                d['isDeletedByTeacher'] == true;
          });

          if (silinenler.isNotEmpty && !_isDialogShowing) {
            _isDialogShowing = true;
            var ilkSilinenDokuman = silinenler.first;
            String dersAdi = ilkSilinenDokuman['lessonTitle'] ?? 'Bir dersiniz';
            String docId = ilkSilinenDokuman.id;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orangeAccent),
                    SizedBox(width: 8),
                    Text("Ders İptal Edildi!"),
                  ],
                ),
                content: Text(
                  "Kayıtlı olduğunuz '$dersAdi' dersi eğitmen tarafından sistemden kaldırılmıştır.",
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 108, 221, 74),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('registrations')
                          .doc(docId)
                          .delete();

                      if (mounted) {
                        Navigator.pop(context);
                      }
                      _isDialogShowing = false;
                    },
                    child: const Text(
                      "Tamam",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.kullaniciRol == 'teacher';
    String bolumBasligi = "Derslerim";
    String bosMesaj = isTeacher
        ? "Henüz oluşturduğunuz bir ders bulunmuyor."
        : "Henüz kayıt olduğunuz bir ders bulunmuyor.";

    Stream<QuerySnapshot> dersStream = isTeacher
        ? FirebaseFirestore.instance
              .collection('lessons')
              .where('teacherId', isEqualTo: widget.kullaniciEmail.trim())
              .snapshots()
        : FirebaseFirestore.instance
              .collection('registrations')
              .where('studentEmail', isEqualTo: widget.kullaniciEmail.trim())
              .snapshots();

    final List<Widget> sayfalar = [
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WavyHeader(baslik: "Merhaba ${widget.kullaniciAdi}"),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30),
              decoration: BoxDecoration(
                color: const Color.fromARGB(179, 196, 192, 192),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Ders veya konu ara...",
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 104, 100, 100),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 35),
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 15),
              child: Text(
                bolumBasligi,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: dersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    child: Text(
                      bosMesaj,
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    if (!isTeacher &&
                        data.containsKey('isDeletedByTeacher') &&
                        data['isDeletedByTeacher'] == true) {
                      return const SizedBox.shrink();
                    }

                    // Ders Başlığı Ayarı
                    String lessonTitle = isTeacher
                        ? (data['title'] ?? 'Ders Adı')
                        : (data['lessonTitle'] ?? 'Ders Adı');

                    // Tarih ve Saat Alanlarını Çekiyoruz
                    String tarih = data['date'] ?? data['tarih'] ?? '';
                    String saat =
                        data['time'] ?? data['hour'] ?? data['saat'] ?? '';

                    String zamanBilgisi = "";
                    if (tarih.isNotEmpty && saat.isNotEmpty) {
                      zamanBilgisi = "$tarih | $saat";
                    } else if (tarih.isNotEmpty) {
                      zamanBilgisi = tarih;
                    } else if (saat.isNotEmpty) {
                      zamanBilgisi = saat;
                    } else {
                      zamanBilgisi = "Zaman bilgisi eklenmedi";
                    }

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 4.0,
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 108, 221, 74),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            lessonTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          // 🎯 Sadece Tarih ve Saat Bilgisini Gösteren Alan
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Color.fromARGB(255, 108, 221, 74),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  zamanBilgisi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      Calendarpage(),
      LessonsPage(
        kullaniciAdi: widget.kullaniciAdi,
        kullaniciEmail: widget.kullaniciEmail,
        kullaniciRol: widget.kullaniciRol,
      ),
      ProfilPage(
        kullaniciAdi: widget.kullaniciAdi,
        kullaniciEmail: widget.kullaniciEmail,
        kullaniciRol: widget.kullaniciRol,
      ),
    ];

    return Scaffold(
      body: sayfalar[_secilenIndeks],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _secilenIndeks,
        selectedItemColor: const Color.fromARGB(255, 108, 221, 74),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _secilenIndeks = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Dersler',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilim'),
        ],
      ),
    );
  }
}
