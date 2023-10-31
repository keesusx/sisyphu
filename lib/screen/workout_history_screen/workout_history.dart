import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:collection/collection.dart';
import 'package:sisyphu/db/daily_body_stats.dart';
import '../../db/db_helper.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;

class WorkoutHistory extends StatefulWidget {
  const WorkoutHistory({super.key});

  @override
  State<WorkoutHistory> createState() => _WorkoutHistoryState();
}

class _WorkoutHistoryState extends State<WorkoutHistory> {
  late DateFormat daysFormat;
  late ScrollController _scrollController;
  late bool isExistDailyBodyStat;

  List<DateTime> dates = [];
  late Map<String, List> setListInGroup;
  late Map<String, List<Map<String, dynamic>>> historyList;

  final int dateGenerateNumber = 25;

  late List<DailyBodyStats> dailyBodyStats = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting();
    daysFormat = DateFormat.EEEE('ko');
    isExistDailyBodyStat = false;

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

    // var temp = DBHelper.instance.isExistDailyBodyStat(DateTime(2023,10,22));
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('widget build');

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
                expandedAlignment: Alignment.centerLeft,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(historyList.keys.toList()[index].toString()),
                        Text(' '),
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
                    ? Row(
                        children: [
                          Text('체중: ${historyList.entries.toList()[index].value.toList().first['weight']}kg'),
                          IconButton(
                              onPressed: () => openDialog(index, true),
                              icon: Icon(
                                Icons.edit,
                                size: 20,
                              ))
                        ],
                      )
                    : Row(
                        children: [
                          Text('체중:'),
                          IconButton(
                              onPressed: () => openDialog(index, false),
                              icon: Icon(
                                Icons.add_chart,
                                color: Colors.pink,
                                size: 20,
                              ))
                        ],
                      ),
                children: [
                  historyList.entries.toList()[index].value.toList().first['bodypart'] != null
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 30,
                            columns: _getColumns(),
                            rows: _getRows(index),
                          ),
                        )
                      : Container()
                ]),
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
        dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['minimum_weight'].toString() + 'kg', style: _style)));
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
        dataCells.add(DataCell(Text(historyList.entries.toList()[index].value.toList()[j]['minimum_reps'].toString(), style: _style)));
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

  Future<void> syncDailyBodyStats() async {
    List<DailyBodyStats> temp = await DBHelper.instance.getDailyBodyStats();
    setState(() {
      dailyBodyStats = temp;
    });
  }

  Future<void> fetchHistoryData() async {
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

    setState(() {
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
    });
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

  void openAlert() {
    print('show alert');
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('필수'),
          );
        });
  }

  void openDialog(int index, bool isExist) async {
    final textInputControllerWeight = TextEditingController();
    final textInputControllerSkeletalMuscle = TextEditingController();
    final textInputControllerFatRate = TextEditingController();
    final textInputControllerNote = TextEditingController();

    var stats;
    if (isExist) {
      stats = await DBHelper.instance.getDailyBodyStatByDate(DateTime.parse(historyList.keys.toList()[index]));
    }

    // aysnc 와 context를 함께 사용할때 방어코드. 위젯이 마운트되지 않으면 context에 아무값도 없을 확률이 있기 때문
    if (!mounted) {
      return;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
                actionsOverflowDirection: VerticalDirection.down,
                scrollable: true,
                actionsAlignment: MainAxisAlignment.end,
                title: Text('${historyList.keys.toList()[index]} 체위'),
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Builder(builder: (context) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('몸무게(kg)'),
                            TextFormField(
                              //키보드에 점 띄우기
                              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                              //소수점 입력 formatter 처리
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
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
                              validator: (text) {
                                if (text == null || text.isEmpty) {
                                  return '몸무게는 필수 입력사항 입니다.';
                                }
                                return null;
                              },
                              decoration: InputDecoration(hintText: isExist ? '${stats[0].weight}kg' : ''),
                            ),
                            const SizedBox(height: 20),
                            const Text('골격근(kg)'),
                            TextField(
                              keyboardType: TextInputType.number,
                              //소수점 입력 formatter 처리
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
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
                              controller: textInputControllerSkeletalMuscle,
                              decoration: InputDecoration(
                                  hintText: isExist
                                      ? stats[0].skeletalMuscle == null
                                          ? '-'
                                          : '${stats[0].skeletalMuscle}kg'
                                      : ''),
                            ),
                            const SizedBox(height: 20),
                            const Text('체지방률(%)'),
                            TextField(
                              //키보드에 점 띄우기
                              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                              //소수점 입력 formatter 처리
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
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
                              controller: textInputControllerFatRate,
                              decoration: InputDecoration(
                                  hintText: isExist
                                      ? stats[0].fatRate == null
                                          ? '-'
                                          : '${stats[0].fatRate}%'
                                      : ''),
                            ),
                            const SizedBox(height: 20),
                            const Text('컨디션'),
                            TextField(
                              textInputAction: TextInputAction.newline,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              controller: textInputControllerNote,
                              decoration: InputDecoration(
                                  hintText: isExist
                                      ? stats[0].note == null
                                          ? '-'
                                          : '${stats[0].note}'
                                      : ''),
                            )
                          ],
                        ),
                      );
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                      onPressed: () async {
                        switch (isExist) {
                          case true:
                            if (textInputControllerWeight.text.isEmpty &&
                                textInputControllerSkeletalMuscle.text.isEmpty &&
                                textInputControllerNote.text.isEmpty &&
                                textInputControllerFatRate.text.isEmpty) {
                              break;
                            } else {
                              DailyBodyStats data = DailyBodyStats(
                                  id: stats[0].id,
                                  weight: textInputControllerWeight.text.isEmpty
                                      ? double.parse(stats[0].weight.toString())
                                      : double.parse(textInputControllerWeight.text),
                                  skeletalMuscle: textInputControllerSkeletalMuscle.text.isEmpty
                                      ? stats[0].skeletalMuscle == null
                                          ? null
                                          : double.parse(stats[0].skeletalMuscle.toString())
                                      : double.parse(textInputControllerSkeletalMuscle.text),
                                  fatRate: textInputControllerFatRate.text.isEmpty
                                      ? stats[0].fatRate == null
                                          ? null
                                          : double.parse(stats[0].fatRate.toString())
                                      : double.parse(textInputControllerFatRate.text),
                                  note: textInputControllerNote.text.isEmpty
                                      ? stats[0].note == null
                                          ? null
                                          : stats[0].note
                                      : textInputControllerNote.text,
                                  createdAt: stats[0].createdAt,
                                  updatedAt: DateTime.now().toIso8601String());

                              DBHelper.updateDailyBodyStat(data);
                            }
                            await syncDailyBodyStats();
                            await fetchHistoryData();
                            Navigator.of(context).pop();
                            break;
                          case false:
                            if (textInputControllerWeight.text.isEmpty) {
                              // openAlert();
                              if (_formKey.currentState!.validate()) {
                                // TODO submit
                              }
                            } else if (textInputControllerWeight.text.isNotEmpty) {
                              await DBHelper.insertDailyBodyStats(DailyBodyStats(
                                  weight: double.parse(textInputControllerWeight.text),
                                  skeletalMuscle: textInputControllerSkeletalMuscle.text.isNotEmpty
                                      ? double.parse(textInputControllerSkeletalMuscle.text.toString())
                                      : null,
                                  fatRate:
                                      textInputControllerFatRate.text.isNotEmpty ? double.parse(textInputControllerFatRate.text.toString()) : null,
                                  note: textInputControllerNote.text.isNotEmpty ? textInputControllerNote.text : '',
                                  createdAt: historyList.keys.toList()[index],
                                  updatedAt: historyList.keys.toList()[index]));
                              await syncDailyBodyStats();
                              await fetchHistoryData();
                              Navigator.of(context).pop();
                            }

                            break;
                        }
                      },
                      child: const Text('확인')),
                ]));
  }
}
