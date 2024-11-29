import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final Color? color;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final double? width;
  final BoxConstraints? constraints;
  CustomCard({
    Key? key,
    this.color,
    this.borderRadius,
    this.padding,
    required this.child,
    this.width,
    this.constraints
  }) : super(key: key);

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        color: widget.color ?? Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius ?? 16))
      ),
      padding: widget.padding ?? EdgeInsets.all(16),
      child: widget.child,
    );
  }
}
