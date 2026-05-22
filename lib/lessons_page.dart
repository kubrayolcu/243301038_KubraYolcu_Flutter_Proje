import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobil_app_edu/log_service.dart'; // 🎯 Merkezi log servisimiz

class LessonsPage extends StatefulWidget {
  final String kullaniciAdi;
  final String kullaniciEmail;
  final String kullaniciRol;

  const LessonsPage({
    super.key,
    required this.kullaniciAdi,
    required this.kullaniciEmail,
    required this.kullaniciRol,
  });

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  // 🏫 Sınıf Seçenekleri
  final List<String> _sinifSecenekleri = [
    'Pusula',
    'Ufuk',
    'Albatros',
    'Petek',
    'Günışığı',
    'Bulut',
  ];

  String? _secilenSinif;
  DateTime? _secilenTarih;
  TimeOfDay? _secilenSaat;

  void _dersFormunuGoster({
    String? lessonId,
    String? mevcutBaslik,
    String? mevcutAciklama,
    String? mevcutKapasite,
    String? mevcutTarih,
    String? mevcutSaat,
    String? mevcutSinif,
  }) {
    if (lessonId != null) {
      _titleController.text = mevcutBaslik ?? '';
      _descController.text = mevcutAciklama ?? '';
      _capacityController.text = mevcutKapasite ?? '';

      _secilenSinif = _sinifSecenekleri.contains(mevcutSinif)
          ? mevcutSinif
          : null;

      _secilenTarih = mevcutTarih != null
          ? DateTime.tryParse(mevcutTarih)
          : null;
      if (mevcutSaat != null && mevcutSaat.contains(':')) {
        final parts = mevcutSaat.split(':');
        _secilenSaat = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        _secilenSaat = null;
      }
    } else {
      _titleController.clear();
      _descController.clear();
      _capacityController.clear();
      _secilenSinif = null;
      _secilenTarih = null;
      _secilenSaat = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(lessonId == null ? "Yeni Ders Ekle" : "Dersi Düzenle"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Ders Başlığı",
                        hintText: "Örn: Mobil Programlama",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Açıklama",
                        hintText: "Ders içeriği hakkında kısa bilgi",
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 🎯 Tipi <String> olarak netleştirerek IDE hatasını çözdük kanka:
                    DropdownButtonFormField<String>(
                      value: _secilenSinif,
                      hint: const Text("Sınıf / Derslik Seçin"),
                      decoration: const InputDecoration(
                        labelText: "Sınıf / Derslik",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _sinifSecenekleri.map((String sinif) {
                        return DropdownMenuItem<String>(
                          value: sinif,
                          child: Text(sinif),
                        );
                      }).toList(),
                      onChanged: (String? yeniDeger) {
                        setDialogState(() {
                          _secilenSinif = yeniDeger;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Kontenjan",
                        hintText: "Örn: 30",
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _secilenTarih == null
                                ? "Tarih Seçilmedi"
                                : "Tarih: ${_secilenTarih!.toLocal().toString().split(' ')[0]}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                _secilenTarih = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text("Seç"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _secilenSaat == null
                                ? "Saat Seçilmedi"
                                : "Saat: ${_secilenSaat!.format(context)}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                _secilenSaat = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 18),
                          label: const Text("Seç"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String title = _titleController.text.trim();
                  String desc = _descController.text.trim();
                  int cap = int.tryParse(_capacityController.text) ?? 10;

                  if (title.isEmpty || desc.isEmpty || _secilenSinif == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Lütfen tüm alanları doldurun!"),
                      ),
                    );
                    return;
                  }

                  if (_secilenTarih == null || _secilenSaat == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Lütfen ders tarihi ve saatini seçin kanka!",
                        ),
                      ),
                    );
                    return;
                  }

                  String formatliTarih = _secilenTarih!
                      .toLocal()
                      .toString()
                      .split(' ')[0];
                  String formatliSaat =
                      "${_secilenSaat!.hour.toString().padLeft(2, '0')}:${_secilenSaat!.minute.toString().padLeft(2, '0')}";

                  if (lessonId == null) {
                    // ➕ YENİ DERS EKLEME
                    await FirebaseFirestore.instance.collection('lessons').add({
                      'title': title,
                      'description': desc,
                      'classroom': _secilenSinif,
                      'capacity': cap,
                      'teacherId': widget.kullaniciEmail,
                      'teacherName': widget.kullaniciAdi,
                      'lessonDate': formatliTarih,
                      'lessonTime': formatliSaat,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // 🎯 Senin LogService yapına tam uydurduk kanka (email, adSoyad, islem, detay):
                    await LogService.logYaz(
                      email: widget.kullaniciEmail,
                      adSoyad: widget.kullaniciAdi,
                      islem: 'Ders Oluşturuldu',
                      detay: "'$title' isimli yeni bir ders sisteme eklendi.",
                    );
                  } else {
                    // ✏️ DERSİ DÜZENLEME
                    await FirebaseFirestore.instance
                        .collection('lessons')
                        .doc(lessonId)
                        .update({
                          'title': title,
                          'description': desc,
                          'classroom': _secilenSinif,
                          'capacity': cap,
                          'lessonDate': formatliTarih,
                          'lessonTime': formatliSaat,
                        });

                    await LogService.logYaz(
                      email: widget.kullaniciEmail,
                      adSoyad: widget.kullaniciAdi,
                      islem: 'Ders Düzenlendi',
                      detay:
                          "ID'si $lessonId olan ders güncellendi. Yeni Sınıf: $_secilenSinif, Zaman: $formatliTarih $formatliSaat",
                    );
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(lessonId == null ? "Ekle" : "Güncelle"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _dersSilOnayiniGoster(String lessonId, String lessonTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Dersi Sil?"),
          ],
        ),
        content: Text(
          "Sileyim mi bak gidiyoooo!\n\n'$lessonTitle' dersi tamamen silinecek.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Hayır, Gitmesin",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                var registrationsQuery = await FirebaseFirestore.instance
                    .collection('registrations')
                    .where('lessonId', isEqualTo: lessonId)
                    .get();

                for (var doc in registrationsQuery.docs) {
                  await doc.reference.update({'isDeletedByTeacher': true});
                }
              } catch (e) {
                print("Öğrenci kayıtları işaretlenirken hata: $e");
              }

              await FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(lessonId)
                  .delete();

              // 🎯 Ders Silme Logu
              await LogService.logYaz(
                email: widget.kullaniciEmail,
                adSoyad: widget.kullaniciAdi,
                islem: 'Ders Silindi',
                detay:
                    "'$lessonTitle' dersi öğretmen tarafından sistemden tamamen silindi.",
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "'$lessonTitle' dersi başarıyla silindi kanka!",
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              "Evet, Sil Gitsin",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _derseKayitOl(String lessonId, String lessonTitle) async {
    await FirebaseFirestore.instance.collection('registrations').add({
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'studentEmail': widget.kullaniciEmail,
      'studentName': widget.kullaniciAdi,
      'registeredAt': FieldValue.serverTimestamp(),
    });

    // 🎯 Derse Kayıt Olma Logu
    await LogService.logYaz(
      email: widget.kullaniciEmail,
      adSoyad: widget.kullaniciAdi,
      islem: 'Derse Kayıt Olundu',
      detay: "${widget.kullaniciAdi}, '$lessonTitle' dersine kayıt oldu.",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$lessonTitle dersine başarıyla kaydoldunuz!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String rolTemiz = widget.kullaniciRol.toLowerCase().trim();
    final bool isTeacher = rolTemiz == 'teacher' || rolTemiz == 'öğretmen';

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 108, 221, 74),
              onPressed: () => _dersFormunuGoster(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Projedeki WavyHeader / WaveHeader ismine göre kontrol edersin kanka
          Container(
            height: 120,
            width: double.infinity,
            color: const Color.fromARGB(255, 108, 221, 74),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 30.0),
                child: Text(
                  "Dersler",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lessons')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Henüz eklenmiş bir ders yok."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    String title = data['title'] ?? 'Ders';
                    String desc = data['description'] ?? '';
                    int cap = data['capacity'] ?? 10;
                    String teacherId = data['teacherId'] ?? '';
                    String lDate = data['lessonDate'] ?? 'Belirtilmedi';
                    String lTime = data['lessonTime'] ?? 'Belirtilmedi';
                    String classroom = data['classroom'] ?? 'Belirtilmedi';

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color.fromARGB(255, 108, 221, 74),
                          child: Icon(
                            Icons.bookmark_added,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Text(
                          "$desc\nYer: $classroom\nZaman: $lDate - Saat: $lTime\nKapasite: $cap kişi\nEğitmen: ${data['teacherName'] ?? 'Belirtilmemiş'}",
                        ),
                        isThreeLine: true,
                        trailing: isTeacher
                            ? (teacherId == widget.kullaniciEmail
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () => _dersFormunuGoster(
                                            lessonId: docId,
                                            mevcutBaslik: title,
                                            mevcutAciklama: desc,
                                            mevcutKapasite: cap.toString(),
                                            mevcutTarih: lDate,
                                            mevcutSaat: lTime,
                                            mevcutSinif: classroom,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _dersSilOnayiniGoster(
                                                docId,
                                                title,
                                              ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      "Diğer",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ))
                            : ElevatedButton(
                                onPressed: () => _derseKayitOl(docId, title),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    108,
                                    221,
                                    74,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text("Kaydol"),
                              ),
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
