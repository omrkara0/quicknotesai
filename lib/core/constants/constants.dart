class AppConstants {
  // Sayfa Başlıkları
  static const String appTitle = 'Quick Notes AI';
  static const String homePageTitle = 'Notlarım';
  static const String settingsTitle = 'Ayarlar';
  static const String aboutTitle = 'Hakkında';
  static const String createNoteTitle = 'Not Oluştur';
  static const String editNoteTitle = 'Notu Düzenle';
  static const String createImageNoteTitle = 'Resimli Not Oluştur';

  // Kategoriler
  static const String allCategory = 'Tümü';
  static const String importantCategory = 'Önemli';
  static const String todoCategory = 'Yapılacaklar';
  static const String dailyCategory = 'Günlük';
  static const String favoritesCategory = 'Favoriler';
  static const String categoryLabel = 'Kategori: ';

  // Ayarlar
  static const String themeSetting = 'Tema';
  static const String darkTheme = 'Koyu Tema';
  static const String lightTheme = 'Açık Tema';
  static const String aboutSetting = 'Hakkında';
  static const String version = 'Sürüm: 1.0.0';

  // Diyalog Metinleri
  static const String deleteCategoryTitle = 'Kategori Sil';
  static const String deleteCategoryConfirm =
      'Bu kategoriyi silmek istediğinizden emin misiniz?';
  static const String deleteNoteTitle = 'Notu Sil';
  static const String deleteNoteConfirm =
      'Bu notu silmek istediğinizden emin misiniz?';
  static const String addCategoryTitle = 'Kategori Ekle';
  static const String addCategoryHint = 'Kategori adını girin';
  static const String categoryEmptyError = 'Kategori adı boş olamaz';
  static const String cancel = 'İptal';
  static const String delete = 'Sil';
  static const String close = 'Kapat';
  static const String add = 'Ekle';
  static const String lockedNoteTitle = 'Kilitli Not';
  static const String lockedNoteMessage = '🔒 Bu not kilitlidir';
  static const String lockedNoteDescription =
      'Bu not kilitlidir. Görüntülemek için PIN kodunu giriniz.';
  static const String wrongPinCode = 'Yanlış PIN kodu. Tekrar deneyin.';
  static const String pinCodeLabel = 'PIN Kodu';
  static const String pinCodeHint = '4 haneli PIN kodu';
  static const String pinCodeLengthError = 'PIN kodu 4 haneli olmalıdır';
  static const String pinCodeDigitsError =
      'PIN kodu sadece rakamlardan oluşmalıdır';

  // Form Metinleri
  static const String titleHint = 'Başlık';
  static const String noteContentHint = 'Notunuzu buraya yazın...';
  static const String extractedTextLabel = 'Çıkarılan Metin:';
  static const String addImageHint = 'Resim eklemek için dokunun';
  static const String addImageText = 'Resim ekleyerek metin çıkarın';

  // Kilit İşlemleri
  static const String lockTooltip = 'Kilitle';
  static const String unlockTooltip = 'Kilidi Kaldır';
  static const String lockTitle = 'Notu Kilitle';
  static const String lockButtonText = 'Kilitle';
  static const String lockedMessage = 'Not kilitlendi';
  static const String unlockedMessage = 'Not kilidi kaldırıldı';

  // Hata Mesajları
  static const String errorCreatingNote = 'Not oluşturulurken hata oluştu: ';
  static const String errorDeletingNote = 'Not silinirken hata oluştu: ';
  static const String errorGeneratingSummary =
      'Özet oluşturulurken hata oluştu: ';
  static const String errorPickingImage = 'Resim seçilirken hata oluştu: ';
  static const String errorProcessingImage = 'Resim işlenirken hata oluştu: ';
  static const String errorUpdatingNote = 'Not güncellenirken hata oluştu: ';
  static const String errorAnalyzingEmotion =
      'Duygu analizi yapılırken hata oluştu: ';

  // Uygulama Açıklaması
  static const String appDescription =
      'Quick Notes AI, notlarınızı hızlı ve kolay bir şekilde yönetmenizi sağlayan bir uygulamadır.';

  // Resim İşlemleri
  static const String chooseFromGallery = 'Galeriden Seç';
  static const String takePhoto = 'Fotoğraf Çek';
  static const String addAnother = 'Başka Ekle';
  static const String errorPrefix = 'Hata: ';

  // Not İşlemleri
  static const String summarize = 'Özetle';
  static const String analyzeEmotion = 'Duygu Analizi';

  // Duygu Analizi
  static const String keywords = 'Anahtar Kelimeler';
  static const String emotion = 'emotion';
  static const String intensity = 'intensity';
  static const String keywordsKey = 'keywords';
  static const String suggestion = 'suggestion';
}
