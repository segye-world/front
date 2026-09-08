class ApiConfig {
  // 실기기(USB): PC에서 `adb reverse tcp:8080 tcp:8080` 실행 후 127.0.0.1 사용
  // 에뮬레이터: adb reverse 없이 쓰려면 10.0.2.2 로 변경
  static const baseUrl = 'http://10.0.2.2:8080';

  // Dio 기반 API 클라이언트에서 공통으로 사용하는 백엔드 API 경로입니다.
  static const apiPrefix = '/api/v1';
}
