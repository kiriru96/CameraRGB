import 'package:flutter/material.dart';

class WidgetToPicture extends StatefulWidget {
  final Function(GlobalKey key)? builder;

  const WidgetToPicture({@required this.builder, Key? key}) : super(key: key);

  @override
  State<WidgetToPicture> createState() => WidgetToPictureState();
}

class WidgetToPictureState extends State<WidgetToPicture> {
  final globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: globalKey,
      child: widget.builder!(globalKey),
    );
  }
}
