import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A column that fills the viewport when its content fits and grows to its
/// natural height, scrolling, when it does not.
///
/// [children] are stacked full-width at their natural heights, except the
/// [FlexFloor] ones, which share the height left over and never get less
/// than their floor. On a landscape phone, a split-screen half or at large
/// text the fixed controls of a screen (a banner, meters, sliders) leave a
/// region such as a transcript no room; here that region keeps its floor
/// and the whole page scrolls instead of overflowing. Nothing is estimated:
/// the fixed children are measured first. The tree is the same whether or
/// not the column fits, so a rotation never remounts the children.
class FillOrScrollView extends StatelessWidget {
  const FillOrScrollView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) =>
        SingleChildScrollView(
          child: _FloorColumn(
            viewportHeight: box.hasBoundedHeight ? box.maxHeight : 0,
            children: children,
          ),
        ),
  );
}

/// Marks a child of [FillOrScrollView] that takes the height its siblings
/// leave, at least [height] logical pixels (scaled with the text size).
class FlexFloor extends StatelessWidget {
  const FlexFloor({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Floor(
    height: MediaQuery.textScalerOf(context).scale(height),
    child: child,
  );
}

class _FloorParentData extends ContainerBoxParentData<RenderBox> {
  /// The floor of a [FlexFloor] child; null for a fixed child.
  double? floor;
}

class _Floor extends ParentDataWidget<_FloorParentData> {
  const _Floor({required this.height, required super.child});

  final double height;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _FloorParentData;
    if (data.floor == height) return;
    data.floor = height;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => FillOrScrollView;
}

class _FloorColumn extends MultiChildRenderObjectWidget {
  const _FloorColumn({required this.viewportHeight, super.children});

  final double viewportHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFloorColumn(viewportHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFloorColumn renderObject,
  ) => renderObject.viewportHeight = viewportHeight;
}

class _RenderFloorColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FloorParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FloorParentData> {
  _RenderFloorColumn(this._viewportHeight);

  double _viewportHeight;
  set viewportHeight(double value) {
    if (value == _viewportHeight) return;
    _viewportHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FloorParentData) {
      child.parentData = _FloorParentData();
    }
  }

  @override
  void performLayout() {
    final double width = constraints.maxWidth;
    var fixed = 0.0;
    var floors = 0.0;
    var flexible = 0;
    for (RenderBox? c = firstChild; c != null; c = childAfter(c)) {
      final data = c.parentData! as _FloorParentData;
      final double? floor = data.floor;
      if (floor != null) {
        floors += floor;
        flexible++;
        continue;
      }
      c.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      fixed += c.size.height;
    }
    // What the viewport leaves after the fixed children, shared out; never
    // less than a child's floor.
    final double spare = math.max(0, _viewportHeight - fixed - floors);
    var y = 0.0;
    for (RenderBox? c = firstChild; c != null; c = childAfter(c)) {
      final data = c.parentData! as _FloorParentData;
      final double? floor = data.floor;
      if (floor != null) {
        c.layout(
          BoxConstraints.tight(Size(width, floor + spare / flexible)),
          parentUsesSize: true,
        );
      }
      data.offset = Offset(0, y);
      y += c.size.height;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
