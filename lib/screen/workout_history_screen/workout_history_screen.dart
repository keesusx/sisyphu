import 'package:flutter/material.dart';
import 'package:sisyphu/screen/workout_history_screen/workout_history.dart';
import 'package:collection/collection.dart';
import '../../db/db_helper.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
          WorkoutHistory(),
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
}
