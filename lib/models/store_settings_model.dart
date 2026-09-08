import '../config/app_constants.dart';

class StoreSettingsModel {
  final String id;
  final String name;
  final String tagline;
  final String subtitle;
  final String address;
  final String whatsappNumber;
  final Map<String, dynamic> operatingHours;
  final double freeDeliveryThreshold;
  final double deliveryFee;
  final String aboutText;
  final String guaranteeText;

  const StoreSettingsModel({
    this.id = '00000000-0000-0000-0000-000000000001',
    this.name = AppConstants.defaultStoreName,
    this.tagline = AppConstants.defaultTagline,
    this.subtitle = AppConstants.defaultSubtitle,
    this.address = AppConstants.defaultAddress,
    this.whatsappNumber = AppConstants.defaultWhatsAppNumber,
    this.operatingHours = const {
      'Monday': '6:00 AM - 9:00 PM',
      'Tuesday': '6:00 AM - 9:00 PM',
      'Wednesday': '6:00 AM - 9:00 PM',
      'Thursday': '6:00 AM - 9:00 PM',
      'Friday': '6:00 AM - 9:00 PM',
      'Saturday': '6:00 AM - 10:00 PM',
      'Sunday': '6:00 AM - 10:00 PM',
    },
    this.freeDeliveryThreshold = AppConstants.defaultFreeDeliveryThreshold,
    this.deliveryFee = AppConstants.defaultDeliveryFee,
    this.aboutText =
        'Fresh Kart sources vegetables and fruits daily at 4:00 AM directly from local APMC mandis and organic farmer clusters. No cold-storage decay, zero middleman markup — only crisp, peak-fresh farm produce delivered to your doorstep within hours of procurement.',
    this.guaranteeText =
        '100% Crisp & Clean Guarantee: If any item is bruised or unsatisfactory, WhatsApp us within 2 hours of delivery for an instant replacement or full refund without return hassle.',
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      id: json['id'] as String? ?? '00000000-0000-0000-0000-000000000001',
      name: json['name'] as String? ?? AppConstants.defaultStoreName,
      tagline: json['tagline'] as String? ?? AppConstants.defaultTagline,
      subtitle: json['subtitle'] as String? ?? AppConstants.defaultSubtitle,
      address: json['address'] as String? ?? AppConstants.defaultAddress,
      whatsappNumber:
          json['whatsapp_number'] as String? ?? AppConstants.defaultWhatsAppNumber,
      operatingHours: (json['operating_hours'] as Map<String, dynamic>?) ??
          const {
            'Monday': '6:00 AM - 9:00 PM',
            'Tuesday': '6:00 AM - 9:00 PM',
            'Wednesday': '6:00 AM - 9:00 PM',
            'Thursday': '6:00 AM - 9:00 PM',
            'Friday': '6:00 AM - 9:00 PM',
            'Saturday': '6:00 AM - 10:00 PM',
            'Sunday': '6:00 AM - 10:00 PM',
          },
      freeDeliveryThreshold:
          (json['free_delivery_threshold'] as num?)?.toDouble() ??
              AppConstants.defaultFreeDeliveryThreshold,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ??
          AppConstants.defaultDeliveryFee,
      aboutText: json['about_text'] as String? ?? '',
      guaranteeText: json['guarantee_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'subtitle': subtitle,
      'address': address,
      'whatsapp_number': whatsappNumber,
      'operating_hours': operatingHours,
      'free_delivery_threshold': freeDeliveryThreshold,
      'delivery_fee': deliveryFee,
      'about_text': aboutText,
      'guarantee_text': guaranteeText,
    };
  }
}
