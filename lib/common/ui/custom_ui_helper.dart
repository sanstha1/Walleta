import 'package:flutter/material.dart';

const xxsHSpan = SizedBox(height: 2);
const xsHSpan = SizedBox(height: 4);
const sHSpan = SizedBox(height: 8);
const mHSpan = SizedBox(height: 12);
const lHSpan = SizedBox(height: 16);
const xlHSpan = SizedBox(height: 24);
const xxlHSpan = SizedBox(height: 32);

const xxsWSpan = SizedBox(width: 2);
const xsWSpan = SizedBox(width: 4);
const sWSpan = SizedBox(width: 8);
const mWSpan = SizedBox(width: 12);
const lWSpan = SizedBox(width: 16);
const xlWSpan = SizedBox(width: 24);
const xxlWSpan = SizedBox(width: 32);

const xxsPadding = EdgeInsets.all(2);
const xsPadding = EdgeInsets.all(4);
const sPadding = EdgeInsets.all(8);
const mPadding = EdgeInsets.all(12);
const lPadding = EdgeInsets.all(16);
const xlPadding = EdgeInsets.all(24);
const xxlPadding = EdgeInsets.all(32);

const xxsXPadding = EdgeInsets.symmetric(horizontal: 2);
const xsXPadding = EdgeInsets.symmetric(horizontal: 4);
const sXPadding = EdgeInsets.symmetric(horizontal: 8);
const mXPadding = EdgeInsets.symmetric(horizontal: 12);
const lXPadding = EdgeInsets.symmetric(horizontal: 16);
const xlXPadding = EdgeInsets.symmetric(horizontal: 24);
const xxlXPadding = EdgeInsets.symmetric(horizontal: 32);

const xxsYPadding = EdgeInsets.symmetric(vertical: 2);
const xsYPadding = EdgeInsets.symmetric(vertical: 4);
const sYPadding = EdgeInsets.symmetric(vertical: 8);
const mYPadding = EdgeInsets.symmetric(vertical: 12);
const lYPadding = EdgeInsets.symmetric(vertical: 16);
const xlYPadding = EdgeInsets.symmetric(vertical: 24);
const xxlYPadding = EdgeInsets.symmetric(vertical: 32);

Widget widthFactorBox(BuildContext context, {double factor = 1}) =>
    SizedBox(width: widthFactor(context, factor: factor));

Widget heightFactorBox(BuildContext context, {double factor = 1}) =>
    SizedBox(height: heightFactor(context, factor: factor));

BorderRadius circularRadius(double radius) => BorderRadius.circular(radius);

double widthFactor(BuildContext context, {double factor = 1}) =>
    MediaQuery.of(context).size.width * factor;

double heightFactor(BuildContext context, {double factor = 1}) =>
    MediaQuery.of(context).size.height * factor;

TextTheme textTheme(BuildContext context) => Theme.of(context).textTheme;

TextStyle? displaySmall(BuildContext context) =>
    textTheme(context).displaySmall;

TextStyle? headlineMedium(BuildContext context) =>
    textTheme(context).headlineMedium;

TextStyle? headlineSmall(BuildContext context) =>
    textTheme(context).headlineSmall;

TextStyle? headlineSmallB(BuildContext context) =>
    headlineSmall(context)?.copyWith(fontWeight: FontWeight.w600);

TextStyle? titleLarge(BuildContext context) => textTheme(context).titleLarge;

TextStyle? titleLargeB(BuildContext context) =>
    textTheme(context).titleLarge?.copyWith(fontWeight: FontWeight.w800);

TextStyle? headline6B(BuildContext context) =>
    titleLarge(context)?.copyWith(fontWeight: FontWeight.bold);

TextStyle? titleMedium(BuildContext context) => textTheme(context).titleMedium;

TextStyle? titleMediumB(BuildContext context) =>
    titleMedium(context)?.copyWith(fontWeight: FontWeight.bold);

TextStyle? titleSmall(BuildContext context) => textTheme(context).titleSmall;

TextStyle? titleSmallB(BuildContext context) =>
    titleSmall(context)?.copyWith(fontWeight: FontWeight.bold);

TextStyle? bodyLarge(BuildContext context) => textTheme(context).bodyLarge;

TextStyle? bodyMedium(BuildContext context) => textTheme(context).bodyMedium;

TextStyle? bodyMediumB(BuildContext context) =>
    bodyMedium(context)?.copyWith(fontWeight: FontWeight.bold);

TextStyle? bodySmall(BuildContext context) => textTheme(context).bodySmall;

TextStyle? bodySmallB(BuildContext context) =>
    textTheme(context).bodySmall?.copyWith(fontWeight: FontWeight.bold);

TextStyle? labelStyle(BuildContext context) => textTheme(context).labelLarge;

TextStyle? labelStyleSmall(BuildContext context) =>
    textTheme(context).labelSmall;
