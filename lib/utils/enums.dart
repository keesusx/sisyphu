enum TIMER_TYPE { UP, DOWN }

enum APP_STATUS { FINISH, IN_WORKOUT, IN_BREAK }

enum EVALUATION_TYPE {
  EASY('0', '쉬움'),
  SUCCESS('1', '성공'),
  FAIL('2', '실패');

  const EVALUATION_TYPE(this.number, this.label);

  final String number;
  final String label;

  factory EVALUATION_TYPE.getByLabel(String label) {
    print(label);
    return EVALUATION_TYPE.values.firstWhere((value) => value.label == label);
  }
}

enum SUGGESTION_INDEX { LATEST_SET_INFO, NOTE_INFO, NEXT_SET_INFO, OVER_SET_INFO }
