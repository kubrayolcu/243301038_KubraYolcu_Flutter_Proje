import 'package:flutter/material.dart';
import 'package:mobil_app_edu/home_page.dart'; // WavyHeader buradan geliyor
import 'package:cloud_firestore/cloud_firestore.dart';

class Calendarpage extends StatelessWidget {
  final List<String> gunler = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

  // 🎯 Mayıs 2026 Bilgileri
  final int baslangicBosluk =
      4; // 1 Mayıs Cuma olduğu için ilk 4 kutu (Pzt-Per) boş kalacak kanka
  final int toplamGun = 31; // Mayıs ayı 31 çeker

  Calendarpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const WavyHeader(baslik: "Takvimim"),

          // 🎯 Sütun Üstündeki Gün İsimleri (Pazartesi, Salı...)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: gunler.map((gun) {
                return Expanded(
                  child: Text(
                    gun,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 🎯 Takvim Kutuları ve Firebase Entegrasyonu
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Firebase 'lessons' koleksiyonundan Mayıs ayındaki dersleri anlık dinliyoruz kanka
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .snapshots(),
              builder: (context, snapshot) {
                // Dersleri gün sayılarına göre gruplamak için bir Map oluşturuyoruz
                Map<int, List<Map<String, dynamic>>> gunlukDersler = {};

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;

                    // Firestore'da tarih alanı 'date' veya 'lessonDate' olarak tutuluyorsa (Örn: "2026-05-01" veya "01.05.2026")
                    String dersTarihi =
                        data['date'] ?? data['lessonDate'] ?? '';

                    if (dersTarihi.isNotEmpty) {
                      try {
                        // "2026-05-15" gibi Yıl-Ay-Gün formatı için ayıklama:
                        if (dersTarihi.contains('-')) {
                          DateTime parsedDate = DateTime.parse(dersTarihi);
                          if (parsedDate.year == 2026 &&
                              parsedDate.month == 5) {
                            int gun = parsedDate.day;
                            if (!gunlukDersler.containsKey(gun))
                              gunlukDersler[gun] = [];
                            gunlukDersler[gun]!.add(data);
                          }
                        }
                        // "15.05.2026" gibi gün.ay.yıl formatı kullandıysan burası çalışır:
                        else if (dersTarihi.contains('.')) {
                          var parcalar = dersTarihi.split('.');
                          int gun = int.parse(parcalar[0]);
                          int ay = int.parse(parcalar[1]);
                          int yil = int.parse(parcalar[2]);
                          if (yil == 2026 && ay == 5) {
                            if (!gunlukDersler.containsKey(gun))
                              gunlukDersler[gun] = [];
                            gunlukDersler[gun]!.add(data);
                          }
                        }
                      } catch (e) {
                        debugPrint("Tarih dönüşüm hatası: $e");
                      }
                    }
                  }
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  // Toplam kutu sayısı = Baştaki boşluklar + Mayıs ayının 31 günü
                  itemCount: baslangicBosluk + toplamGun,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio:
                        0.6, // Kutuların diklemesine uzaması için oranı ayarladım kanka
                  ),
                  itemBuilder: (context, index) {
                    // Eğer index başlangıç boşluğundan küçükse oralara boş kutu koyuyoruz
                    if (index < baslangicBosluk) {
                      return const SizedBox.shrink();
                    }

                    // Ayın kaçıncı günü olduğunu hesaplıyoruz (1, 2, 3... 31)
                    int ayinGunu = index - baslangicBosluk + 1;
                    var oGununDersListesi = gunlukDersler[ayinGunu] ?? [];

                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFAED581),
                          width: 1.5,
                        ),
                        // Eğer o güne hoca ders eklediyse rengi bir tık koyulaştırıp belli edebiliriz
                        color: oGununDersListesi.isNotEmpty
                            ? const Color(0xFFA8E6CF)
                            : const Color(0xFFC8E6C9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🎯 Kutunun Sol Üstünde Ayın Günü Yazıyor
                          Text(
                            ayinGunu.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // 🎯 O güne ait dersler listeleniyor
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: oGununDersListesi.length,
                              itemBuilder: (context, dersIndex) {
                                var dersVerisi = oGununDersListesi[dersIndex];

                                // Firestore alan adlarına göre eşitleme (teacherName ve lessonTitle/title)
                                String dersAdi =
                                    dersVerisi['title'] ??
                                    dersVerisi['lessonTitle'] ??
                                    'Ders';
                                String hocaAdi =
                                    dersVerisi['teacherName'] ??
                                    dersVerisi['teacherId'] ??
                                    'Hoca';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 3),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      200,
                                      108,
                                      221,
                                      74,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dersAdi,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        hocaAdi,
                                        style: const TextStyle(
                                          fontSize: 7,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
