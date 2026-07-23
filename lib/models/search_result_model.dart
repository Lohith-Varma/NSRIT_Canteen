import 'package:flutter/material.dart';

class SearchResultModel {
  final String id;
  final String title;
  final String subtitle;
  final String module;
  final IconData icon;
  final VoidCallback? onTap;

  const SearchResultModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.module,
    required this.icon,
    this.onTap,
  });
}
