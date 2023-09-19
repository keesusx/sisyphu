
enum TIMER_TYPE { UP, DOWN }
enum APP_STATUS { FINISH, IN_WORKOUT, IN_BREAK }

enum EVALUATION_TYPE {
  EASY('0', '쉬움'),
  SUCCESS('1', '성공'),
  FAIL('2', '실패');

  const EVALUATION_TYPE(this.number, this.label);

  final String number;
  final String label;

}
