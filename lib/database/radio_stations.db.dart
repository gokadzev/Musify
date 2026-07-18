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

import 'package:musify/models/radio_model.dart';

List<RadioStation> radioStationsDB = [
  const RadioStation(
    id: 'r_cap_london',
    name: 'Capital London',
    image:
        'https://www.radio.net/300/capitalfmuk.png?version=5949ecef911a9e5232d0dba9643c8ba5b7da9363',
    streamUrl: 'https://media-ssl.musicradio.com/CapitalMP3',
    genre: 'Pop',
  ),
  const RadioStation(
    id: 'r_top_hits',
    name: 'Top Hits',
    image:
        'https://static2.mytuner.mobi/media/tvos_radios/407/hot106.c2263eb2.png',
    streamUrl: 'https://cdn.onlyhitsradio.net/tophits',
    genre: 'Pop',
  ),
  const RadioStation(
    id: 'r_bigfm',
    name: 'bigFM',
    image:
        'https://file.atsw.de/production/static/1783676137495/ab66799083e298839f274a7a8dd9fa15.svg',
    streamUrl: 'https://stream.bigfm.de/deutschland/mp3-128/',
    genre: 'Pop',
  ),
  const RadioStation(
    id: 'r_kissfm',
    name: 'KissFM 104,5',
    image:
        'https://static2.mytuner.mobi/media/tvos_radios/192/kissfm-1045.9092a318.png',
    streamUrl: 'https://ice-11.spilarinn.is/kissfm',
    genre: 'Pop',
  ),
];
