part of '../t_pdf_render_v3_base.dart';

class TCustomScrollbarWidget {
  final double scrollbarHeight;
  final double scrollbarWidth;
  final double scrollbarRightPosition;
  final Widget child;
  const TCustomScrollbarWidget({
    required this.scrollbarHeight,
    required this.scrollbarWidth,
    required this.scrollbarRightPosition,
    required this.child,
  });

  /// ### Dev UI 3
  factory TCustomScrollbarWidget.ui2(int pageIndex) {
    return TCustomScrollbarWidget(
      scrollbarHeight: 40, // 💡 အမြင့်ကို ၄၀ လောက်ပဲထားရင် ပိုလှပါတယ်
      scrollbarWidth: 70, // 💡 စာသားဆံ့အောင် width ကို နည်းနည်းချဲ့ပေးလိုက်တယ်
      scrollbarRightPosition: 10,
      child: Container(
        alignment: Alignment.center, // 🎯 စာသားကို အလယ်ဗဟို ရောက်အောင်ပို့မယ်
        decoration: BoxDecoration(
          color: Colors.black.withValues(
            alpha: 0.7,
          ), // 🎨 နောက်ခံကို အမည်းရောင် ခပ်မှိုင်းမှိုင်းလေး (Semi-transparent) ထားမယ်
          borderRadius: BorderRadius.circular(
            20,
          ), // 🎯 ဒေါင့်တွေကို လုံးဝိုင်းသွားအောင် လုပ်ပေးတာ (ဘဲဥပုံစံ ဖြစ်သွားမယ်)
          border: Border.all(
            color: Colors.white24, // ✨ အနားသတ်လိုင်း အဖြူနုနုလေး ထည့်ပေးမယ်
            width: 1,
          ),
          boxShadow: [
            // 👤 Scrollbar လေး ကြွတက်လာသလို ဖြစ်အောင် အရိပ် (Shadow) ထည့်ပေးမယ်
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ), // ↔️ ဘေးဘယ်ညာ အကွာအဝေး ညှိမယ်
        child: Text(
          'P: $pageIndex',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // 🔤 စာသားကို အထူလေး လုပ်မယ်
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// ### Dev UI 3
  factory TCustomScrollbarWidget.ui3(int pageIndex) {
    return TCustomScrollbarWidget(
      scrollbarHeight: 28,
      scrollbarWidth: 55,
      scrollbarRightPosition: 4,
      child: ClipPath(
        clipper:
            ArrowBubbleClipper(), // 🎯 အပေါ်မှာဆွဲခဲ့တဲ့ အချွန်ပုံစံ Clipper ကို သုံးမယ်
        child: Container(
          color: Colors.black.withValues(
            alpha: 0.7,
          ), // 🎨 နောက်ခံအရောင် (ဒီမှာတင် အရောင်ထည့်ရပါမယ်)
          alignment: Alignment
              .centerLeft, // 🎯 စာသားကို ဘယ်ဘက်နား ကပ်ပေးထားမယ် (ညာဘက်မှာ အချွန်ရှိလို့)
          padding: const EdgeInsets.only(
            left: 5,
          ), // စာသား ဘယ်ဘက်ကပ်မနေအောင် padding ပေးမယ်
          child: Text(
            'P: $pageIndex',
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

final _defaultScrollbar = Container(
  decoration: BoxDecoration(
    color: Colors.deepPurple.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(20),
  ),
);

class TCustomPageFooterWidget {
  final double basefooterHeight;
  final Widget child;
  const TCustomPageFooterWidget({
    required this.basefooterHeight,
    required this.child,
  });
}
