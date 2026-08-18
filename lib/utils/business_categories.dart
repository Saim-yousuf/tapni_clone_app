import 'package:flutter/material.dart';
import 'package:tapni_app/l10n/app_localizations_fallback.dart';

const List<String> kBusinessCategories = [
  'Technology',
  'Retail',
  'Health',
  'Education',
  'Finance',
  'Real Estate',
  'Food & Beverage',
  'Entertainment',
  'Other',
];

String businessCategoryLabel(BuildContext context, String category) {
  switch (category) {
    case 'Technology':
      return context.l10n.industryTechnology;
    case 'Retail':
      return context.l10n.industryRetail;
    case 'Health':
      return context.l10n.industryHealthcare;
    case 'Education':
      return context.l10n.industryEducation;
    case 'Finance':
      return context.l10n.industryFinance;
    case 'Real Estate':
      return context.l10n.realEstate;
    case 'Food & Beverage':
      return context.l10n.foodBeverage;
    case 'Entertainment':
      return context.l10n.industryEntertainment;
    case 'Other':
      return context.l10n.industryOther;
    default:
      return category;
  }
}
