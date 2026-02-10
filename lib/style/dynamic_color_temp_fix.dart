/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */


import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

// issue: https://github.com/material-foundation/flutter-packages/issues/582
// temp-fix comment: https://github.com/material-foundation/flutter-packages/issues/582#issuecomment-2081174158

(ColorScheme light, ColorScheme dark) tempGenerateDynamicColourSchemes(
  ColorScheme lightDynamic,
  ColorScheme darkDynamic,
) {
  final lightBase = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
  final darkBase = ColorScheme.fromSeed(
    seedColor: darkDynamic.primary,
    brightness: Brightness.dark,
  );

  final lightAdditionalColours = _extractAdditionalColours(lightBase);
  final darkAdditionalColours = _extractAdditionalColours(darkBase);

  final lightScheme = _insertAdditionalColours(
    lightBase,
    lightAdditionalColours,
  );
  final darkScheme = _insertAdditionalColours(darkBase, darkAdditionalColours);

  return (lightScheme.harmonized(), darkScheme.harmonized());
}

List<Color> _extractAdditionalColours(ColorScheme scheme) => [
  scheme.surface,
  scheme.surfaceDim,
  scheme.surfaceBright,
  scheme.surfaceContainerLowest,
  scheme.surfaceContainerLow,
  scheme.surfaceContainer,
  scheme.surfaceContainerHigh,
  scheme.surfaceContainerHighest,
];

ColorScheme _insertAdditionalColours(
  ColorScheme scheme,
  List<Color> additionalColours,
) => scheme.copyWith(
  surface: additionalColours[0],
  surfaceDim: additionalColours[1],
  surfaceBright: additionalColours[2],
  surfaceContainerLowest: additionalColours[3],
  surfaceContainerLow: additionalColours[4],
  surfaceContainer: additionalColours[5],
  surfaceContainerHigh: additionalColours[6],
  surfaceContainerHighest: additionalColours[7],
);
