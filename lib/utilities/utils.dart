import 'package:flutter/material.dart';
import 'package:musify/utilities/common_variables.dart';

BorderRadius getItemBorderRadius(int index, int totalLength) {
  const defaultRadius = BorderRadius.zero;
  if (index == 0) {
    return commonCustomBarRadiusFirst; // First item
  } else if (index == totalLength - 1) {
    return commonCustomBarRadiusLast; // Last item
  }
  return defaultRadius; // Default for middle items
}
