import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../db/db_helper.dart';

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

  late DateFormat daysFormat;
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    daysFormat = DateFormat.EEEE('ko');

    resultInGroup = {};
    setListInGroup = {};
    _scrollController = ScrollController()..addListener(scrollListener);
    syncWorkoutDates();

    Future.delayed(Duration(milliseconds: 300), () {
      dates = List.generate(
              dateGenerateNumber,
              (index) => DateTime.now()
                  .subtract(Duration(days: dateGenerateNumber - (index + 1))))
          .reversed
          .toList();
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
        body: TabBarView(
            children: [
          isLoading == true
              ? Center(child: Text('기록이 없습니다.'),)
              : Scrollbar(
                  controller: _scrollController,
                  child: ListView.separated(
                    separatorBuilder: (BuildContext context, int index) =>
                        Divider(
                      thickness: 1,
                    ),
                    controller: _scrollController,
                    itemCount: resultInGroup.length,
                    itemBuilder: (context, index) {
                      return Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                            // leading: Text(daysFormat.format(DateTime.parse(resultInGroup.keys.toList()[index])).substring(0,1)),
                            title: Row(
                              children: [
                                Text(resultInGroup.keys
                                    .toList()[index]
                                    .toString()),
                                Text(' '),
                                Text(daysFormat
                                    .format(DateTime.parse(
                                        resultInGroup.keys.toList()[index]))
                                    .substring(0, 1))
                              ],
                            ),
                            trailing: resultInGroup.entries
                                        .toList()[index]
                                        .value
                                        .toList()
                                        .first['bodypart'] !=
                                    null
                                ? Icon(Icons.keyboard_arrow_down_outlined)
                                : Icon(null),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                calDateDiffInString(resultInGroup.entries
                                    .toList()[index]
                                    .value
                                    .toList()
                                    .first['datediff']
                                    .ceil()),
                                titleWithBodyparts(
                                    index,
                                    resultInGroup.entries
                                        .toList()[index]
                                        .value
                                        .toList()
                                        .length)
                              ],
                            ),
                            children: [
                              resultInGroup.entries
                                          .toList()[index]
                                          .value
                                          .toList()
                                          .first['bodypart'] !=
                                      null
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
                            // resultInGroup.entries.toList()[index].value.toList().map((e) => Text(e['bodypart'].toString())).toList()
                            ),
                      );
                    },
                  ),
                ),

          Container(child: Center(child: Text('준비 중입니다'),),),
          Container(child: Center(child: Text('준비 중입니다'),),),
        ]),
      ),
    );
  }

  Widget calDateDiffInString(int dateDiff) {
    switch (dateDiff) {
      case 0:
        return Text('오늘');
      case 1:
        return Text('어제');
      default:
        return Text(dateDiff.toString() + '일 전');
    }
  }

  Widget titleWithBodyparts(int k, int j) {
    List<String> temp = [];
    for (int i = 0; i < j; i++) {
      if (resultInGroup.entries.toList()[k].value.toList()[i]['bodypart'] !=
          null) {
        temp.add(
            resultInGroup.entries.toList()[k].value.toList()[i]['bodypart']);
      } else {
        temp.add('휴식');
      }
    }
    List<String> bodypartsInSet = temp.toSet().toList();

    String result = '';
    bodypartsInSet.forEach((element) {
      result += element.toString() + ' ';
    });
    if (result == '휴식 ') {
      return Icon(Icons.battery_charging_full_rounded, color: Colors.pink);
    }
    return Text(result);
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
              for (int j = 0;
                  j < setListInGroup.entries.toList()[i].value.length;
                  j++) {
                result.add({
                  "date": element.toString().substring(0, 10),
                  "name": setListInGroup.entries.toList()[i].value.toList()[j]
                      ['name'],
                  "bodypart": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['bodypart_name']
                      .toString(),
                  "datediff": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['datediff'],
                  "count": setListInGroup.entries.toList()[i].value.toList()[j]
                      ['count'],
                  "minimum_weight": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['minimum_weight'],
                  "maximum_weight": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['maximum_weight'],
                  "average_weight": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['average_weight'],
                  "minimum_reps": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['minimum_reps'],
                  "maximum_reps": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['maximum_reps'],
                  "average_reps": setListInGroup.entries
                      .toList()[i]
                      .value
                      .toList()[j]['average_reps'],
                  "volumn": setListInGroup.entries.toList()[i].value.toList()[j]
                      ['volumn'],
                });
              }
            });
          }
        });
      } else {
        result.add({
          "date": element.toString().substring(0, 10),
          "datediff": DateTime.now()
              .difference(DateTime.parse(element.toIso8601String()))
              .inDays
        });
      }
    });
    resultInGroup =
        result.groupListsBy((obj) => obj['date'].toString().substring(0, 10));
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
    setHistoryDataDivisions.forEach(
        (item) => dataColumn.add(DataColumn(label: Text(item, style: _style))));
    return dataColumn;
  }

  List<DataRow> _getRows(int index) {
    const TextStyle _style = TextStyle(fontSize: 12);

    List<DataRow> dataRow = [];
    for (int j = 0; j < resultInGroup.entries.toList()[index].value.length; j++) {
      List<DataCell> dataCells = [];
      dataCells.add(DataCell(Text(
          resultInGroup.entries
              .toList()[index]
              .value
              .toList()[j]['bodypart']
              .toString(),
          style: _style)));
      dataCells.add(DataCell(ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 120),
        child: Text(
            resultInGroup.entries
                .toList()[index]
                .value
                .toList()[j]['name']
                .toString(),
            overflow: TextOverflow.ellipsis,
            style: _style),
      )));

     

      if (resultInGroup.entries.toList()[index].value.toList()[j]
              ['minimum_weight'] ==
          resultInGroup.entries.toList()[index].value.toList()[j]
              ['maximum_weight']) {
        dataCells.add(DataCell(Text(resultInGroup.entries
                .toList()[index]
                .value
                .toList()[j]['minimum_weight']
                .toString() +
            'kg')));
      } else {
        dataCells.add(DataCell(Text(
            resultInGroup.entries
                    .toList()[index]
                    .value
                    .toList()[j]['minimum_weight']
                    .toString() +
                '~' +
                resultInGroup.entries
                    .toList()[index]
                    .value
                    .toList()[j]['maximum_weight']
                    .toString() +
                'kg',
            style: _style)));
      }

       dataCells.add(DataCell(Text(
          resultInGroup.entries
              .toList()[index]
              .value
              .toList()[j]['count']
              .toString(),
          style: _style)));
          

      if (resultInGroup.entries.toList()[index].value.toList()[j]
              ['minimum_reps'] ==
          resultInGroup.entries.toList()[index].value.toList()[j]
              ['maximum_reps']) {
        dataCells.add(DataCell(Text(resultInGroup.entries
            .toList()[index]
            .value
            .toList()[j]['minimum_reps']
            .toString())));
      } else {
        dataCells.add(DataCell(Text(
            resultInGroup.entries
                    .toList()[index]
                    .value
                    .toList()[j]['minimum_reps']
                    .toString() +
                '~' +
                resultInGroup.entries
                    .toList()[index]
                    .value
                    .toList()[j]['maximum_reps']
                    .toString(),
            style: _style)));
      }
      dataRow.add(DataRow(cells: dataCells));
    }
    return dataRow;
  }
}
