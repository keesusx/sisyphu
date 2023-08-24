import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sisyphu/db/bodyparts_workouts.dart';
import '../db/db_helper.dart';
import '../db/workouts.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final textController = TextEditingController();
  late String createdAt;
  late String updatedAt;
  late String dropdownBodyPartValue;
  late String dropdownWorkoutNameValue;

  late List<Map<String, dynamic>> workouts;
  late Map<String, List> workoutsInGroup;

  final List<String> bodyparts = ['가슴', '등', '어깨', '팔', '하체'];

  List<String> chestEntries = [
    '벤치 프레스',
    '인클라인 벤치 프레스',
    '체스트 프레스',
    '케이블 플라이',
    '펙덱 플라이',
    '딥스',
    '푸시업'
  ];

  List<String> backEntries = [
    '풀 업',
    '데드 리프트',
    '랫 풀 다운',
    '암 풀 다운',
    '시티드 로우',
    '바벨 로우',
    '덤벨 로우',
  ];

  List<String> sholuderEntries = [
    '숄더 프레스',
    '오버 헤드 프레스',
    '사이드 레터럴 레이즈',
    '프론트 레이즈',
    '백 플라이',
  ];

  List<String> armEntries = [
    '바벨 컬',
    '덤벨 컬',
    '머신 컬',
    '해머 컬',
    '오버헤드 익스텐션',
    '덤벨 킥백'
  ];

  List<String> legEntries = [
    '스쿼트',
    '레그 익스텐션',
    '레그 컬',
    '레그 프레스',
  ];

  late List<String> selectedEntries;

  @override
  void initState() {
    dropdownBodyPartValue = bodyparts.first;
    workoutsInGroup = {};
    selectedEntries = chestEntries;

    Future.delayed(const Duration(milliseconds: 300), () async {
      setWorkoutList();
    });
  }

  void setWorkoutList() async {
    workoutsInGroup = {};
    workouts = await DBHelper.instance.getWorkoutWithBodyPart();
    setState(() {
      workoutsInGroup =
          groupBy(workouts, (Map obj) => obj['bodypart']).cast<String, List>();
    });
  }

  void switchRecommendEntries(String value) {
    selectedEntries = [];
    switch (value) {
      case '가슴':
        setState(() {
          selectedEntries = chestEntries;
        });
        break;
      case '등':
        setState(() {
          selectedEntries = backEntries;
        });
        break;
      case '어깨':
        setState(() {
          selectedEntries = sholuderEntries;
        });
        break;
      case '팔':
        setState(() {
          selectedEntries = armEntries;
        });
        break;
      case '하체':
        setState(() {
          selectedEntries = legEntries;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text('운동 추가')),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                menuLabel('운동 추가하기'),
                SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton(
                          hint: Text('종류'),
                          value: dropdownBodyPartValue,
                          items: bodyparts.map((String value) {
                            return DropdownMenuItem(
                                value: value, child: Text(value));
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              dropdownBodyPartValue = value!;
                            });
                            switchRecommendEntries(value!);
                          }),
                      Flexible(
                        fit: FlexFit.loose,
                        child: TextField(
                          decoration: InputDecoration(
                              border: OutlineInputBorder(), labelText: '운동이름'),
                          controller: textController,
                          // onChanged: (String newValue) {
                          //   setState(() {
                          //     textController.text = newValue;
                          //   });
                          // },
                        ),
                      ),
                      IconButton(
                          onPressed: () async {
                            createdAt = DateTime.now().toIso8601String();
                            updatedAt = DateTime.now().toIso8601String();
                            if (textController.text != '' &&
                                dropdownBodyPartValue != '') {
                              var workoutID = await DBHelper.instance
                                  .insertWorkouts(Workouts(
                                      name: textController.text,
                                      created_at: createdAt,
                                      updated_at: updatedAt));
                              await DBHelper.instance.insertBodypartsWorkouts(
                                  BodypartsWorkouts(
                                      workout: workoutID,
                                      bodypart: dropdownBodyPartValue,
                                      createdAt: createdAt,
                                      updatedAt: updatedAt));
                              setState(() {
                                textController.clear();
                                dropdownBodyPartValue = bodyparts.first;
                              });
                              setWorkoutList();
                            }
                          },
                          icon: Icon(Icons.add))
                    ],
                  ),
                ),
                workoutEntry(),
                SizedBox(height: 40),
                menuLabel('운동 리스트'),
                SizedBox(height: 20),
                workoutList()
              ],
            ),
          ),
        ));
  }

  Widget workoutEntry() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: selectedEntries.length,
          itemBuilder: (BuildContext context, int index) {
            return TextButton(
                onPressed: () {
                  setState(() {
                    textController.text = selectedEntries[index];
                  });
                },
                child: Text(
                  selectedEntries[index],
                  style: TextStyle(color: Colors.pink, fontSize: 12),
                ));
          }),
    );
  }

  Widget menuLabel(String text) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 20))
        ],
      ),
    );
  }

  Widget workoutList() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: workoutsInGroup.length,
        itemBuilder: (BuildContext context, int index) {
          return Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
                initiallyExpanded: false,
                title: Text(workoutsInGroup.keys.toList()[index].toString()),
                children: List<Widget>.generate(
                    workoutsInGroup.entries.toList()[index].value.length,
                    (int i) {
                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(workoutsInGroup.entries
                              .toList()[index]
                              .value
                              .toList()[i]['name']
                              .toString()),
                        ],
                      ),
                    ),
                  );
                })),
          );
        });
  }
}
