import 'package:flutter/widgets.dart';

class ArrowBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    double arrowWidth = 8.0; // အချွန်ရဲ့ အကျယ်
    double arrowHeight = 10.0; // အချွန်ရဲ့ အမြင့်
    double radius = 6.0; // လေးထောင့်တုံးရဲ့ အနားလုံးမှုနှုန်း

    // လေးထောင့် Box ပုံစံဆွဲမယ် (ညာဘက်အချွန်အတွက် နေရာချန်ခဲ့မယ်)
    path.moveTo(radius, 0);
    path.lineTo(size.width - arrowWidth - radius, 0);
    path.arcToPoint(
      Offset(size.width - arrowWidth, radius),
      radius: Radius.circular(radius),
    );

    // 🎯 ညာဘက်ခြမ်း အလယ်မှာ အချွန်လေး ထည့်မယ်
    path.lineTo(size.width - arrowWidth, (size.height - arrowHeight) / 2);
    path.lineTo(size.width, size.height / 2); // အချွန်ဆုံးမှတ်
    path.lineTo(size.width - arrowWidth, (size.height + arrowHeight) / 2);

    path.lineTo(size.width - arrowWidth, size.height - radius);
    path.arcToPoint(
      Offset(size.width - arrowWidth - radius, size.height),
      radius: Radius.circular(radius),
    );
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
