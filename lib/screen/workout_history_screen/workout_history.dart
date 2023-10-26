import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:collection/collection.dart';
import 'package:sisyphu/db/daily_body_stats.dart';
import '../../db/db_helper.dart';
import 'package:flutter/services.dart';

class WorkoutHistory extends StatefulWidget {
  const WorkoutHistory({super.key});

  @override
  State<WorkoutHistory> createState() => _WorkoutHistoryState();
}

class _WorkoutHistoryState extends State<WorkoutHistory> {
  late DateFormat daysFormat;
  late ScrollController _scrollController;

  List<DateTime> dates = [];
  late Map<String, List> setListInGroup;
  late Map<String, List<Map<String, dynamic>>> historyList;

  final int dateGenerateNumber = 14;

  late List<DailyBodyStats> dailyBodyStats = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting();
    daysFormat = DateFormat.EEEE('ko');

    _scrollController = ScrollController()..addListener(scrollListener);

    setListInGroup = {};
    historyList = {};
    syncWorkoutDates();
    syncDailyBodyStats();
    Future.delayed(Duration(milliseconds: 300), () {
      dates =
          List.generate(dateGenerateNumber, (index) => DateTime.now().subtract(Duration(days: dateGenerateNumber - (index + 1)))).reversed.toList();
      fetchHistoryData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.separated(
        separatorBuilder: (BuildContext context, int index) => Divider(
          thickness: 1,
        ),
        controller: _scrollController,
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
                // leading: Text(daysFormat.format(DateTime.parse(historyList.keys.toList()[index])).substring(0,1)),
                leading: IconButton(
                  icon: Image.asset(
                    'assets/images/icons/weight-scale.png',
                    width: 20,
                  ),
                  onPressed: () {
                    // print(historyList.keys.toList()[k]);
                    openDialog(index);
                    // DBHelper.instance.insertDailyBodyStats(DailyBodyStats(weight: , skeletalMuscle:, fatRate:, note: , createdAt: , updatedAt: updatedAt))
                  },
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(historyList.keys.toList()[index].toString()),
                        Spacer(),
                        Text(daysFormat.format(DateTime.parse(historyList.keys.toList()[index])).substring(0, 1)),
                        calDateDiffInString(historyList.entries.toList()[index].value.toList().first['datediff'].ceil()),
                      ],
                    ),
                  ],
                ),
                trailing: historyList.entries.toList()[index].value.toList().first['bodypart'] != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          titleWithBodyparts(index, historyList.entries.toList()[index].value.toList().length),
                          Icon(Icons.keyboard_arrow_down_outlined),
                        ],
                      )
                    : Icon(Icons.battery_charging_full_rounded, color: Colors.pink),
                subtitle: historyList.entries.toList()[index].value.toList().first['weight'] != null
                    ? Text('체중: ${historyList.entries.toList()[index].value.toList().first['weight']}kg')
                    : Text('체중: -'),
                children: [
                  historyList.entries.toList()[index].value.toList().first['bodypart'] != null
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            horizontalMargin: 0,
                            columns: _getColumns(),
                            rows: _getRows(index),
                          ),
                        )
                      : Container()
                ]
                // historyList.entries.toList()[index].value.toList().map((e) => Text(e['bodypart'].toString())).toList()
                ),
          );
        },
      ),
    );
  }

  Widget calDateDiffInString(int dateDiff) {
    switch (dateDiff) {
      case 0:
        return Text('(오늘)');
      case 1:
        return Text('(어제)');
      default:
        return Text('(' + dateDiff.toString() + '일 전)');
    }
  }

  Widget titleWithBodyparts(int k, int j) {
    List<String> temp = [];
    for (int i = 0; i < j; i++) {
      if (historyList.entries.toList()[k].value.toList()[i]['bodypart'] != null) {
        temp.add(historyList.entries.toList()[k].value.toList()[i]['bodypart']);
      }
    }
    List<String> bodypartsInSet = temp.toSet().toList();

    String result = '';
    bodypartsInSet.forEach((element) {
      result += element.toString() + ' ';
    });
    return Text(result);
  }

  List<DataColumn> _getColumns() {
    const TextStyle _style = TextStyle(fontSize: 12);
    final List<String> setHistoryDataDivisions = [
      '부위',
      '종목',
      '무게',
      '세트',
      '횟수',
    ];

    List<DataColumn> dataColumn = [];
    setHistoryDataDivisions.forEach((item) => dataColumn.add(DataColumn(label: Text(item, style: _style))));
    return dataColumn;
  }

  List<DataRow> _getRows(int index) {
    const TextStyle _style = TextStyle(fontSize: 12);

    List<DataRow> dataRow = [];
    for (int j = 0; j < historyList.entries.toList()[index].value.length; j++) {
      List<DataCell> dataCells = [];
      dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['bodypart'].toString(), style: _style)));
      dataCells.add(DataCell(ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 120),
        child: Text(historyList.entries.toList()[index].value.toList()[j]['name'].toString(), overflow: TextOverflow.ellipsis, style: _style),
      )));

      if (historyList.entries.toList()[index].value.toList()[j]['minimum_weight'] ==
          historyList.entries.toList()[index].value.toList()[j]['maximum_weight']) {
        dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['minimum_weight'].toString() + 'kg')));
      } else {
        dataCells.add(DataCell(Text(
            historyList.entries.toList()[index].value.toList()[j]['minimum_weight'].toString() +
                '~' +
                historyList.entries.toList()[index].value.toList()[j]['maximum_weight'].toString() +
                'kg',
            style: _style)));
      }

      dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['count'].toString(), style: _style)));

      if (historyList.entries.toList()[index].value.toList()[j]['minimum_reps'] ==
          historyList.entries.toList()[index].value.toList()[j]['maximum_reps']) {
        dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['minimum_reps'].toString())));
      } else {
        dataCells.add(DataCell(Text(
            historyList.entries.toList()[index].value.toList()[j]['minimum_reps'].toString() +
                '~' +
                historyList.entries.toList()[index].value.toList()[j]['maximum_reps'].toString(),
            style: _style)));
      }
      dataRow.add(DataRow(cells: dataCells));
    }
    return dataRow;
  }

  void syncWorkoutDates() async {
    var temp = await DBHelper.instance.getSetsInGroup();

    setState(() {
      setListInGroup = groupBy(temp, (obj) {
        return obj['created_at'].toString().substring(0, 10);
      });
    });
  }

  void syncDailyBodyStats() async {
    List<DailyBodyStats> temp = await DBHelper.instance.getDailyBodyStats();
    setState(() {
      dailyBodyStats = temp;
    });
    dailyBodyStats.toList().forEach((element) => print(element.createdAt));
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

    historyList = result.groupListsBy((obj) => obj['date'].toString().substring(0, 10));

    for (int i = 0; i < historyList.length; i++) {
      for (int k = 0; k < dailyBodyStats.length; k++) {
        if (historyList.keys.toList()[i] == dailyBodyStats[k].createdAt) {
          historyList.entries.toList()[i].value.forEach((element) {
            element['weight'] = dailyBodyStats[k].weight;
          });
        }
      }
    }
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

  void openDialog(int index) {
    final textInputControllerWeight = TextEditingController();
    final textInputControllerSkeletalMuscle = TextEditingController();
    final textInputControllerFatRate = TextEditingController();
    var textInputControllerNote = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                actionsOverflowDirection: VerticalDirection.down,
                scrollable: true,
                actionsAlignment: MainAxisAlignment.end,
                title: Text('${historyList.keys.toList()[index]} 체위'),
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('몸무게(kg)'),
                        TextField(
                          //키보드에 점 띄우기
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                          //소수점 입력 formatter 처리
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                            TextInputFormatter.withFunction((oldValue, newValue) {
                              final text = newValue.text;
                              return text.isEmpty
                                  ? newValue
                                  : double.tryParse(text) == null
                                      ? oldValue
                                      : newValue;
                            }),
                          ],
                          controller: textInputControllerWeight,
                          // decoration: InputDecoration(hintText: '${newWeight}kg'),
                        ),
                        const SizedBox(height: 20),
                        const Text('골격근(kg)'),
                        TextField(
                          keyboardType: TextInputType.number,
                          controller: textInputControllerSkeletalMuscle,
                          // decoration: InputDecoration(hintText: '$newReps회'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('체지방률(%)'),
                          ],
                        ),
                        TextField(
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          controller: textInputControllerNote,
                          // decoration: InputDecoration(hintText: '$newNote'),
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
                        Navigator.of(context).pop();
                      },
                      child: const Text('확인')),
                ]));
  }
}
