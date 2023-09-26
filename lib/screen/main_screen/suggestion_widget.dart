
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sisyphu/db/db_helper.dart';
import '../../my_flutter_app_icons.dart';

class SuggestionWidget extends StatefulWidget {

  final int setNumber;
  final int workoutID;

  SuggestionWidget({super.key, required this.setNumber, required this.workoutID });

  @override
  State<SuggestionWidget> createState() => _SuggestionWidgetState();
}


enum SUGGESTION_INDEX {LATEST_SET_INFO, NOTE_INFO, NEXT_SET_INFO}

class _SuggestionWidgetState extends State<SuggestionWidget> {

  late List<Map<String, dynamic>> history;
  late int lastSetNumber;

  bool isFirstSet = true;
  late String message;
  late SUGGESTION_INDEX suggestion_index;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    history = [];
    lastSetNumber = 0;
    message = '';
    suggestion_index = SUGGESTION_INDEX.LATEST_SET_INFO;

    Future.delayed(const Duration(milliseconds: 2000), () async {
      setSuggestion();
    });

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
          onPressed: () {
            int index = SUGGESTION_INDEX.values.indexOf(suggestion_index);
            if( index < SUGGESTION_INDEX.values.length ) {
              setState(() {
                index += 1;
                if( index >= SUGGESTION_INDEX.values.length) {
                  index = 0;
                }
                suggestion_index = SUGGESTION_INDEX.values[index];
              });
            }
            setData();
          },
        )
      ],
    );
  }

  Widget messageWidget() {
    getSetsNumber(widget.workoutID);
    if (isFirstSet) {
      return Text('다음 운동부터 중량, 횟수가 자동설정 돼요');
    } else {
      setData();
      return Text('$message');
    }
  }

  void setSuggestion() async {
    var data = await getHistory();
    setState(() {
      history = data;
      lastSetNumber = data.last['set_order'];
    });
    if(history.isNotEmpty) {
      setData();
    }
  }

  void setData() {
    if (history.length < widget.setNumber) {
      setState(() {
        message = '세트 초과';
      });
    } else if (history.length >= widget.setNumber) {
      switchMessage();
    }
  }

  void switchMessage() {
    int set;
    int weight;
    int reps;
    String type;
    String note;

    setState(() {
      switch (suggestion_index) {
        case SUGGESTION_INDEX.LATEST_SET_INFO:
          set = history[widget.setNumber - 1]['set_order'];
          weight = history[widget.setNumber - 1]['weight'];
          reps = history[widget.setNumber - 1]['result_num_time'];
          type = history[widget.setNumber - 1]['type'];
          message = '지난번 $set 세트 $weight kg, $reps회는 $type했어요';
          break;
        case SUGGESTION_INDEX.NOTE_INFO:
          note = history[widget.setNumber - 1]['note'];
          message = '노트: $note';
          break;
        case SUGGESTION_INDEX.NEXT_SET_INFO:
          if( widget.setNumber == lastSetNumber ) {
            message = '다음 세트 정보가 없습니다';
          } else {
            weight = history[widget.setNumber]['weight'];
            reps = history[widget.setNumber]['result_num_time'];
            type = history[widget.setNumber]['type'];
            message = '다음 세트 $weight kg, $reps회에서는 $type했어요';
          }
      }
    });
  }
  

  Future<List<Map<String, dynamic>>> getHistory() async {
   return await DBHelper.instance.getLatestSetHistory(widget.workoutID);
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
