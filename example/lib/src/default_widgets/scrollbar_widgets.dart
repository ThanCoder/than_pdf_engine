import 'package:flutter/material.dart';

Widget defaultScrollbar1({
  required double thumbWidth,
  required double thumbHeight,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.grabbing,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        // Premium ဖြစ်တဲ့ Teal Gradient ကာလာ သုံးထားပါတယ်
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(10),
        // အနောက်က စာသားတွေနဲ့ ထင်ထင်ရှားရှားဖြစ်အောင် Shadow အနည်းငယ် ထည့်ထားပါတယ်
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // အလယ်မှာ လက်နဲ့ဆွဲရလွယ်အောင် အစောင်းစင်းလိုင်းလေး (Indicator) ထည့်ချင်ရင် ထည့်နိုင်ပါတယ်
      child: Center(
        child: Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}

Widget defaultScrollbarMinimal({
  required double thumbWidth,
  required double thumbHeight,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors
        .click, // Grabbing အစား ပုံမှန် လက်ညှိုးပုံစံ ပြောင်းထားပါတယ်
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        // ရိုးရှင်းပြီး Premium ဖြစ်တဲ့ Blue Grey ကာလာကို သုံးထားပါတယ်
        color: Colors.blueGrey.shade300.withValues(alpha: 0.8),
        // ဘေးဘောင်တွေကို လုံးဝဝိုင်းသွားအောင် ပုံစံသွင်းထားပါတယ်
        borderRadius: BorderRadius.circular(100),
      ),
      // အလယ်က အစင်းကို ဖြုတ်ပြီး Minimalist ဆန်ဆန် အလွတ်ပဲ ထားထားပါတယ်
    ),
  );
}

Widget defaultScrollbarNeon({
  required double thumbWidth,
  required double thumbHeight,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.grabbing,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: thumbWidth,
      height: thumbHeight,
      decoration: BoxDecoration(
        // ခေတ်မီတဲ့ Neon Purple နဲ့ Pink Gradient စပ်ထားပါတယ်
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purpleAccent.shade400, Colors.pinkAccent.shade400],
        ),
        borderRadius: BorderRadius.circular(8),
        // Scrollbar လေးက လင်းလက်နေသလို ဖြစ်အောင် Neon Glow Shadow ထည့်ထားပါတယ်
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 0), // Spread ဖြစ်အောင် ဗဟိုမှာ ထားပါတယ်
          ),
        ],
      ),
      // အလယ်မှာ အစင်းလေးတွေအစား Dot (အစက်) ၃ စက်နဲ့ Design ဆန်းထားပါတယ်
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
