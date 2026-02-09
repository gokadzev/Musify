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

import 'package:flutter/material.dart';

const recommendedCubesNumber = 8;

const commonSingleChildScrollViewPadding = EdgeInsets.symmetric(horizontal: 10);
const commonBarPadding = EdgeInsets.symmetric(horizontal: 8);
var commonBarRadius = BorderRadius.circular(16);
var commonBarTitleStyle = const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
);
const commonMiniArtworkRadius = 8.0;

const commonCustomBarRadius = BorderRadius.all(Radius.circular(16));
const commonCustomBarRadiusFirst = BorderRadius.vertical(
  top: Radius.circular(16),
);
const commonCustomBarRadiusLast = BorderRadius.vertical(
  bottom: Radius.circular(16),
);

const miniPlayerTotalHeight = 92.0;

const commonListViewBottomPadding = EdgeInsets.only(bottom: 8);

const commonBarContentPadding = EdgeInsets.symmetric(
  vertical: 12,
  horizontal: 10,
);
