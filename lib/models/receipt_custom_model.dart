import 'dart:convert';

/// Posisi Logo pada struk thermal 58mm
enum ReceiptLogoPosition {
  top('top', 'Paling Atas (Sebelum Nama Toko)'),
  afterHeader('after_header', 'Setelah Header (Sebelum Info Nota)'),
  beforeItems('before_items', 'Sebelum Daftar Barang'),
  afterTotal('after_total', 'Setelah Total Belanja'),
  bottom('bottom', 'Paling Bawah (Di Footer)');

  final String code;
  final String label;
  const ReceiptLogoPosition(this.code, this.label);

  static ReceiptLogoPosition fromCode(String? code) {
    return ReceiptLogoPosition.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ReceiptLogoPosition.top,
    );
  }
}

/// Perataan Logo pada kertas 58mm
enum ReceiptLogoAlign {
  left('left', 'Rata Kiri'),
  center('center', 'Tengah'),
  right('right', 'Rata Kanan');

  final String code;
  final String label;
  const ReceiptLogoAlign(this.code, this.label);

  static ReceiptLogoAlign fromCode(String? code) {
    return ReceiptLogoAlign.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ReceiptLogoAlign.center,
    );
  }
}

/// Ukuran Logo pada kertas 58mm (max 384 dot)
enum ReceiptLogoSize {
  small('small', 'Kecil (140 px)', 140),
  medium('medium', 'Sedang (220 px)', 220),
  full('full', 'Lebar Penuh (360 px)', 360);

  final String code;
  final String label;
  final int pixelWidth;
  const ReceiptLogoSize(this.code, this.label, this.pixelWidth);

  static ReceiptLogoSize fromCode(String? code) {
    return ReceiptLogoSize.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ReceiptLogoSize.medium,
    );
  }
}

/// Gaya Garis Pemisah (32 karakter untuk 58mm)
enum ReceiptDividerStyle {
  dash('dash', 'Garis Putus (- - -)', '--------------------------------'),
  dot('dot', 'Titik (. . .)', '................................'),
  star('star', 'Bintang (* * *)', '********************************'),
  equal('equal', 'Garis Ganda (= = =)', '================================');

  final String code;
  final String label;
  final String pattern;
  const ReceiptDividerStyle(this.code, this.label, this.pattern);

  static ReceiptDividerStyle fromCode(String? code) {
    return ReceiptDividerStyle.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ReceiptDividerStyle.dash,
    );
  }
}

/// Model Kustomisasi Struktur Struk 58mm
class ReceiptCustomModel {
  // --- LOGO SETTINGS ---
  bool showLogo;
  String? logoPath;
  String? logoPreset;
  ReceiptLogoPosition logoPosition;
  ReceiptLogoAlign logoAlignment;
  ReceiptLogoSize logoSize;

  // --- HEADER SETTINGS ---
  String storeName;
  String storeNameSize;
  bool showAddress;
  String storeAddress;
  bool showContact;
  String storeContact;
  bool showHeaderNote;
  String headerNote;

  // --- TRANSACTION INFO ---
  bool showInvoiceNumber;
  bool showDate;
  bool showTime;
  bool showCashierName;
  String cashierName;
  bool showCustomerName;
  ReceiptDividerStyle dividerStyle;

  // --- ITEMS TABLE ---
  bool compactItemRows;

  // --- TOTALS & PAYMENT ---
  bool showSubtotalRow;
  bool showTax;
  double taxPercent;
  bool showDiscount;
  bool showPaymentMethod;
  bool showCashAndChange;

  // --- FOOTER SETTINGS ---
  bool showFooterMessage;
  String footerMessage;
  bool showWarrantyNotice;
  String warrantyNotice;
  bool showSocialMedia;
  String socialMediaText;
  bool showInvoiceQr;

  ReceiptCustomModel({
    this.showLogo = true,
    this.logoPath,
    this.logoPreset = 'store',
    this.logoPosition = ReceiptLogoPosition.top,
    this.logoAlignment = ReceiptLogoAlign.center,
    this.logoSize = ReceiptLogoSize.medium,
    this.storeName = 'NANDA POS',
    this.storeNameSize = 'large',
    this.showAddress = true,
    this.storeAddress = 'Pusat Aksesoris & Servis HP',
    this.showContact = true,
    this.storeContact = 'WhatsApp: 0812-3456-7890',
    this.showHeaderNote = true,
    this.headerNote = 'Solusi Belanja Hemat & Terpercaya',
    this.showInvoiceNumber = true,
    this.showDate = true,
    this.showTime = true,
    this.showCashierName = true,
    this.cashierName = 'Kasir Utama',
    this.showCustomerName = false,
    this.dividerStyle = ReceiptDividerStyle.dash,
    this.compactItemRows = false,
    this.showSubtotalRow = true,
    this.showTax = false,
    this.taxPercent = 11.0,
    this.showDiscount = false,
    this.showPaymentMethod = true,
    this.showCashAndChange = true,
    this.showFooterMessage = true,
    this.footerMessage = 'Terima Kasih Atas Kunjungan Anda!',
    this.showWarrantyNotice = true,
    this.warrantyNotice = 'Klaim garansi wajib menunjukkan struk ini.',
    this.showSocialMedia = true,
    this.socialMediaText = 'Follow IG: @nandapos_id',
    this.showInvoiceQr = true,
  });

  ReceiptCustomModel copyWith({
    bool? showLogo,
    String? logoPath,
    String? logoPreset,
    ReceiptLogoPosition? logoPosition,
    ReceiptLogoAlign? logoAlignment,
    ReceiptLogoSize? logoSize,
    String? storeName,
    String? storeNameSize,
    bool? showAddress,
    String? storeAddress,
    bool? showContact,
    String? storeContact,
    bool? showHeaderNote,
    String? headerNote,
    bool? showInvoiceNumber,
    bool? showDate,
    bool? showTime,
    bool? showCashierName,
    String? cashierName,
    bool? showCustomerName,
    ReceiptDividerStyle? dividerStyle,
    bool? compactItemRows,
    bool? showSubtotalRow,
    bool? showTax,
    double? taxPercent,
    bool? showDiscount,
    bool? showPaymentMethod,
    bool? showCashAndChange,
    bool? showFooterMessage,
    String? footerMessage,
    bool? showWarrantyNotice,
    String? warrantyNotice,
    bool? showSocialMedia,
    String? socialMediaText,
    bool? showInvoiceQr,
  }) {
    return ReceiptCustomModel(
      showLogo: showLogo ?? this.showLogo,
      logoPath: logoPath ?? this.logoPath,
      logoPreset: logoPreset ?? this.logoPreset,
      logoPosition: logoPosition ?? this.logoPosition,
      logoAlignment: logoAlignment ?? this.logoAlignment,
      logoSize: logoSize ?? this.logoSize,
      storeName: storeName ?? this.storeName,
      storeNameSize: storeNameSize ?? this.storeNameSize,
      showAddress: showAddress ?? this.showAddress,
      storeAddress: storeAddress ?? this.storeAddress,
      showContact: showContact ?? this.showContact,
      storeContact: storeContact ?? this.storeContact,
      showHeaderNote: showHeaderNote ?? this.showHeaderNote,
      headerNote: headerNote ?? this.headerNote,
      showInvoiceNumber: showInvoiceNumber ?? this.showInvoiceNumber,
      showDate: showDate ?? this.showDate,
      showTime: showTime ?? this.showTime,
      showCashierName: showCashierName ?? this.showCashierName,
      cashierName: cashierName ?? this.cashierName,
      showCustomerName: showCustomerName ?? this.showCustomerName,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      compactItemRows: compactItemRows ?? this.compactItemRows,
      showSubtotalRow: showSubtotalRow ?? this.showSubtotalRow,
      showTax: showTax ?? this.showTax,
      taxPercent: taxPercent ?? this.taxPercent,
      showDiscount: showDiscount ?? this.showDiscount,
      showPaymentMethod: showPaymentMethod ?? this.showPaymentMethod,
      showCashAndChange: showCashAndChange ?? this.showCashAndChange,
      showFooterMessage: showFooterMessage ?? this.showFooterMessage,
      footerMessage: footerMessage ?? this.footerMessage,
      showWarrantyNotice: showWarrantyNotice ?? this.showWarrantyNotice,
      warrantyNotice: warrantyNotice ?? this.warrantyNotice,
      showSocialMedia: showSocialMedia ?? this.showSocialMedia,
      socialMediaText: socialMediaText ?? this.socialMediaText,
      showInvoiceQr: showInvoiceQr ?? this.showInvoiceQr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'show_logo': showLogo,
      'logo_path': logoPath,
      'logo_preset': logoPreset,
      'logo_position': logoPosition.code,
      'logo_alignment': logoAlignment.code,
      'logo_size': logoSize.code,
      'store_name': storeName,
      'store_name_size': storeNameSize,
      'show_address': showAddress,
      'store_address': storeAddress,
      'show_contact': showContact,
      'store_contact': storeContact,
      'show_header_note': showHeaderNote,
      'header_note': headerNote,
      'show_invoice_number': showInvoiceNumber,
      'show_date': showDate,
      'show_time': showTime,
      'show_cashier_name': showCashierName,
      'cashier_name': cashierName,
      'show_customer_name': showCustomerName,
      'divider_style': dividerStyle.code,
      'compact_item_rows': compactItemRows,
      'show_subtotal_row': showSubtotalRow,
      'show_tax': showTax,
      'tax_percent': taxPercent,
      'show_discount': showDiscount,
      'show_payment_method': showPaymentMethod,
      'show_cash_and_change': showCashAndChange,
      'show_footer_message': showFooterMessage,
      'footer_message': footerMessage,
      'show_warranty_notice': showWarrantyNotice,
      'warranty_notice': warrantyNotice,
      'show_social_media': showSocialMedia,
      'social_media_text': socialMediaText,
      'show_invoice_qr': showInvoiceQr,
      'paper_size': 58,
    };
  }

  factory ReceiptCustomModel.fromMap(Map<String, dynamic> map) {
    return ReceiptCustomModel(
      showLogo: map['show_logo'] == true || map['show_logo'] == 1,
      logoPath: map['logo_path']?.toString(),
      logoPreset: map['logo_preset']?.toString() ?? 'store',
      logoPosition: ReceiptLogoPosition.fromCode(map['logo_position']?.toString()),
      logoAlignment: ReceiptLogoAlign.fromCode(map['logo_alignment']?.toString()),
      logoSize: ReceiptLogoSize.fromCode(map['logo_size']?.toString()),
      storeName: map['store_name']?.toString() ?? 'NANDA POS',
      storeNameSize: map['store_name_size']?.toString() ?? 'large',
      showAddress: map['show_address'] == null ? true : (map['show_address'] == true || map['show_address'] == 1),
      storeAddress: map['store_address']?.toString() ?? 'Pusat Aksesoris & Servis HP',
      showContact: map['show_contact'] == null ? true : (map['show_contact'] == true || map['show_contact'] == 1),
      storeContact: map['store_contact']?.toString() ?? 'WhatsApp: 0812-3456-7890',
      showHeaderNote: map['show_header_note'] == null ? true : (map['show_header_note'] == true || map['show_header_note'] == 1),
      headerNote: map['header_note']?.toString() ?? 'Solusi Belanja Hemat & Terpercaya',
      showInvoiceNumber: map['show_invoice_number'] == null ? true : (map['show_invoice_number'] == true || map['show_invoice_number'] == 1),
      showDate: map['show_date'] == null ? true : (map['show_date'] == true || map['show_date'] == 1),
      showTime: map['show_time'] == null ? true : (map['show_time'] == true || map['show_time'] == 1),
      showCashierName: map['show_cashier_name'] == null ? true : (map['show_cashier_name'] == true || map['show_cashier_name'] == 1),
      cashierName: map['cashier_name']?.toString() ?? 'Kasir Utama',
      showCustomerName: map['show_customer_name'] == true || map['show_customer_name'] == 1,
      dividerStyle: ReceiptDividerStyle.fromCode(map['divider_style']?.toString()),
      compactItemRows: map['compact_item_rows'] == true || map['compact_item_rows'] == 1,
      showSubtotalRow: map['show_subtotal_row'] == null ? true : (map['show_subtotal_row'] == true || map['show_subtotal_row'] == 1),
      showTax: map['show_tax'] == true || map['show_tax'] == 1,
      taxPercent: (map['tax_percent'] is num) ? (map['tax_percent'] as num).toDouble() : 11.0,
      showDiscount: map['show_discount'] == true || map['show_discount'] == 1,
      showPaymentMethod: map['show_payment_method'] == null ? true : (map['show_payment_method'] == true || map['show_payment_method'] == 1),
      showCashAndChange: map['show_cash_and_change'] == null ? true : (map['show_cash_and_change'] == true || map['show_cash_and_change'] == 1),
      showFooterMessage: map['show_footer_message'] == null ? true : (map['show_footer_message'] == true || map['show_footer_message'] == 1),
      footerMessage: map['footer_message']?.toString() ?? 'Terima Kasih Atas Kunjungan Anda!',
      showWarrantyNotice: map['show_warranty_notice'] == null ? true : (map['show_warranty_notice'] == true || map['show_warranty_notice'] == 1),
      warrantyNotice: map['warranty_notice']?.toString() ?? 'Klaim garansi wajib menunjukkan struk ini.',
      showSocialMedia: map['show_social_media'] == null ? true : (map['show_social_media'] == true || map['show_social_media'] == 1),
      socialMediaText: map['social_media_text']?.toString() ?? 'Follow IG: @nandapos_id',
      showInvoiceQr: map['show_invoice_qr'] == null ? true : (map['show_invoice_qr'] == true || map['show_invoice_qr'] == 1),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ReceiptCustomModel.fromJson(String source) => ReceiptCustomModel.fromMap(jsonDecode(source));
}

