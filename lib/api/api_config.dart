class ApiConfig {
  // 실기기(USB): PC에서 `adb reverse tcp:8080 tcp:8080` 실행 후 127.0.0.1 사용
  // 에뮬레이터: adb reverse 없이 쓰려면 10.0.2.2 로 변경
  static const baseUrl = 'http://127.0.0.1:8080';
  static const apiPrefix = '/api/v1';
}
