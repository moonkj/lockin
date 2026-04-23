import Foundation

/// 리더보드 닉네임 검증. 길이·공백·금칙어 체크.
/// 금칙어는 한국어 욕설·성적 단어 기본 목록 + 자주 쓰이는 영어 비속어.
/// 완벽한 필터는 불가능하지만 눈에 띄는 다수 케이스를 차단하는 목적.
enum NicknameValidator {
    enum ValidationError: Error, LocalizedError {
        case tooShort
        case tooLong
        case containsBannedWord

        var errorDescription: String? {
            switch self {
            case .tooShort:          return "닉네임은 2자 이상이어야 해요."
            case .tooLong:           return "닉네임은 20자 이하로 입력해주세요."
            case .containsBannedWord: return "허용되지 않은 단어가 포함돼 있어요."
            }
        }
    }

    static func validate(_ raw: String) -> Result<String, ValidationError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 { return .failure(.tooShort) }
        if trimmed.count > 20 { return .failure(.tooLong) }
        if containsBanned(trimmed) { return .failure(.containsBannedWord) }
        return .success(trimmed)
    }

    /// 내부 금칙어 판정. 대소문자 무시, 공백 제거 후 부분 일치.
    private static func containsBanned(_ input: String) -> Bool {
        let normalized = input.lowercased()
            .replacingOccurrences(of: " ", with: "")
        for word in bannedWords {
            if normalized.contains(word) { return true }
        }
        return false
    }

    /// 기본 금칙어. 로마자·한글·자주 쓰는 변형. 필요 시 확장.
    /// NOTE: 완벽한 목록은 아니며 운영 중 신고 기반으로 보강하는 것을 전제.
    private static let bannedWords: [String] = [
        // 한국어 욕설
        "시발", "씨발", "씨팔", "시팔", "tlqkf", "ㅅㅂ", "ㅆㅂ",
        "개새", "개색", "개세", "병신", "븅신", "ㅂㅅ",
        "좆", "존나", "좃", "ㅈㄴ",
        "fuck", "shit", "bitch", "asshole", "dick", "pussy", "cunt",
        // 성적 단어
        "섹스", "sex", "야동", "포르노", "porn", "자위", "딸딸",
        "성기", "자지", "보지", "음경", "음순",
        "야한", "야사", "ㅅㅅ", "성관계",
        // 차별·혐오
        "니글", "nigger", "nigga", "faggot",
        // 도박·약물 유도
        "도박사이트", "마약삽니다"
    ]
}
