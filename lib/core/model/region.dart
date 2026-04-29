import 'package:hiddify/core/localization/translations.dart';

enum Region {
  fi,
  nl,
  ir,
  cn,
  ru,
  af,
  id,
  tr,
  br,
  de,
  us,
  uk,
  sg,
  other;

  static const availableCountries = [fi];

  String present(TranslationsEn t) => switch (this) {
    fi => 'Finland, Helsinki (fi)',
    nl => 'Netherlands (nl)',
    de => 'Germany (de)',
    us => 'United States (us)',
    uk => 'United Kingdom (uk)',
    sg => 'Singapore (sg)',
    ir => t.pages.settings.routing.regions.ir,
    cn => t.pages.settings.routing.regions.cn,
    ru => t.pages.settings.routing.regions.ru,
    af => t.pages.settings.routing.regions.af,
    id => t.pages.settings.routing.regions.id,
    tr => t.pages.settings.routing.regions.tr,
    br => t.pages.settings.routing.regions.br,
    other => t.pages.settings.routing.regions.other,
  };
}
