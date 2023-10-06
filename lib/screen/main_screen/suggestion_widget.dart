import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sisyphu/db/db_helper.dart';
import '../../my_flutter_app_icons.dart';

class SuggestionWidget extends StatefulWidget {

  final String message;
  final Function() notifyRefreshButtonPressed;

  SuggestionWidget({super.key, required this.message, required this.notifyRefreshButtonPressed});

  @override
  State<SuggestionWidget> createState() => _SuggestionWidgetState();
}


// enum SUGGESTION_INDEX {LATEST_SET_INFO, NOTE_INFO, NEXT_SET_INFO}

class _SuggestionWidgetState extends State<SuggestionWidget> {

  bool isFirstSet = true;
  // late SUGGESTION_INDEX suggestion_index;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // suggestion_index = SUGGESTION_INDEX.LATEST_SET_INFO;

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context)  {
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
         messageWidget(),
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.pink),
          onPressed: widget.notifyRefreshButtonPressed
        )
      ],
    );
  }

  Widget messageWidget() {
    return Text(widget.message);
  }


  void getSetsNumber(int workoutID) async {
    var workoutDates = await DBHelper.instance.getworkoutDates(workoutID);
    if (workoutDates.length == 0 ) {
      setState(() {
        isFirstSet = true;
      });

    } else if (workoutDates.length >= 1) {
      setState(() {
        isFirstSet = false;
      });
    }
  }
}
