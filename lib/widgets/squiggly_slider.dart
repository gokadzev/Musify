// Credits: https://github.com/HannesGitH/squiggly_slider
// HanesGitH

// MIT License

// Copyright (c) 2023 hannepps

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';
import 'package:musify/widgets/squiggly_slider_track_shape.dart';

/// A Material Design Squiggly [Slider].
///
/// Used to select from a range of values while signaling something is live.
///
/// ![A squiggly slider widget, squiggly slider track shape.](https://github.com/hannesgith/squiggly_slider/raw/main/assets/sample.gif)
///
/// The Squiggly Sliders value is part of the Stateful widget subclass to change the value
/// setState was called.
/// The squiggly sinus curve can be controlled by the [squiggleAmplitude] and [squiggleWavelength] parameters.
/// The [squiggleSpeed] parameter controls the speed of the animation.
///
/// ** See code in examples/lib/main.dart **
///
/// See also:
///
///  * [Slider] for more information about the component parts of a slider.
class SquigglySlider extends Slider {
  /// Creates a squiggly Material Design slider.
  ///
  /// The squiggle itself is a sinus curve with rounded edges, vertically centered
  /// its amplitude and wavelength can be adjusted by [squiggleAmplitude] and [squiggleWavelength] respectively,
  /// the curve itself is animated, and the animation speed can be adjusted with [squiggleSpeed] which controls how many waves pass from left to right in one second.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of
  /// the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called while the user is selecting a new value for the
  ///   slider.
  /// * [onChangeStart] is called when the user starts to select a new value for
  ///   the slider.
  /// * [onChangeEnd] is called when the user is done selecting a new value for
  ///   the slider.
  ///
  /// You can override some of the colors with the [activeColor] and
  /// [inactiveColor] properties, although more fine-grained control of the
  /// appearance is achieved using a [SliderThemeData].
  ///
  /// A slider can be used to select from either a continuous or a discrete set of
  /// values. The default is to use a continuous range of values from [min] to
  /// [max]. To use discrete values, use a non-null value for [divisions], which
  /// indicates the number of discrete intervals. For example, if [min] is 0.0 and
  /// [max] is 50.0 and [divisions] is 5, then the slider can take on the
  /// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
  ///
  /// The terms for the parts of a slider are:
  ///
  ///  * The "thumb", which is a shape that slides horizontally when the user
  ///    drags it.
  ///  * The "track", which is the line that the slider thumb slides along.
  ///  * The "value indicator", which is a shape that pops up when the user
  ///    is dragging the thumb to indicate the value being selected.
  ///  * The "active" side of the slider is the side between the thumb and the
  ///    minimum value.
  ///  * The "inactive" side of the slider is the side between the thumb and the
  ///    maximum value.
  ///
  /// The slider will be disabled if [onChanged] is null or if the range given by
  /// [min]..[max] is empty (i.e. if [min] is equal to [max]).
  ///
  /// The slider widget itself does not maintain any state. Instead, when the state
  /// of the slider changes, the widget calls the [onChanged] callback. Most
  /// widgets that use a slider will listen for the [onChanged] callback and
  /// rebuild the slider with a new [value] to update the visual appearance of the
  /// slider. To know when the value starts to change, or when it is done
  /// changing, set the optional callbacks [onChangeStart] and/or [onChangeEnd].
  ///
  /// By default, a slider will be as wide as possible, centered vertically. When
  /// given unbounded constraints, it will attempt to make the track 144 pixels
  /// wide (with margins on each side) and will shrink-wrap vertically.
  ///
  const SquigglySlider({
    super.key,
    required super.value,
    super.secondaryTrackValue,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min = 0.0,
    super.max = 1.0,
    super.divisions,
    super.label,
    super.activeColor,
    super.inactiveColor,
    super.secondaryActiveColor,
    super.thumbColor,
    super.overlayColor,
    super.mouseCursor,
    super.semanticFormatterCallback,
    super.focusNode,
    super.autofocus = false,
    this.squiggleAmplitude = 0.0,
    this.squiggleWavelength = 0.0,
    this.squiggleSpeed = 1.0,
  });

  /// The amplitude of the squiggle.
  final double squiggleAmplitude;

  /// The wavelength of the squiggle.
  final double squiggleWavelength;

  /// The speed of the squiggle in waves per second.
  final double squiggleSpeed;

  @override
  State<SquigglySlider> createState() => _SquigglySliderState();
}

class _SquigglySliderState extends State<SquigglySlider>
    with SingleTickerProviderStateMixin {
  late AnimationController phaseController;

  @override
  void initState() {
    super.initState();
    if (widget.squiggleSpeed == 0) {
      phaseController = AnimationController(
        vsync: this,
      );
      phaseController.value = 0.5;
    } else {
      phaseController = AnimationController(
        duration: Duration(
          milliseconds: (1000.0 / widget.squiggleSpeed.abs()).round(),
        ),
        vsync: this,
      )
        ..repeat(min: 0, max: 1)
        ..addListener(() {
          setState(() {
            // The state that has changed here is the animation object’s value.
          });
        });
    }
  }

  @override
  void dispose() {
    phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackShape: SquigglySliderTrackShape(
            squiggleAmplitude: widget.squiggleAmplitude,
            squiggleWavelength: widget.squiggleWavelength,
            squigglePhaseFactor: widget.squiggleSpeed < 0
                ? 1 - phaseController.value
                : phaseController.value,
          ),
        ),
        child: Slider(
          key: widget.key,
          value: widget.value,
          secondaryTrackValue: widget.secondaryTrackValue,
          onChanged: widget.onChanged,
          onChangeStart: widget.onChangeStart,
          onChangeEnd: widget.onChangeEnd,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.label,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          secondaryActiveColor: widget.secondaryActiveColor,
          thumbColor: widget.thumbColor,
          overlayColor: widget.overlayColor,
          mouseCursor: widget.mouseCursor,
          semanticFormatterCallback: widget.semanticFormatterCallback,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
        ),
      );
}
