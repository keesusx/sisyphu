import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisyphu/db/workouts.dart';
import 'package:sisyphu/screen/add_workout_screen.dart';
import 'package:sisyphu/screen/main_screen/suggestion.dart';
import 'package:sisyphu/screen/main_screen/suggestion_widget.dart';
import 'package:sisyphu/screen/workout_history_screen.dart';
import 'package:sisyphu/utils/analytics.dart';
import '../../db/evaluations.dart';
import '../../db/sets.dart';
import '../../db/db_helper.dart';
import 'package:collection/collection.dart';
import '../../utils/enums.dart';
import 'package:badges/badges.dart' as badges;
import '../../utils/target.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  // 운동 평가 기본 셋팅: '성공'
  EVALUATION_TYPE _evaluationType = EVALUATION_TYPE.SUCCESS;

  Timer? countTimer;
  Duration myDuration = Duration(minutes: 0, seconds: 00);
  bool wasPause = false;
  bool isWorkoutEmpty = true;
  Suggestion suggestion = Suggestion(setNumber: 0);

  final int timeLimitInMinute = 30;

  late APP_STATUS workoutMode;
  late bool isStarted;

  late int timerMinutes;
  late int timerSeconds;
  late int targetWeight;
  late int newWeight;
  late int targetReps;
  late int newReps;
  late int nowSetNumber;
  late int nowWorkoutID;
  late String nowWorkoutName;
  late double _scale;
  late String signalMessagePrefix;
  late String signalMessageSuffix;
  late num latestVolumn;
  late num todayVolumn;

  late List<Map<String, dynamic>> todayCompletedWorkouts;
  late List<Map<String, dynamic>> todayTargetWorkouts;
  late List<Map<String, dynamic>> workoutList;

  late Map<String, List> todayCompletedWorkoutsInGroup;
  late int workoutIndex;

  late List<Map<String, dynamic>> history;
  late int lastSetNumber;
  late String message;
  late SUGGESTION_INDEX suggestion_index;

  late final AppLifecycleListener _appLifecycleListener;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    isStarted = false;
    nowWorkoutName = '';
    nowWorkoutID = 0;
    targetWeight = 0;
    newWeight = 0;
    targetReps = 1;
    newReps = 0;
    todayCompletedWorkouts = [];
    todayTargetWorkouts = [];
    todayCompletedWorkoutsInGroup = {};
    workoutList = [];
    workoutIndex = 0;
    timerMinutes = 0;
    timerSeconds = 0;
    nowSetNumber = 1;
    latestVolumn = 0;
    todayVolumn = 0;
    _scale = 100;
    history = [];
    lastSetNumber = 0;
    message = '';
    suggestion_index = SUGGESTION_INDEX.LATEST_SET_INFO;

    _appLifecycleListener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );

    setAppStatus(APP_STATUS.IN_BREAK);
    ensureEmptyWorkout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged(AppLifecycleState state) async {
    var prefs = await SharedPreferences.getInstance();

    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        print("app in active");

        if (wasPause == false) {
        } else {
          DateTime lastUnstoppedTimerValue = DateTime.parse(prefs.getString('timerStartTime')!);
          Duration timeElapsed = DateTime.now().difference(lastUnstoppedTimerValue);

          if (timeElapsed.inMinutes >= timeLimitInMinute) {
            setIsStarted(false);
            setAppFinish();
          }

          setState(() {
            if (workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK) {
              if (isStarted) {
                print('counter added');
                myDuration = myDuration + timeElapsed;
              }
            }
            wasPause = false;
          });
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        prefs.setString('timerStartTime', DateTime.now().toString());
        setState(() {
          wasPause = true;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _onWorkoutTextStyle = TextStyle(color: Colors.pink);
    TextStyle _onBreakTextStyle = TextStyle(color: Colors.black);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: workoutMode == APP_STATUS.FINISH
              ? Container()
              : workoutMode == APP_STATUS.IN_BREAK
                  ? isWorkoutEmpty
                      ? emptyWorkoutMessage()
                      : Text('휴식중', style: _onBreakTextStyle)
                  : Text('운동중', style: _onWorkoutTextStyle),
          actions: [
            IconButton(
                onPressed: () {
                  Analytics.sendAnalyticsEvent('add_workout_icon');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddWorkoutScreen())).then((value) async {
                    //Navigation Stack이 다시 돌아왔을때 콜백
                    ensureEmptyWorkout();
                    setTargetWorkout();

                    if (todayTargetWorkouts.length > 0) {
                      var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowSetNumber(temp + 1);
                      setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                    }
                  });
                },
                icon: isWorkoutEmpty
                    ? Stack(
                        alignment: AlignmentDirectional.center,
                        children: [
                          Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pink, width: 2))),
                          Icon(Icons.add, color: Colors.pink)
                        ],
                      )
                    : Icon(Icons.add)),
            IconButton(
                onPressed: () {
                  Analytics.sendAnalyticsEvent('history_icon');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutHistoryScreen()));
                },
                icon: Icon(Icons.history_rounded)),
          ],
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK ? inWorkoutWidgets() : Container(),
                isWorkoutEmpty ? Container() : menuLabel('오늘 한 운동'),
                todayCompletedSetsWidget(),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: workoutMode == APP_STATUS.IN_BREAK
            ? FloatingActionButton(
                child: Icon(Icons.stop),
                backgroundColor: isWorkoutEmpty ? Colors.grey : null,
                onPressed: isWorkoutEmpty
                    ? null
                    : () {
                        Analytics.sendAnalyticsEvent('finish_workout_button');
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(title: Text('운동을 종료할까요?'), actions: [
                                  TextButton(
                                      onPressed: () {
                                        setIsStarted(false);
                                        setAppFinish();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('네')),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('아니오'))
                                ]));
                      },
              )
            : workoutMode == APP_STATUS.FINISH
                ? FloatingActionButton(
                    child: Icon(Icons.play_arrow),
                    onPressed: () async {
                      setAppStatus(APP_STATUS.IN_BREAK);
                      setTargetWorkout();
                      var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowSetNumber(temp + 1);
                      setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                    })
                : Container());
  }

  Widget inWorkoutWidgets() {
    return Column(
      children: [
        isWorkoutEmpty ? Container() : workoutInfo(),
        SizedBox(height: 20),
        counter(),
        SizedBox(height: 20),
        controlPanel(targetWeight, targetReps),
        SizedBox(height: 20),
        startStopButton(),
        SizedBox(height: 20),
        SuggestionWidget(message: message, notifyRefreshButtonPressed: shuffleSuggestionMessage),
        SizedBox(height: 20),
      ],
    );
  }

  Widget menuLabel(String text) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [Text(text, style: TextStyle(fontSize: 20))],
      ),
    );
  }

  Widget workoutInfo() {
    return Container(
      height: 70,
      child: Stack(alignment: Alignment.center, children: [
        Text(
          nowWorkoutName,
          style: TextStyle(fontSize: 20),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            workoutMode == APP_STATUS.IN_BREAK
                ? IconButton(
                    onPressed: () async {
                      Analytics.sendAnalyticsEvent('previous_arrow');

                      if (workoutIndex > 0) {
                        setWorkoutIndexDecrease();
                        setNowWorkoutName(todayTargetWorkouts[workoutIndex]['name']);
                      }
                      var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowSetNumber(temp + 1);
                      await setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                      setTodayVolumn(todayTargetWorkouts[workoutIndex]['workout']);
                      setLatestVolumn(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowWorkoutID(todayTargetWorkouts[workoutIndex]['workout']);
                      setSuggestion();
                      // setProgressiveUI(todayTargetWorkouts[workoutIndex]['workout']);
                    },
                    icon: Icon(Icons.arrow_back_ios_new_outlined))
                : Container(),
            workoutMode == APP_STATUS.IN_BREAK
                ? IconButton(
                    onPressed: () async {
                      Analytics.sendAnalyticsEvent('forward_arrow');

                      if (workoutIndex < todayTargetWorkouts.length) {
                        setWorkoutIndexIncrease();
                        setNowWorkoutName(todayTargetWorkouts[workoutIndex]['name']);
                        setNowWorkoutID(todayTargetWorkouts[workoutIndex]['workout']);
                      }
                      var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowSetNumber(temp + 1);
                      await setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                      setTodayVolumn(todayTargetWorkouts[workoutIndex]['workout']);
                      setLatestVolumn(todayTargetWorkouts[workoutIndex]['workout']);
                      setNowWorkoutID(todayTargetWorkouts[workoutIndex]['workout']);
                      setSuggestion();

                      // setProgressiveUI(todayTargetWorkouts[workoutIndex]['workout']);
                    },
                    icon: Icon(Icons.arrow_forward_ios_outlined))
                : Container()
          ],
        ),
      ]),
    );
  }

  Widget startStopButton() {
    int setID;
    return workoutMode == APP_STATUS.IN_BREAK
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Color(0xff04A777),
              shape: const CircleBorder(),
              fixedSize: const Size(180, 180),
            ),
            onPressed: isWorkoutEmpty
                ? null
                : () {
                    Analytics.sendAnalyticsEvent('start_counter_button');
                    setIsStarted(true);
                    setAppStatus(APP_STATUS.IN_WORKOUT);
                    if (countTimer != null) {
                      setState(() {
                        timerMinutes = 0;
                        timerSeconds = 0;
                      });
                      resetTimer(this.timerMinutes, this.timerSeconds);
                    }
                    startTimer(TIMER_TYPE.UP);
                    _changeScale();
                  },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 90),
                Text('$nowSetNumber세트 시작', style: TextStyle(fontSize: 20)),
              ],
            ),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              fixedSize: const Size(180, 180),
              animationDuration: Duration(milliseconds: 300),
            ),
            onPressed: () async {
              Analytics.sendAnalyticsEvent('stop_counter_button');

              setAppStatus(APP_STATUS.IN_BREAK);
              setState(() {
                setNowSetNumber(nowSetNumber + 1);
              });

              String strDigits(int n) => n.toString().padLeft(2, '0');
              final seconds = strDigits(myDuration.inSeconds.remainder(60));
              final minutes = strDigits(myDuration.inMinutes.remainder(60));

              setID = await DBHelper.instance.insertSets(Sets(
                  workout: todayTargetWorkouts[workoutIndex]['workout'],
                  targetNumTime: this.targetReps,
                  weight: this.targetWeight,
                  setOrder: this.nowSetNumber - 1,
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String()));

              await DBHelper.instance.insertEvaluations(Evaluations(
                  set: setID,
                  type: _evaluationType.label,
                  note: '',
                  resultNumTime: this.targetReps,
                  elapsedTime: '$minutes:$seconds',
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String()));

              if (countTimer != null || countTimer!.isActive) {
                setState(() {
                  timerMinutes = 0;
                  timerSeconds = 0;
                });
                resetTimer(this.timerMinutes, this.timerSeconds);
              }
              startTimer(TIMER_TYPE.UP);

              setTodayCompletedWorkouts();
              await setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
              setTodayVolumn(todayTargetWorkouts[workoutIndex]['workout']);
              setLatestVolumn(todayTargetWorkouts[workoutIndex]['workout']);
              setSuggestion();
              _scrollDown();
              _changeScale();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause, size: 90),
                Text(
                  '$nowSetNumber세트 종료',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          );
  }

  Widget counter() {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
              duration: Duration(milliseconds: 400),
              tween: Tween<double>(begin: _scale, end: _scale),
              builder: (_, double size, __) =>
                  Text('$minutes:$seconds', style: TextStyle(fontWeight: FontWeight.w100, color: Colors.black, fontSize: size)))
        ],
      ),
    );
  }

  Widget todayCompletedSetsWidget() {
    EVALUATION_TYPE tempEvaluationType;

    return Column(
      children: [
        ListView.builder(
            reverse: true,
            shrinkWrap: true,
            controller: _scrollController,
            itemCount: todayCompletedWorkoutsInGroup.length,
            itemBuilder: (BuildContext context, int index) {
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(todayCompletedWorkoutsInGroup.keys.toList()[index].toString()),
                    children: List<Widget>.generate(todayCompletedWorkoutsInGroup.entries.toList()[index].value.length, (int i) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text((todayCompletedWorkoutsInGroup.entries.toList()[index].value.length - i).toString() + '세트 '),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['weight'].toString() + 'kg'),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['target_num_time'].toString() + '회'),
                          badges.Badge(
                            position: badges.BadgePosition.topEnd(top: 2, end: 5),
                            badgeContent: Icon(Icons.circle_rounded, color: Colors.pink, size: 2),
                            showBadge: isNewSet(
                                    i, DateTime.parse(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['created_at']))
                                ? true
                                : false,
                            child: IconButton(
                                onPressed: () async {
                                  final textInputControllerWeight = TextEditingController();
                                  final textInputControllerReps = TextEditingController();
                                  var textInputControllerNote = TextEditingController();

                                  var newWeight = todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['weight'];
                                  var newReps = todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['target_num_time'];
                                  var newNote = todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['note'];

                                  tempEvaluationType = EVALUATION_TYPE
                                      .getByLabel(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['type']);

                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                              // actionsPadding: EdgeInsets.all(10),
                                              actionsOverflowDirection: VerticalDirection.down,
                                              scrollable: true,
                                              actionsAlignment: MainAxisAlignment.end,
                                              title:
                                                  Text((todayCompletedWorkoutsInGroup.entries.toList()[index].value.length - i).toString() + '세트 평가'),
                                              content: StatefulBuilder(
                                                builder: (BuildContext context, StateSetter setState) {
                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('중량'),
                                                      TextField(
                                                        keyboardType: TextInputType.number,
                                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                        controller: textInputControllerWeight,
                                                        decoration: InputDecoration(hintText: '${newWeight}kg'),
                                                      ),
                                                      SizedBox(height: 20),
                                                      Text('횟수'),
                                                      TextField(
                                                        keyboardType: TextInputType.number,
                                                        controller: textInputControllerReps,
                                                        decoration: InputDecoration(hintText: '${newReps}회'),
                                                      ),
                                                      SizedBox(height: 20),
                                                      Text('평가'),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: ListTile(
                                                              horizontalTitleGap: -5,
                                                              contentPadding: EdgeInsets.all(0),
                                                              title: Text(
                                                                '쉬움',
                                                                style: TextStyle(fontSize: 12),
                                                              ),
                                                              leading: Radio<EVALUATION_TYPE>(
                                                                value: EVALUATION_TYPE.EASY,
                                                                groupValue: tempEvaluationType,
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    tempEvaluationType = value!;
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            flex: 1,
                                                          ),
                                                          Expanded(
                                                            child: ListTile(
                                                              horizontalTitleGap: -5,
                                                              contentPadding: EdgeInsets.all(0),
                                                              dense: true,
                                                              title: Text(
                                                                '성공',
                                                                style: TextStyle(fontSize: 12),
                                                              ),
                                                              leading: Radio<EVALUATION_TYPE>(
                                                                value: EVALUATION_TYPE.SUCCESS,
                                                                groupValue: tempEvaluationType,
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    tempEvaluationType = value!;
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            flex: 1,
                                                          ),
                                                          Expanded(
                                                            child: ListTile(
                                                              horizontalTitleGap: -5,
                                                              contentPadding: EdgeInsets.all(0),
                                                              title: Text(
                                                                '실패',
                                                                style: TextStyle(fontSize: 12),
                                                              ),
                                                              leading: Radio<EVALUATION_TYPE>(
                                                                value: EVALUATION_TYPE.FAIL,
                                                                groupValue: tempEvaluationType,
                                                                onChanged: (value) {
                                                                  setState(() {
                                                                    tempEvaluationType = value!;
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            flex: 1,
                                                          )
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text('개선할 점'),
                                                          TextButton(
                                                              onPressed: () async {
                                                                var latestNote = await DBHelper.instance.getNote(nowWorkoutID,
                                                                    todayCompletedWorkoutsInGroup.entries.toList()[index].value.length - i);

                                                                if (latestNote.length > 1) {
                                                                  setState(() {
                                                                    textInputControllerNote.text = latestNote[1]['note'].toString();
                                                                  });
                                                                }
                                                              },
                                                              child: Text(
                                                                '지난 메모 불러오기',
                                                                style: TextStyle(fontSize: 12),
                                                              ))
                                                        ],
                                                      ),
                                                      TextField(
                                                        textInputAction: TextInputAction.newline,
                                                        maxLines: null,
                                                        keyboardType: TextInputType.multiline,
                                                        controller: textInputControllerNote,
                                                        decoration: InputDecoration(hintText: '${newNote}'),
                                                      )
                                                    ],
                                                  );
                                                },
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('취소'),
                                                ),
                                                TextButton(
                                                    onPressed: () {
                                                      if (textInputControllerWeight.text.length > 0) {
                                                        DBHelper.updateWeight(
                                                            todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id'],
                                                            int.parse(textInputControllerWeight.text));
                                                      }
                                                      if (textInputControllerReps.text.length > 0) {
                                                        DBHelper.updateReps(
                                                            todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id'],
                                                            int.parse(textInputControllerReps.text));
                                                      }
                                                      if (textInputControllerNote.text.length > 0) {
                                                        DBHelper.updateNote(
                                                            todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]
                                                                ['evaluationsID'],
                                                            textInputControllerNote.text);
                                                      }
                                                      DBHelper.updateEvaluationType(
                                                          todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]
                                                              ['evaluationsID'],
                                                          tempEvaluationType.label);
                                                      setTodayCompletedWorkouts();
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('확인')),
                                              ]));
                                },
                                icon: Icon(Icons.edit)),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                        title: Text('세트를 삭제합니다.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () async {
                                                DBHelper.deleteSet(
                                                    todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id']);
                                                setTodayCompletedWorkouts();
                                                var temp =
                                                    await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                                                setNowSetNumber(temp + 1);
                                                setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('네')),
                                          TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('취소'))
                                        ],
                                      ));
                            },
                          )
                        ],
                      );
                    })),
              );
            }),
      ],
    );
  }

  Widget emptyWorkoutMessage() {
    return Text('운동을 추가 해보세요');
  }

  Widget controlPanel(int targetWeight, int targetReps) {
    final TextStyle _style = TextStyle(color: Colors.black);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 1, child: TextButton(child: Text('-10', style: _style), onPressed: () => reduceWeight(10))),
              Expanded(flex: 1, child: TextButton(child: Text('-5', style: _style), onPressed: () => reduceWeight(5))),
              Expanded(flex: 1, child: TextButton(child: Text('-1', style: _style), onPressed: () => reduceWeight(1))),
              Expanded(flex: 2, child: Text(textAlign: TextAlign.center, '$targetWeight kg', style: TextStyle(fontSize: 20))),
              Expanded(flex: 1, child: TextButton(child: Text('+1', style: _style), onPressed: () => addWeight(1))),
              Expanded(flex: 1, child: TextButton(child: Text('+5', style: _style), onPressed: () => addWeight(5))),
              Expanded(flex: 1, child: TextButton(child: Text('+10', style: _style), onPressed: () => addWeight(10))),
            ],
          ),
        ),
        Container(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(child: Text('-5', style: _style), onPressed: () => reduceReps(5)),
              TextButton(child: Text('-1', style: _style), onPressed: () => reduceReps(1)),
              Text(
                '$targetReps회',
                style: TextStyle(fontSize: 20),
              ),
              TextButton(child: Text('+1', style: _style), onPressed: () => addReps(1)),
              TextButton(child: Text('+5', style: _style), onPressed: () => addReps(5)),
            ],
          ),
        )
      ],
    );
  }

  void _changeScale() {
    setState(() => _scale = _scale == 100 ? 120 : 100);
  }

  Future<void> setTargetWeightReps(int workoutID, setInNumber) async {
    if (todayTargetWorkouts.length > 0) {
      var setHistory = await DBHelper.instance.getLatestSetHistory(workoutID);

      //과거에 히스토리가 없으면 오늘 데이터로 셋팅
      if (setHistory.isEmpty) {
        setLatestWeightReps(workoutID);
      }
      //과거에 히스토리가 있을 때 과거 데이터로 셋팅
      else if (setHistory.isNotEmpty) {
        // 오늘 운동한 세트수가 가장 최근 세트수보다 많으면 오늘 데이터로 셋팅
        if (setHistory.length < setInNumber) {
          setLatestWeightReps(workoutID);
        } else {
          setHistory.forEach((element) {
            if (setInNumber == element['set_order']) {
              setNowWorkoutWeight(element['weight']);
              setNowWorkoutReps(element['result_num_time']);
            }
          });
        }
      }
    }
  }

  void setLatestVolumn(int workoutID) async {
    num volumn = 0;
    var setHistory = await DBHelper.instance.getLatestSetHistory(workoutID);

    setHistory.forEach((element) {
      volumn += element['weight'] * element['result_num_time'];
    });

    setState(() {
      latestVolumn = volumn;
    });

    // print('이전 볼륨: $latestVolumn');
  }

  void setTodayVolumn(int workoutID) async {
    num volumn = 0;
    var todayWeightReps = await DBHelper.instance.getWeightsRepsToday(workoutID);

    todayWeightReps.forEach((element) {
      volumn += element['weight'] * element['reps'];
    });

    setState(() {
      todayVolumn = volumn;
    });

    // print('today volumn is $todayVolumn');
  }

  void setLatestWeightReps(int workoutID) async {
    var todayWeightReps = await DBHelper.instance.getWeightsRepsToday(workoutID);

    if (todayWeightReps.isNotEmpty) {
      var latestWeightReps = todayWeightReps.last;

      print('오늘 이전에 운동한 기록은 없고 오늘 운동 기록은 있음');
      setNowWorkoutWeight(latestWeightReps['weight']);
      setNowWorkoutReps(latestWeightReps['reps']);
    } else {
      print('오늘 이전에 운동한 기록도 없고 오늘도 처음 운동임');
      setNowWorkoutWeight(0);
      setNowWorkoutReps(1);
    }
  }

  Future<void> setTargetWorkout() async {
    List<Map<String, dynamic>> originalPickedWorkoutsFromDB = await DBHelper.instance.getTodayTargetWorkoutId();
    List<Map<String, dynamic>> allWorkouts = await DBHelper.instance.getWorkouts();
    List<Map<String, dynamic>> resultTargetWorkouts = [];

    List<int> targetWorkoutIdList = [];
    List<int> allWorkoutIdList = [];
    List<int> otherWorkoutIdList = [];
    List<int> sameBodypartWorkoutIdList = [];
    List<int> remainWorkoutIdList = [];

    //id 값만 뽑아내서 리스트에 저장
    originalPickedWorkoutsFromDB.forEach((element) {
      targetWorkoutIdList.add(int.parse(element['workout'].toString()));
    });

    allWorkouts.forEach((element) {
      allWorkoutIdList.add(int.parse(element['workout'].toString()));
    });

    // bodypart 달라지는 index 찾아서 저장
    List<Target> targets = originalPickedWorkoutsFromDB.map((c) => Target.fromMap(c)).toList();
    List<int> bodypartDifferentPointIndex = searchDifferentIndex(targets);

    // 같은 운동 묶는 로직 시작
    for (int i = 0; i < bodypartDifferentPointIndex.length; i++) {
      sameBodypartWorkoutIdList = [];
      remainWorkoutIdList = [];

      int index = bodypartDifferentPointIndex[i];

      List<Map<String, dynamic>> sameBodyPartWorkouts = await DBHelper.instance.getAllWorkoutsByBodyPart(targets[index].bodypartID);

      sameBodyPartWorkouts.forEach((element) {
        sameBodypartWorkoutIdList.add(element['workout']);
      });

      remainWorkoutIdList = sameBodypartWorkoutIdList.toSet().difference(targetWorkoutIdList.toSet()).toList();

      // 같은 부위 운동을 원하는 리스트 위치에 집어넣기
      if (remainWorkoutIdList.isNotEmpty) {
        targetWorkoutIdList.insert(index + i + 1, remainWorkoutIdList.first);
      }
    }

    // 나머지 남은 운동들 뒤에 붙이기
    otherWorkoutIdList = allWorkoutIdList.toSet().difference(targetWorkoutIdList.toSet()).toList();
    targetWorkoutIdList.addAll(otherWorkoutIdList);

    // workout id 값을 가지고 리스트 데이터 맵핑
    for (int i = 0; i < targetWorkoutIdList.length; i++) {
      for (int j = 0; j < allWorkouts.length; j++) {
        if (allWorkouts[j]['workout'] == targetWorkoutIdList[i]) {
          resultTargetWorkouts.add(allWorkouts[j]);
        }
      }
    }

    // State 변경
    if (originalPickedWorkoutsFromDB.isNotEmpty) {
      setState(() {
        todayTargetWorkouts = resultTargetWorkouts;
      });
    } else {
      setState(() {
        todayTargetWorkouts = allWorkouts;
      });
    }

    if (todayTargetWorkouts.isNotEmpty) {
      setNowWorkoutName(todayTargetWorkouts[workoutIndex]['name']);
    }
  }

  List<int> searchDifferentIndex(List<Target> list) {
    List<int> indexList = [];

    for (int i = 0; i < list.length - 1; i++) {
      if (list[i].bodypartID != list[i + 1].bodypartID) {
        indexList.add(i);
      }
    }

    return indexList;
  }

  void setProgressiveUI(int workoutID) async {
    var datas = await getDateByWorkoutDB(workoutID);
    if (isProgressive(datas)) {
      print('점진적 과부하 미흡');
    } else {
      print('점진적 과부하 양호');
    }
  }

  Future<void> initData() async {
    if (isWorkoutEmpty) {
      print('empty');
    } else {
      setTodayCompletedWorkouts();
      await setTargetWorkout();

      Future.delayed(const Duration(milliseconds: 500), () async {
        var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
        setNowSetNumber(temp + 1);
        await setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
        setTodayVolumn(todayTargetWorkouts[workoutIndex]['workout']);
        setLatestVolumn(todayTargetWorkouts[workoutIndex]['workout']);
        setNowWorkoutID(todayTargetWorkouts[workoutIndex]['workout']);
        setSuggestion();
      });
    }
  }

  Future<List<Map<String, dynamic>>> getDateByWorkoutDB(int workoutID) async {
    var datas = await DBHelper.instance.getDateByWorkout(workoutID);
    return datas;
  }

  bool isProgressive(List<Map<String, dynamic>> datas) {
    var averageVolumn = datas.map((e) => e['volumn']).reduce((value, element) => value + element) / datas.length;
    for (var data in datas) {
      if ((averageVolumn - data['volumn']).abs() / averageVolumn > 0.05) {
        return true;
      }
    }
    return false;
  }

  Future<void> prefixIsWorkoutEmpty() async {
    List<Map<String, dynamic>> data = await DBHelper.instance.getWorkouts();
    if (data.length == 0) {
      setState(() {
        isWorkoutEmpty = true;
      });
    } else {
      setState(() {
        isWorkoutEmpty = false;
      });
    }
  }

  Future<void> ensureEmptyWorkout() async {
    await prefixIsWorkoutEmpty();
    await initData();
  }

  void setAppFinish() {
    setState(() {
      if (countTimer != null) {
        stopTimer();
        resetTimer(0, 0);
      }
    });
    setAppStatus(APP_STATUS.FINISH);
  }

  void setNowWorkoutName(String workoutName) {
    setState(() {
      nowWorkoutName = workoutName;
    });
  }

  void setNowWorkoutID(int id) {
    setState(() {
      nowWorkoutID = id;
    });
  }

  void setNowWorkoutWeight(int weight) {
    setState(() {
      targetWeight = weight;
    });
  }

  void setNowWorkoutReps(int reps) {
    setState(() {
      targetReps = reps;
    });
  }

  void setNowSetNumber(int number) {
    setState(() {
      nowSetNumber = number;
    });
  }

  void setIsStarted(bool isStart) {
    setState(() {
      isStarted = isStart;
    });
  }

  void setWorkoutIndexIncrease() {
    if (workoutIndex < todayTargetWorkouts.length - 1) {
      setState(() {
        workoutIndex++;
      });
    }
  }

  void setWorkoutIndexDecrease() {
    setState(() {
      workoutIndex--;
    });
  }

  void setAppStatus(APP_STATUS status) {
    setState(() {
      workoutMode = status;
    });
  }

  void setTodayCompletedWorkouts() async {
    todayCompletedWorkoutsInGroup = {};
    List<Map<String, dynamic>> completedWorkouts = [];
    completedWorkouts = await DBHelper.instance.getCompletedWorkouts();
    setState(() {
      todayCompletedWorkouts = completedWorkouts;
    });
    todayCompletedWorkoutsInGroup = groupBy(todayCompletedWorkouts, (Map obj) => obj['name']).cast<String, List>();
  }

  void startTimer(TIMER_TYPE type) {
    switch (type) {
      case TIMER_TYPE.UP:
        countTimer = Timer.periodic(Duration(seconds: 1), (_) => setCountUp());
        break;
      case TIMER_TYPE.DOWN:
        countTimer = Timer.periodic(Duration(seconds: 1), (_) => setCountDown());
        break;
    }
  }

  void stopTimer() {
    setState(() => countTimer!.cancel());
  }

  void resetTimer(int min, int sec) {
    stopTimer();
    setState(() => myDuration = Duration(minutes: min, seconds: sec));
  }

  void setCountDown() {
    final reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countTimer!.cancel();
        setAppStatus(APP_STATUS.IN_BREAK);
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

  void addWeight(int targetWeight) {
    setState(() {
      this.targetWeight += targetWeight;
    });
  }

  void reduceWeight(int targetWeight) {
    if (this.targetWeight - targetWeight >= 0) {
      setState(() {
        this.targetWeight -= targetWeight;
      });
    }
  }

  void addReps(int number) {
    setState(() {
      this.targetReps += number;
    });
  }

  void reduceReps(int number) {
    if (this.targetReps - number >= 1) {
      setState(() {
        this.targetReps -= number;
      });
    }
  }

  bool isNewSet(int index, DateTime setDate) {
    final int TIME_DIFFERENCE = 10;
    DateTime now = DateTime.now();
    int difference = now.difference(setDate).inMinutes;

    if (index == 0 && difference < TIME_DIFFERENCE) {
      return true;
    } else {
      return false;
    }
  }

  void setSuggestion() async {
    setState(() {
      suggestion_index = SUGGESTION_INDEX.LATEST_SET_INFO;
    });

    var data = await DBHelper.instance.getLatestSetHistory(nowWorkoutID);

    if (data.isEmpty) {
      setState(() {
        history = [];
      });
    } else if (data.isNotEmpty) {
      setState(() {
        history = data;
        lastSetNumber = data.last['set_order'];
      });
    }
    setSuggestionData();
  }

  void setSuggestionData() {
    if (history.isEmpty) {
      if (nowSetNumber > 1) {
        setSuggestionMessage('조금 전 세트를 메모해보세요\n다음 운동시 리마인드 해드려요');
      } else {
        setSuggestionMessage('다음 운동부터 중량, 횟수가 자동설정 돼요');
      }
    } else if (history.length >= nowSetNumber) {
      switchSuggestionMessage();
    } else if (history.length < nowSetNumber) {
      setState(() {
        suggestion_index = SUGGESTION_INDEX.OVER_SET_INFO;
      });
      switchSuggestionMessage();
    }
  }

  void setSuggestionMessage(String string) {
    setState(() {
      message = string;
    });
  }

  void shuffleSuggestionMessage() {
    int index = SUGGESTION_INDEX.values.indexOf(suggestion_index);
    if (index < SUGGESTION_INDEX.values.length) {
      setState(() {
        index += 1;
        if (index >= SUGGESTION_INDEX.values.length) {
          index = 0;
        }
        if (index == SUGGESTION_INDEX.values.indexOf(SUGGESTION_INDEX.OVER_SET_INFO)) {
          index = 0;
        }
        suggestion_index = SUGGESTION_INDEX.values[index];
      });
    }
    setSuggestionData();
  }

  void switchSuggestionMessage() {
    int set;
    int weight;
    int reps;
    String type;
    String note;

    switch (suggestion_index) {
      case SUGGESTION_INDEX.LATEST_SET_INFO:
        set = history[nowSetNumber - 1]['set_order'];
        weight = history[nowSetNumber - 1]['weight'];
        reps = history[nowSetNumber - 1]['result_num_time'];
        type = history[nowSetNumber - 1]['type'];
        setSuggestionMessage('지난 번 ${set}세트 ${weight}kg, $reps회는 $type했어요');
        break;
      case SUGGESTION_INDEX.NOTE_INFO:
        if (history[nowSetNumber - 1]['note'].isEmpty) {
          if (nowSetNumber == 1) {
            note = '세트 종료 후 메모를 남겨보세요';
          } else {
            note = '조금 전 세트를 메모해보세요\n다음 운동시 리마인드 해드려요';
          }
        } else {
          note = history[nowSetNumber - 1]['note'];
        }

        setSuggestionMessage(note);
        break;
      case SUGGESTION_INDEX.NEXT_SET_INFO:
        if (nowSetNumber == lastSetNumber) {
          setSuggestionMessage('마지막 세트, 조금만 더 힘내세요!');
        } else {
          weight = history[nowSetNumber]['weight'];
          reps = history[nowSetNumber]['result_num_time'];
          type = history[nowSetNumber]['type'];
          setSuggestionMessage('다음 세트 ${weight}kg, $reps회에서는 $type했어요');
        }
        break;
      case SUGGESTION_INDEX.OVER_SET_INFO:
        num difference = (todayVolumn - latestVolumn).abs();
        if (todayVolumn == latestVolumn) {
          setSuggestionMessage('지난 번과 볼륨이 같아요');
        } else if (todayVolumn < latestVolumn) {
          setSuggestionMessage('지난 번 보다 볼륨이 ${difference}kg 줄었어요');
        } else if (todayVolumn > latestVolumn) {
          setSuggestionMessage('지난 번 보다 볼륨이 ${difference}kg 늘었어요');
        }
    }
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }
}
