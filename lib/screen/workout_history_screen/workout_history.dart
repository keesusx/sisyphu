import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


class WorkoutHistory extends StatefulWidget {
  final ScrollController scrollController;
  final Map<String, List<Map<String, dynamic>>> historyList;

  const WorkoutHistory({super.key, required this.historyList, required this.scrollController});

  @override
  State<WorkoutHistory> createState() => _WorkoutHistoryState();
}

class _WorkoutHistoryState extends State<WorkoutHistory> {

  late DateFormat daysFormat;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting();
    daysFormat = DateFormat.EEEE('ko');
  }
  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: widget.scrollController,
      child: ListView.separated(
        separatorBuilder: (BuildContext context, int index) => Divider(
          thickness: 1,
        ),
        controller: widget.scrollController,
        itemCount: widget.historyList.length,
        itemBuilder: (context, index) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
                // leading: Text(daysFormat.format(DateTime.parse(widget.historyList.keys.toList()[index])).substring(0,1)),
                title: Row(
                  children: [
                    Text(widget.historyList.keys.toList()[index].toString()),
                    Text(' '),
                    Text(daysFormat.format(DateTime.parse(widget.historyList.keys.toList()[index])).substring(0, 1))
                  ],
                ),
                trailing: widget.historyList.entries.toList()[index].value.toList().first['bodypart'] != null
                    ? Icon(Icons.keyboard_arrow_down_outlined)
                    : Icon(null),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    calDateDiffInString(widget.historyList.entries.toList()[index].value.toList().first['datediff'].ceil()),
                    titleWithBodyparts(index, widget.historyList.entries.toList()[index].value.toList().length)
                  ],
                ),
                children: [
                  widget.historyList.entries.toList()[index].value.toList().first['bodypart'] != null
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
      if (widget.historyList.entries.toList()[k].value.toList()[i]['bodypart'] != null) {
        temp.add(widget.historyList.entries.toList()[k].value.toList()[i]['bodypart']);
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
    for (int j = 0; j < widget.historyList.entries.toList()[index].value.length; j++) {
      List<DataCell> dataCells = [];
      dataCells.add(DataCell(Text(widget.historyList.entries.toList()[index].value.toList()[j]['bodypart'].toString(), style: _style)));
      dataCells.add(DataCell(ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 120),
        child: Text(widget.historyList.entries.toList()[index].value.toList()[j]['name'].toString(), overflow: TextOverflow.ellipsis, style: _style),
      )));

      if (widget.historyList.entries.toList()[index].value.toList()[j]['minimum_weight'] ==
          widget.historyList.entries.toList()[index].value.toList()[j]['maximum_weight']) {
        dataCells.add(DataCell(Text(widget.historyList.entries.toList()[index].value.toList()[j]['minimum_weight'].toString() + 'kg')));
      } else {
        dataCells.add(DataCell(Text(
            widget.historyList.entries.toList()[index].value.toList()[j]['minimum_weight'].toString() +
                '~' +
                widget.historyList.entries.toList()[index].value.toList()[j]['maximum_weight'].toString() +
                'kg',
            style: _style)));
      }

      dataCells.add(DataCell(Text(widget.historyList.entries.toList()[index].value.toList()[j]['count'].toString(), style: _style)));

      if (widget.historyList.entries.toList()[index].value.toList()[j]['minimum_reps'] ==
          widget.historyList.entries.toList()[index].value.toList()[j]['maximum_reps']) {
        dataCells.add(DataCell(Text(widget.historyList.entries.toList()[index].value.toList()[j]['minimum_reps'].toString())));
      } else {
        dataCells.add(DataCell(Text(
            widget.historyList.entries.toList()[index].value.toList()[j]['minimum_reps'].toString() +
                '~' +
                widget.historyList.entries.toList()[index].value.toList()[j]['maximum_reps'].toString(),
            style: _style)));
      }
      dataRow.add(DataRow(cells: dataCells));
    }
    return dataRow;
  }
}
