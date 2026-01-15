# 📚 KitapDostum - Sosyal Kitap Takip ve Okuma Asistanı

KitapDostum, kitap okuma alışkanlığını dijitalleştiren, oyunlaştırma (gamification) ve sosyal etkileşim ile okumayı teşvik eden kapsamlı bir mobil uygulamadır.

## 🎯 Projenin Amacı ve Senaryosu

**Bu uygulama kime hitap ediyor?**
Kitap okumayı sevenlere, okuma alışkanlığı kazanmak isteyenlere ve kütüphanesini dijital ortamda takip etmek isteyen öğrencilere/bireylere hitap eder.

**Hangi ihtiyacı / problemi çözüyor?**
Fiziksel kütüphanelerin takibinin zorluğu, okuma sürelerinin tutulamaması ve okuma motivasyonunun düşmesi problemlerini çözer. Barkod tarama ile kitapları saniyeler içinde kaydeder.

**Nasıl ve hangi senaryoda kullanılıyor?**
Kullanıcı yeni aldığı bir kitabı barkodunu okutarak kütüphanesine ekler. Okumaya başladığında "Kronometre"yi açarak süresini tutar. Kitabı bitirdiğinde puan kazanır, rozet alır ve bu başarısı "Sosyal Akış" ekranında arkadaşlarıyla otomatik paylaşılır.

## 🛠️ Kullanılan Teknolojiler

* **Dil:** Dart
* **Framework:** Flutter
* **Backend & Veritabanı:** Firebase (Authentication & Cloud Firestore)
* **API:** Google Books API & Open Library API (Kitap verilerini çekmek için)
* **State Management:** Provider
* **Diğer:** Mobile Scanner (Barkod), Shared Preferences (Yerel Ayarlar), Http.

## 📱 Uygulama Ekranları ve Özellikler

✅ **Giriş/Kayıt:** Firebase ile güvenli oturum yönetimi. <br>
✅ **Ana Sayfa:** Kullanıcı istatistikleri, aktif okunan kitap ve gece/gündüz modu. <br>
✅ **Kütüphanem:** Kitapların listelendiği, filtrelendiği ekran. <br>
✅ **Kitap Ekleme:** Barkod tarayarak veya ISBN ile otomatik veri çekme. <br>
✅ **Okuma Sayacı:** Okuma süresini tutan ve kaydeden kronometre. <br>
✅ **Sosyal Akış:** Arkadaşların aktivitelerinin (kitap bitirme, yorum yapma) görüldüğü ekran. <br>
✅ **Profil:** Kazanılan rozetler ve kullanıcı bilgileri. <br>

## 🎥 Tanıtım Videosu

Projenin çalışır halini, barkod okuma ve sosyal akış özelliklerini aşağıdaki videodan detaylıca izleyebilirsiniz:

[**👉 KitapDostum Tanıtım Videosunu İzlemek İçin Tıklayın 👈**](https://www.youtube.com/watch?v=I1Exx8DiI_Q)

---

## 📱 Görseller

Uygulamadan bazı ekran görüntüleri:

<table align="center">
  <tr>
    <td align="center" width="25%">
      <img src="https://github.com/user-attachments/assets/0f5c5622-fa69-4e66-9780-25b6be4360a3" alt="Açılış ve Giriş Ekranı" />
      <br />
      <sub><b>Açılış & Giriş Ekranı</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/user-attachments/assets/21866c72-9702-4e1e-a970-d5047c9afa7e" alt="Ana Sayfa Keşfet" />
      <br />
      <sub><b>Ana Sayfa (Keşfet)</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/user-attachments/assets/540a9f0f-c92d-4ae2-8851-79ed55bac080" alt="Kütüphanem ve Gece Modu" />
      <br />
      <sub><b>Kütüphanem (Gece Modu)</b></sub>
    </td>
    <td align="center" width="25%">
      <img src="https://github.com/user-attachments/assets/12fcf944-cd92-4da2-bf33-67edbef64d22" alt="Menü ve Profil" />
      <br />
      <sub><b>Yan Menü & Profil</b></sub>
    </td>
  </tr>
</table>

---
**Geliştirici:** [Adınız Soyadınız]
**Ders:** Mobil Programlama Final Projesi
