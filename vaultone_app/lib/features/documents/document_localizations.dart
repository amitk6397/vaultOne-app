import 'package:flutter/widgets.dart';

import '../../core/localization/app_localizations.dart';
import 'models/digi_document.dart';

String localizedDocumentType(BuildContext context, DigiDocumentType type) {
  return context.l10n.tr('document_type_${type.name}');
}

String localizedDocumentCardTitle(BuildContext context, DigiDocumentCard card) {
  if (card.isCustom) return card.title;
  return context.l10n.tr('document_card_${card.id}_title');
}

String localizedDocumentCardSubtitle(
  BuildContext context,
  DigiDocumentCard card,
) {
  if (card.isCustom) return card.subtitle;
  return context.l10n.tr('document_card_${card.id}_subtitle');
}

String localizedExpiryLabel(BuildContext context, DateTime? expiry) {
  if (expiry == null) return context.l10n.tr('no_expiry');
  final days = DateTime(
    expiry.year,
    expiry.month,
    expiry.day,
  ).difference(DateTime.now()).inDays;
  if (days < 0) return context.l10n.tr('expired');
  if (days == 0) return context.l10n.tr('expires_today');
  return context.l10n.tr('expires_in_days', args: {'count': days});
}

String localizedDocumentTitle(BuildContext context, DigiDocument document) {
  for (final card in defaultDigiDocumentCards) {
    if (card.type == document.type && card.title == document.title) {
      return localizedDocumentCardTitle(context, card);
    }
  }
  return document.title;
}

String localizedDocumentFieldLabel(BuildContext context, String label) {
  final key = switch (label.trim().toLowerCase()) {
    'number' => 'document_field_number',
    'dob' || 'dob / date' => 'document_field_dob',
    'phone' => 'document_field_phone',
    'email' => 'document_field_email',
    'amount' => 'document_field_amount',
    'website' => 'document_field_website',
    'name' => 'document_field_name',
    'roll / registration' => 'document_field_roll_registration',
    'vehicle number' => 'document_field_vehicle_number',
    _ => null,
  };
  return key == null ? label : context.l10n.tr(key);
}

String localizedDocumentIssuer(BuildContext context, String issuer) {
  final key = switch (issuer.trim().toLowerCase()) {
    'government id' => 'issuer_government_id',
    'uidai' => 'issuer_uidai',
    'income tax department' => 'issuer_income_tax',
    'election commission' => 'issuer_election_commission',
    'passport office' => 'issuer_passport_office',
    'transport authority' => 'issuer_transport_authority',
    'insurance provider' => 'issuer_insurance_provider',
    'medical provider' => 'issuer_medical_provider',
    'property registry' => 'issuer_property_registry',
    'education board' => 'issuer_education_board',
    'financial institution' => 'issuer_financial_institution',
    _ => null,
  };
  return key == null ? issuer : context.l10n.tr(key);
}
