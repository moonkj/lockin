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
        // 0-width 문자 + bidi 마커 (LRE/RLE/PDF/LRO/RLO + LRI/RLI/FSI/PDI + ALM) 제거.
        // + NFC 정규화로 조합형/완성형 일관성 확보.
        let stripped = raw.unicodeScalars.filter {
            ![
                // ZWJ/ZWNJ/ZWSP/word joiner/BOM
                0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF,
                // 전통적 bidi 제어 (Unicode 1.x)
                0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
                // 격리 bidi (Unicode 6.3+) — 이걸 생략하면 새로 삽입된 포맷 공격 통과.
                0x2066, 0x2067, 0x2068, 0x2069,
                // Arabic letter mark
                0x061C
            ].contains($0.value)
        }
        let normalized = String(String.UnicodeScalarView(stripped)).precomposedStringWithCanonicalMapping
        let trimmed = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 { return .failure(.tooShort) }
        if trimmed.count > 20 { return .failure(.tooLong) }
        if trimmed.utf8.count > 60 { return .failure(.tooLong) }
        // 개행·라인분리자 거부 — SwiftUI 가 leaderboard 행을 세로로 늘려버려 다른 사용자
        // UI 를 깨는 주입 공격 차단.
        for s in trimmed.unicodeScalars {
            if s.properties.generalCategory == .control
                || s.properties.generalCategory == .format
                || s == "\n" || s == "\r"
                || s.value == 0x2028 || s.value == 0x2029 {
                return .failure(.containsBannedWord)
            }
        }
        if containsBanned(trimmed) { return .failure(.containsBannedWord) }
        return .success(trimmed)
    }

    /// 내부 금칙어 판정. 구두점·공백·숫자 기반 분리 trick (s.h.i.t / ㅅ ㅂ / 5hit) 을
    /// 추가로 회피시키기 위해 영문/한글 자모 이외 문자는 모두 제거한 pass 로도 검사.
    private static func containsBanned(_ input: String) -> Bool {
        let raw = input.precomposedStringWithCanonicalMapping.lowercased()
        let noSpaces = raw.replacingOccurrences(of: " ", with: "")
        // 편법 회피 방지: 구두점·공백·숫자 등 문자/자모 이외 제거한 고밀도 표현.
        let condensed = String(raw.unicodeScalars.filter { s in
            s.properties.isAlphabetic || (s.value >= 0xAC00 && s.value <= 0xD7A3)
        })
        for word in bannedWords {
            if noSpaces.contains(word) || condensed.contains(word) { return true }
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
