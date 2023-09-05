
import 'package:flutter/material.dart';

import '../../my_flutter_app_icons.dart';

class SuggestionWidget extends StatefulWidget {
  final String prefix;
  final String suffix;

  const SuggestionWidget({super.key, required this.prefix, required this.suffix });

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
        Text('${widget.prefix} ${widget.suffix}운동 부터는 자동으로 무게,횟수가 설정돼요')
      ],
    );
  }
}
