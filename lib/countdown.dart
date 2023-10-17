import 'dart:async';

import 'package:flutter/material.dart';

class CountDown extends StatefulWidget {
  const CountDown({Key? key}) : super(key: key);
  @override
  State<CountDown> createState() => _CountDownState();
}

class _CountDownState extends State<CountDown> {
  // Step 2 감
  Timer? countTimer;
  Duration myDuration = Duration(days: 5);
  bool isStart = false;

  @override
  void initState() {
    super.initState();
  }

  /// Timer related methods ///
  // Step 3
  void startTimer() {
    countTimer = Timer.periodic(Duration(seconds: 1), (_) => setCountUp());
    setState(() => isStart = true);
  }

  // Step 4
  void stopTimer() {
    setState(() => countTimer!.cancel());
  }

  // Step 5
  void resetTimer() {
    stopTimer();
    setState(() => myDuration = Duration(days: 5));
    setState(() => isStart = false);
  }

  // Step 6
  void setCountDown() {
    final reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countTimer!.cancel();
      } else {
        myDuration = Duration(seconds: seconds);
      }
    });
  }

  void setCountUp() {
    final addSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds + addSecondsBy;
      myDuration = Duration(seconds: seconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final days = strDigits(myDuration.inDays);
    final hours = strDigits(myDuration.inHours.remainder(24));
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes:$seconds',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 50),
        ),
        SizedBox(height: 20),
        isStart == false
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(fixedSize: const Size(150, 150), shape: const CircleBorder()),
                onPressed: startTimer,
                child: Text(
                  '시작',
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(fixedSize: const Size(150, 150), shape: const CircleBorder()),
                onPressed: () {
                  if (countTimer == null || countTimer!.isActive) {
                    resetTimer();
                  }
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('평가하기'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(fixedSize: const Size(20, 20), shape: const CircleBorder()),
                                onPressed: () {},
                                child: Text(
                                  '쉬움',
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(fixedSize: const Size(20, 20), shape: const CircleBorder()),
                                onPressed: () {},
                                child: Text(
                                  '적당',
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(fixedSize: const Size(20, 20), shape: const CircleBorder()),
                                onPressed: () {},
                                child: Text(
                                  '실패',
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(onPressed: () {}, child: Icon(Icons.remove)),
                              Text('10회'),
                              TextButton(onPressed: () {}, child: Icon(Icons.add))
                            ],
                          )
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'OK'),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  '종료',
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
              ),
      ],
    );
  }
}
