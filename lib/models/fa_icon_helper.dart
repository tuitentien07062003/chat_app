import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FaIconHelper {
  static const Map<String, FaIconData> iconMap = {
    'thumbs-up': FontAwesomeIcons.solidThumbsUp,
    'heart': FontAwesomeIcons.solidHeart,
    'face-smile': FontAwesomeIcons.solidFaceSmile,
    'face-laugh': FontAwesomeIcons.solidFaceLaugh,
    'fire': FontAwesomeIcons.fire,
    'star': FontAwesomeIcons.solidStar,
    'poop': FontAwesomeIcons.poop,
    'clapping-hands': FontAwesomeIcons.handsClapping,
  };

  static FaIconData getIcon(String name) {
    return iconMap[name] ?? FontAwesomeIcons.question;
  }
}
