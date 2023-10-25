import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sisyphu/screen/workout_history_screen/workout_history.dart';
import '../../db/db_helper.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late ScrollController _scrollController;

  List<DateTime> dates = [];

  late Map<String, List<Map<String, dynamic>>> resultInGroup;
  late Map<String, List> setListInGroup;

  bool isLoading = true;
  int dateGenerateNumber = 14;

  @override
  void initState() {
    super.initState();

    resultInGroup = {};
    setListInGroup = {};
    _scrollController = ScrollController()..addListener(scrollListener);
    syncWorkoutDates();

    Future.delayed(Duration(milliseconds: 300), () {
      dates =
          List.generate(dateGenerateNumber, (index) => DateTime.now().subtract(Duration(days: dateGenerateNumber - (index + 1)))).reversed.toList();
      fetchHistoryData();
      isLoading = false;
    });

    // print(resultInGroup);
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('분석'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: '기록'),
              Tab(text: '부위별'),
              Tab(text: '종합'),
            ],
          ),
        ),
        body: TabBarView(children: [
          isLoading == true
              ? Center(
                  child: Text('기록이 없습니다.'),
                )
              : WorkoutHistory(historyList: resultInGroup, scrollController: _scrollController),
          Container(
            child: Center(
              child: Text('준비 중입니다'),
            ),
          ),
          Container(
            child: Center(
              child: Text('준비 중입니다'),
            ),
          ),
        ]),
      ),
    );
  }

  void syncWorkoutDates() async {
    var temp = await DBHelper.instance.getSetsInGroup();
    setState(() {
      setListInGroup = groupBy(temp, (obj) {
        return obj['created_at'].toString().substring(0, 10);
      });
      // print('setsListInGroup $setListInGroup');
    });
  }

  void fetchHistoryData() {
    List<Map<String, dynamic>> result = [];
    dates.forEachIndexed((index, element) {
      if (setListInGroup.containsKey(element.toString().substring(0, 10))) {
        setListInGroup.keys.toList().forEachIndexed((i, value) {
          if (value == element.toString().substring(0, 10)) {
            setState(() {
              for (int j = 0; j < setListInGroup.entries.toList()[i].value.length; j++) {
                result.add({
                  "date": element.toString().substring(0, 10),
                  "name": setListInGroup.entries.toList()[i].value.toList()[j]['name'],
                  "bodypart": setListInGroup.entries.toList()[i].value.toList()[j]['bodypart_name'].toString(),
                  "datediff": setListInGroup.entries.toList()[i].value.toList()[j]['datediff'],
                  "count": setListInGroup.entries.toList()[i].value.toList()[j]['count'],
                  "minimum_weight": setListInGroup.entries.toList()[i].value.toList()[j]['minimum_weight'],
                  "maximum_weight": setListInGroup.entries.toList()[i].value.toList()[j]['maximum_weight'],
                  "average_weight": setListInGroup.entries.toList()[i].value.toList()[j]['average_weight'],
                  "minimum_reps": setListInGroup.entries.toList()[i].value.toList()[j]['minimum_reps'],
                  "maximum_reps": setListInGroup.entries.toList()[i].value.toList()[j]['maximum_reps'],
                  "average_reps": setListInGroup.entries.toList()[i].value.toList()[j]['average_reps'],
                  "volumn": setListInGroup.entries.toList()[i].value.toList()[j]['volumn'],
                });
              }
            });
          }
        });
      } else {
        result.add(
            {"date": element.toString().substring(0, 10), "datediff": DateTime.now().difference(DateTime.parse(element.toIso8601String())).inDays});
      }
    });
    resultInGroup = result.groupListsBy((obj) => obj['date'].toString().substring(0, 10));
  }

  void scrollListener() {
    if (_scrollController.position.atEdge) {
      bool isTop = _scrollController.position.pixels == 0;
      if (isTop) {
      } else {
        print('adding dates!');
        setState(() {
          for (int j = 0; j < 10; j++) {
            setState(() {
              dates.add(dates.last.subtract(Duration(days: 1)));
            });
          }
        });
        fetchHistoryData();
      }
    }
  }
}
