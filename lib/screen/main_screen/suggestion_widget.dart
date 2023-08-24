
import 'package:flutter/material.dart';

import '../../my_flutter_app_icons.dart';

class SuggestionWidget extends StatefulWidget {
  const SuggestionWidget({super.key});

  @override
  State<SuggestionWidget> createState() => _SuggestionWidgetState();
}

class _SuggestionWidgetState extends State<SuggestionWidget> {

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.pink,
              style: BorderStyle.solid,
              width: 1
            ),
              borderRadius: BorderRadius.circular(8)
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(CustomIcons.chart, color: Colors.pink, size: 16)
          ),
        ),
        Text('오늘 무게를 조금 올려보는 건 어떨까요?')
      ],
    );
  }
}
