"""
Generate Localizable.strings for 6 languages.
Korean strings are the lookup keys (used by SwiftUI Text("한국어") literal).
Each target language gets its translations; missing keys fall back to the key (Korean).
"""
from pathlib import Path

BASE = Path("/Users/kjmoon/Lockin Focus/LockinFocus/Resources")

# Dictionary: korean_source -> {lang: translation}
# Only strings USER SEES in the UI. Comments / code are untouched.
T = {
    # ============ Dashboard header / cards ============
    "락인 포커스": {"en":"Lockin Focus","ja":"ロックインフォーカス","zh-Hans":"专注锁定","fr":"Lockin Focus","hi":"लॉकिन फ़ोकस"},
    "오늘의 집중": {"en":"Today's Focus","ja":"今日の集中","zh-Hans":"今日专注","fr":"Focus du jour","hi":"आज का फ़ोकस"},
    "허용 앱": {"en":"Allowed Apps","ja":"許可アプリ","zh-Hans":"允许的应用","fr":"Apps autorisées","hi":"अनुमत ऐप्स"},
    "다음 스케줄": {"en":"Next Schedule","ja":"次のスケジュール","zh-Hans":"下个计划","fr":"Prochain programme","hi":"अगला शेड्यूल"},
    "지금 집중 시작": {"en":"Start Focus Now","ja":"今すぐ集中開始","zh-Hans":"立即开始专注","fr":"Commencer maintenant","hi":"अभी फ़ोकस शुरू करें"},
    "집중 종료": {"en":"End Focus","ja":"集中を終える","zh-Hans":"结束专注","fr":"Terminer le focus","hi":"फ़ोकस समाप्त करें"},
    "오늘의 명언": {"en":"Today's Quote","ja":"今日の名言","zh-Hans":"今日名言","fr":"Citation du jour","hi":"आज का उद्धरण"},
    "편집": {"en":"Edit","ja":"編集","zh-Hans":"编辑","fr":"Modifier","hi":"संपादित करें"},
    "꺼짐": {"en":"Off","ja":"オフ","zh-Hans":"关闭","fr":"Désactivé","hi":"बंद"},
    "매일": {"en":"Every day","ja":"毎日","zh-Hans":"每天","fr":"Tous les jours","hi":"हर दिन"},
    "평일": {"en":"Weekdays","ja":"平日","zh-Hans":"工作日","fr":"Jours de semaine","hi":"कार्यदिवस"},
    "주말": {"en":"Weekends","ja":"週末","zh-Hans":"周末","fr":"Week-end","hi":"सप्ताहांत"},
    "설정된 허용 앱이 없습니다": {"en":"No allowed apps configured","ja":"許可アプリが設定されていません","zh-Hans":"尚未设置允许的应用","fr":"Aucune app autorisée configurée","hi":"कोई अनुमत ऐप्स कॉन्फ़िगर नहीं"},
    "카테고리는 안의 모든 앱이 허용돼요.": {"en":"All apps in the chosen categories are allowed.","ja":"選択したカテゴリ内のすべてのアプリが許可されます。","zh-Hans":"所选分类中的所有应用都将被允许。","fr":"Toutes les apps des catégories choisies sont autorisées.","hi":"चुनी गई श्रेणियों के सभी ऐप्स अनुमत हैं।"},

    # ============ StreakDots ============
    "최근 7일 흐름": {"en":"Last 7 days","ja":"直近 7 日間","zh-Hans":"最近 7 天","fr":"7 derniers jours","hi":"पिछले 7 दिन"},
    "아직 이번 주 기록이 없어요.": {"en":"No records this week yet.","ja":"今週の記録はまだありません。","zh-Hans":"本周还没有记录。","fr":"Pas encore d'historique cette semaine.","hi":"इस सप्ताह अभी कोई रिकॉर्ड नहीं।"},

    # ============ Focus tree stages ============
    "씨앗": {"en":"Seed","ja":"種","zh-Hans":"种子","fr":"Graine","hi":"बीज"},
    "새싹": {"en":"Sprout","ja":"新芽","zh-Hans":"嫩芽","fr":"Pousse","hi":"अंकुर"},
    "어린 나무": {"en":"Sapling","ja":"若木","zh-Hans":"幼树","fr":"Jeune arbre","hi":"पौधा"},
    "자라는 나무": {"en":"Growing Tree","ja":"成長中の木","zh-Hans":"成长中的树","fr":"Arbre en croissance","hi":"बढ़ता पेड़"},
    "큰 나무": {"en":"Full Tree","ja":"大きな木","zh-Hans":"大树","fr":"Grand arbre","hi":"विशाल पेड़"},
    "열매 맺는 나무": {"en":"Fruiting Tree","ja":"実のなる木","zh-Hans":"结果之树","fr":"Arbre en fruits","hi":"फलदार पेड़"},
    "오늘이 시작이에요": {"en":"Today is a fresh start","ja":"今日が始まりです","zh-Hans":"今天是新的开始","fr":"Aujourd'hui est un nouveau départ","hi":"आज नई शुरुआत है"},

    # ============ Settings ============
    "설정": {"en":"Settings","ja":"設定","zh-Hans":"设置","fr":"Réglages","hi":"सेटिंग्स"},
    "차단": {"en":"Blocking","ja":"ブロック","zh-Hans":"屏蔽","fr":"Blocage","hi":"अवरोधन"},
    "스케줄": {"en":"Schedule","ja":"スケジュール","zh-Hans":"计划","fr":"Programme","hi":"शेड्यूल"},
    "엄격 모드": {"en":"Strict Mode","ja":"厳格モード","zh-Hans":"严格模式","fr":"Mode strict","hi":"सख्त मोड"},
    "엄격 모드 시작": {"en":"Start Strict Mode","ja":"厳格モード開始","zh-Hans":"开启严格模式","fr":"Activer le mode strict","hi":"सख्त मोड शुरू करें"},
    "활성 중": {"en":"Active","ja":"作動中","zh-Hans":"运行中","fr":"Actif","hi":"सक्रिय"},
    "설정한 시간 동안은 어떤 방법으로도 해제할 수 없어요.": {"en":"For the chosen duration, nothing can unlock it.","ja":"設定した時間が過ぎるまではどんな方法でも解除できません。","zh-Hans":"在设定时间内,任何方式都无法解除。","fr":"Rien ne peut le déverrouiller avant la fin du délai.","hi":"निर्धारित अवधि में किसी भी तरह से अनलॉक नहीं किया जा सकता।"},
    "설정한 시간이 끝나기 전에는 어떤 방법으로도 해제할 수 없어요.": {"en":"Cannot be unlocked by any means before the time ends.","ja":"設定時間が終わるまでどんな方法でも解除できません。","zh-Hans":"时间结束前无法以任何方式解除。","fr":"Ne peut être déverrouillé tant que la durée n'est pas écoulée.","hi":"समय समाप्त होने से पहले किसी भी तरह से अनलॉक नहीं किया जा सकता।"},
    "앱 비밀번호 설정": {"en":"App Passcode Setup","ja":"アプリパスコード設定","zh-Hans":"设置应用密码","fr":"Définir le code d'accès","hi":"ऐप पासकोड सेट करें"},
    "설정됨": {"en":"Set","ja":"設定済み","zh-Hans":"已设置","fr":"Défini","hi":"सेट"},
    "미설정": {"en":"Not set","ja":"未設定","zh-Hans":"未设置","fr":"Non défini","hi":"सेट नहीं"},
    "앱 비밀번호는 일반 모드의 하루 첫 해제 때만 쓰여요. 엄격 모드는 시간이 지나기 전에는 어떤 방법으로도 풀 수 없어요.": {"en":"The passcode is used only for the first daily unlock in normal mode. Strict mode cannot be unlocked by any means until the time ends.","ja":"アプリパスコードは通常モードの初日解除時のみ使われます。厳格モードは時間が経過するまでどんな方法でも解除できません。","zh-Hans":"应用密码仅用于普通模式下一天的首次解锁。严格模式在到期前无法通过任何方式解除。","fr":"Le code d'accès n'est utilisé que pour le premier déverrouillage quotidien en mode normal. Le mode strict ne peut être déverrouillé qu'à la fin du délai.","hi":"ऐप पासकोड केवल सामान्य मोड में दिन के पहले अनलॉक के लिए उपयोग होता है। सख्त मोड को समय समाप्त होने से पहले किसी भी तरह से अनलॉक नहीं किया जा सकता।"},
    "닉네임": {"en":"Nickname","ja":"ニックネーム","zh-Hans":"昵称","fr":"Pseudonyme","hi":"उपनाम"},
    "랭킹": {"en":"Ranking","ja":"ランキング","zh-Hans":"排行榜","fr":"Classement","hi":"रैंकिंग"},
    "랭킹에서 다른 사용자에게 보이는 이름이에요. 욕설·성적 단어는 차단돼요.": {"en":"Name shown to other users in the ranking. Profanity and sexual terms are blocked.","ja":"ランキングで他ユーザーに表示される名前です。暴言・性的表現はブロックされます。","zh-Hans":"在排行榜中向其他用户显示的名称。脏话和性相关词汇会被屏蔽。","fr":"Nom affiché aux autres dans le classement. Les insultes et termes sexuels sont bloqués.","hi":"रैंकिंग में अन्य उपयोगकर्ताओं को दिखाया जाने वाला नाम। गालियाँ और यौन शब्द अवरुद्ध हैं।"},
    "버전": {"en":"Version","ja":"バージョン","zh-Hans":"版本","fr":"Version","hi":"संस्करण"},
    "앱 정보": {"en":"About","ja":"アプリ情報","zh-Hans":"关于","fr":"À propos","hi":"ऐप के बारे में"},
    "닫기": {"en":"Close","ja":"閉じる","zh-Hans":"关闭","fr":"Fermer","hi":"बंद करें"},
    "취소": {"en":"Cancel","ja":"キャンセル","zh-Hans":"取消","fr":"Annuler","hi":"रद्द करें"},
    "저장": {"en":"Save","ja":"保存","zh-Hans":"保存","fr":"Enregistrer","hi":"सहेजें"},
    "확인": {"en":"OK","ja":"OK","zh-Hans":"确认","fr":"OK","hi":"ठीक है"},

    # ============ Manual focus dialog ============
    "허용 앱 0개로 집중 시작": {"en":"Start with 0 allowed apps","ja":"許可アプリ 0 で集中を開始","zh-Hans":"在 0 个允许应用下开始","fr":"Démarrer avec 0 app autorisée","hi":"0 अनुमत ऐप्स के साथ शुरू करें"},
    "시스템 앱 외 전부 잠그기": {"en":"Lock all except system apps","ja":"システムアプリ以外すべてロック","zh-Hans":"锁定系统应用以外的全部","fr":"Verrouiller tout sauf les apps système","hi":"सिस्टम ऐप्स को छोड़कर सभी लॉक करें"},
    "전화·메시지·설정은 iOS 가 자동 보호하지만 카메라·지도 등은 보호 보장이 없어요. 허용 앱 카드에서 먼저 필요한 앱을 고를 수도 있어요.": {"en":"iOS auto-protects Phone, Messages, Settings, but apps like Camera and Maps are not guaranteed. You can pick needed apps first in the allowed apps card.","ja":"電話・メッセージ・設定は iOS が自動保護しますが、カメラやマップなどは保護が保証されません。先に許可アプリカードで必要なアプリを選ぶこともできます。","zh-Hans":"iOS 自动保护电话、信息、设置,但相机、地图等无保证。你也可以在允许应用卡片中先选择需要的应用。","fr":"iOS protège automatiquement Téléphone, Messages, Réglages, mais Caméra, Plans ne sont pas garantis. Vous pouvez d'abord choisir des apps dans la carte des apps autorisées.","hi":"iOS स्वतः फ़ोन, संदेश, सेटिंग्स की सुरक्षा करता है, लेकिन कैमरा, मैप्स की गारंटी नहीं। आप अनुमत ऐप्स कार्ड में पहले ज़रूरी ऐप्स चुन सकते हैं।"},
    "엄격 모드 활성화 중": {"en":"Strict mode is active","ja":"厳格モード作動中","zh-Hans":"严格模式运行中","fr":"Mode strict actif","hi":"सख्त मोड सक्रिय"},
    "허용 앱이 0개예요. 집중을 시작하면 시스템 자동 보호 앱(전화·메시지·설정) 외 대부분 앱이 잠깁니다.": {"en":"No allowed apps. Starting focus will lock most apps except the system-protected ones (Phone, Messages, Settings).","ja":"許可アプリが 0 個です。集中を開始するとシステム保護アプリ(電話・メッセージ・設定)以外のほとんどのアプリがロックされます。","zh-Hans":"无允许的应用。开始专注后,除系统自动保护的应用(电话、信息、设置)外,大多数应用将被锁定。","fr":"Aucune app autorisée. Le focus verrouillera la plupart des apps sauf celles protégées par iOS (Téléphone, Messages, Réglages).","hi":"कोई अनुमत ऐप्स नहीं। फ़ोकस शुरू करने पर सिस्टम-संरक्षित ऐप्स (फ़ोन, संदेश, सेटिंग्स) को छोड़कर अधिकांश ऐप्स लॉक हो जाएंगे।"},

    # ============ Accessibility labels ============
    "랭킹 열기": {"en":"Open ranking","ja":"ランキングを開く","zh-Hans":"打开排行榜","fr":"Ouvrir le classement","hi":"रैंकिंग खोलें"},
    "뱃지 모음 열기": {"en":"Open badges","ja":"バッジを開く","zh-Hans":"打开徽章","fr":"Ouvrir les badges","hi":"बैज खोलें"},
    "리포트 열기": {"en":"Open report","ja":"レポートを開く","zh-Hans":"打开报告","fr":"Ouvrir le rapport","hi":"रिपोर्ट खोलें"},
    "설정 열기": {"en":"Open settings","ja":"設定を開く","zh-Hans":"打开设置","fr":"Ouvrir les réglages","hi":"सेटिंग्स खोलें"},
    "내 점수 랭킹에 등록": {"en":"Submit my score","ja":"自分のスコアを登録","zh-Hans":"提交我的分数","fr":"Soumettre mon score","hi":"मेरा स्कोर सबमिट करें"},

    # ============ Toast ============
    "앱 비밀번호를 먼저 설정해주세요. 설정에서 등록할 수 있어요.": {"en":"Set an app passcode first. You can register one in Settings.","ja":"先にアプリパスコードを設定してください。設定から登録できます。","zh-Hans":"请先设置应用密码。可在设置中注册。","fr":"Définissez d'abord un code d'accès. Vous pouvez le faire dans Réglages.","hi":"पहले ऐप पासकोड सेट करें। सेटिंग्स में पंजीकृत कर सकते हैं।"},

    # ============ Leaderboard ============
    "전체 랭킹": {"en":"Global Ranking","ja":"全体ランキング","zh-Hans":"全部排行榜","fr":"Classement global","hi":"वैश्विक रैंकिंग"},
    "일간": {"en":"Daily","ja":"日間","zh-Hans":"每日","fr":"Quotidien","hi":"दैनिक"},
    "주간": {"en":"Weekly","ja":"週間","zh-Hans":"每周","fr":"Hebdo","hi":"साप्ताहिक"},
    "월간": {"en":"Monthly","ja":"月間","zh-Hans":"每月","fr":"Mensuel","hi":"मासिक"},
    "참여자": {"en":"Participants","ja":"参加者","zh-Hans":"参与者","fr":"Participants","hi":"प्रतिभागी"},
    "내 등수": {"en":"My Rank","ja":"自分の順位","zh-Hans":"我的排名","fr":"Mon rang","hi":"मेरी रैंक"},
    "상위": {"en":"Top","ja":"上位","zh-Hans":"前","fr":"Top","hi":"टॉप"},
    "미등록": {"en":"Unregistered","ja":"未登録","zh-Hans":"未注册","fr":"Non inscrit","hi":"अपंजीकृत"},
    "내 순위": {"en":"My Rank","ja":"自分の順位","zh-Hans":"我的排名","fr":"Mon rang","hi":"मेरी रैंक"},
    "나": {"en":"Me","ja":"私","zh-Hans":"我","fr":"Moi","hi":"मैं"},
    "아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요.": {"en":"Not many records yet.\nTap the ↑ button in the top right to submit your score.","ja":"まだ登録された記録が多くありません。\n右上の↑ボタンで自分のスコアを登録してみてください。","zh-Hans":"尚无太多记录。\n点击右上角↑按钮提交你的分数。","fr":"Peu d'enregistrements pour le moment.\nTouchez le bouton ↑ en haut à droite pour envoyer votre score.","hi":"अभी अधिक रिकॉर्ड नहीं हैं।\nऊपर दाईं ओर ↑ बटन से अपना स्कोर दर्ज करें।"},
    "iCloud 에 로그인해주세요. 설정 → Apple ID → iCloud.": {"en":"Please sign in to iCloud. Settings → Apple ID → iCloud.","ja":"iCloud にサインインしてください。設定 → Apple ID → iCloud。","zh-Hans":"请登录 iCloud。设置 → Apple ID → iCloud。","fr":"Connectez-vous à iCloud. Réglages → Apple ID → iCloud.","hi":"कृपया iCloud में साइन इन करें। सेटिंग्स → Apple ID → iCloud।"},
    "iCloud 에 로그인되어 있어야 랭킹에 참여할 수 있어요.": {"en":"You must be signed in to iCloud to join the ranking.","ja":"ランキングに参加するには iCloud にサインインする必要があります。","zh-Hans":"必须登录 iCloud 才能参加排行榜。","fr":"Vous devez être connecté à iCloud pour rejoindre le classement.","hi":"रैंकिंग में शामिल होने के लिए iCloud में साइन इन आवश्यक है।"},
    "1등": {"en":"1st","ja":"1位","zh-Hans":"第 1","fr":"1er","hi":"पहला"},
    "2등": {"en":"2nd","ja":"2位","zh-Hans":"第 2","fr":"2e","hi":"दूसरा"},
    "3등": {"en":"3rd","ja":"3位","zh-Hans":"第 3","fr":"3e","hi":"तीसरा"},

    # ============ Badges ============
    "뱃지": {"en":"Badges","ja":"バッジ","zh-Hans":"徽章","fr":"Badges","hi":"बैज"},
    "획득한 뱃지": {"en":"Earned Badge","ja":"獲得バッジ","zh-Hans":"已获徽章","fr":"Badge obtenu","hi":"प्राप्त बैज"},
    "뱃지 획득": {"en":"Badge Earned","ja":"バッジ獲得","zh-Hans":"获得徽章","fr":"Badge débloqué","hi":"बैज प्राप्त"},
    "아직 잠겨 있어요": {"en":"Still locked","ja":"まだロック中","zh-Hans":"仍然锁定","fr":"Encore verrouillé","hi":"अभी भी लॉक"},
    "순위 뱃지는 참가자 100명 이상인 랭킹에서만 획득할 수 있어요.": {"en":"Ranking badges can only be earned in leaderboards with 100+ participants.","ja":"順位バッジは参加者 100 人以上のランキングでのみ獲得可能です。","zh-Hans":"排名徽章仅在 100 人以上的排行榜中可获得。","fr":"Les badges de rang ne s'obtiennent qu'avec 100+ participants au classement.","hi":"रैंकिंग बैज केवल 100+ प्रतिभागियों वाले लीडरबोर्ड में मिलते हैं।"},

    # ============ Onboarding ============
    "뒤로": {"en":"Back","ja":"戻る","zh-Hans":"返回","fr":"Retour","hi":"वापस"},
    "다음": {"en":"Next","ja":"次へ","zh-Hans":"下一步","fr":"Suivant","hi":"आगे"},
    "건너뛰기": {"en":"Skip","ja":"スキップ","zh-Hans":"跳过","fr":"Passer","hi":"छोड़ें"},
    "시작하기": {"en":"Start","ja":"開始","zh-Hans":"开始","fr":"Commencer","hi":"शुरू करें"},
    "집중 시간대를 골라주세요": {"en":"Choose your focus time","ja":"集中する時間帯を選んでください","zh-Hans":"选择你的专注时段","fr":"Choisissez votre plage de focus","hi":"अपना फ़ोकस समय चुनें"},
    "나중에 언제든 바꿀 수 있어요.": {"en":"You can change this anytime later.","ja":"後でいつでも変更できます。","zh-Hans":"之后随时可以更改。","fr":"Vous pouvez le changer plus tard à tout moment.","hi":"आप इसे बाद में कभी भी बदल सकते हैं।"},
    "허용할 앱을 골라주세요": {"en":"Pick apps to allow","ja":"許可するアプリを選んでください","zh-Hans":"选择要允许的应用","fr":"Choisissez les apps à autoriser","hi":"अनुमत ऐप्स चुनें"},
    "먼저 권한이 필요해요": {"en":"Permission needed first","ja":"まず権限が必要です","zh-Hans":"首先需要权限","fr":"Autorisation requise","hi":"पहले अनुमति आवश्यक"},
    "앱 비밀번호를 정해주세요": {"en":"Set your app passcode","ja":"アプリパスコードを設定してください","zh-Hans":"设置你的应用密码","fr":"Définissez votre code d'accès","hi":"अपना ऐप पासकोड सेट करें"},
    "다시 한 번 입력해주세요": {"en":"Enter it once more","ja":"もう一度入力してください","zh-Hans":"请再输入一次","fr":"Saisissez-le à nouveau","hi":"एक बार और दर्ज करें"},
    "하루 첫 집중 해제 때 확인용으로 써요. iPhone 잠금 암호와는 별개예요.": {"en":"Used to verify the first focus unlock each day. Separate from your iPhone passcode.","ja":"毎日初回の集中解除時の確認に使います。iPhone ロックパスコードとは別です。","zh-Hans":"用于每日首次解除专注时验证。与 iPhone 锁屏密码不同。","fr":"Utilisé pour vérifier le premier déverrouillage du focus chaque jour. Distinct du code iPhone.","hi":"हर दिन पहले फ़ोकस अनलॉक की पुष्टि के लिए उपयोग होता है। iPhone पासकोड से अलग।"},
    "확인을 위해 방금 정한 6자리를 한 번 더 입력해주세요.": {"en":"Re-enter the 6 digits you just chose.","ja":"先ほど設定した 6 桁をもう一度入力してください。","zh-Hans":"请再次输入你刚才设置的 6 位。","fr":"Saisissez à nouveau les 6 chiffres que vous venez de choisir.","hi":"अभी सेट किए गए 6 अंक फिर से दर्ज करें।"},
    "숫자 6자리": {"en":"6 digits","ja":"数字 6 桁","zh-Hans":"6 位数字","fr":"6 chiffres","hi":"6 अंक"},
    "비밀번호가 달라요. 처음부터 다시 입력해주세요.": {"en":"Passcode doesn't match. Start over.","ja":"パスコードが一致しません。最初から入力し直してください。","zh-Hans":"密码不一致。请从头开始输入。","fr":"Le code ne correspond pas. Recommencez.","hi":"पासकोड मेल नहीं खाता। फिर से शुरू करें।"},

    # ============ Focus End Confirm ============
    "정말 종료할까요?": {"en":"Really end the session?","ja":"本当に終了しますか?","zh-Hans":"真的要结束吗?","fr":"Vraiment terminer ?","hi":"वाकई समाप्त करें?"},
    "잠시 숨을 고르면서 한 번 더 생각해봐요.": {"en":"Take a breath and think once more.","ja":"ひと息ついてもう一度考えてみましょう。","zh-Hans":"深呼吸,再想一想。","fr":"Respirez et réfléchissez encore.","hi":"एक सांस लें और फिर से सोचें।"},
    "오늘 첫 해제예요. 잠시 숨을 고르고 다음 단계로 넘어가요.": {"en":"First unlock today. Take a breath, then proceed.","ja":"今日最初の解除です。ひと息ついて次へ進みましょう。","zh-Hans":"今天首次解除。深呼吸后继续。","fr":"Premier déverrouillage du jour. Respirez, puis continuez.","hi":"आज पहला अनलॉक। सांस लें, फिर आगे बढ़ें।"},
    "다음 단계로": {"en":"Next step","ja":"次のステップへ","zh-Hans":"下一步","fr":"Étape suivante","hi":"अगला कदम"},
    "종료할게요": {"en":"End now","ja":"終了する","zh-Hans":"结束","fr":"Terminer","hi":"समाप्त करें"},
    "계속 집중하기": {"en":"Keep focusing","ja":"集中を続ける","zh-Hans":"继续专注","fr":"Continuer le focus","hi":"फ़ोकस जारी रखें"},
    "이 문장을 그대로 써주세요": {"en":"Copy this sentence exactly","ja":"この文をそのまま書いてください","zh-Hans":"请原样抄写这句话","fr":"Recopiez cette phrase exactement","hi":"इस वाक्य को ज्यों का त्यों लिखें"},
    "나는 지금 꼭 집중을 풀어야 한다": {"en":"I really need to break focus right now","ja":"私は今、集中を解かなければならない","zh-Hans":"我现在一定要结束专注","fr":"Je dois vraiment arrêter ma concentration maintenant","hi":"मुझे अभी फ़ोकस ज़रूर तोड़ना है"},
    "여기에 입력": {"en":"Type here","ja":"ここに入力","zh-Hans":"在此输入","fr":"Tapez ici","hi":"यहाँ लिखें"},
    "문장이 달라요. 예시대로 정확히 써야 해요.": {"en":"Sentence doesn't match. Write it exactly as shown.","ja":"文が違います。例の通りに正確に書いてください。","zh-Hans":"句子不一致。请严格按示例书写。","fr":"La phrase ne correspond pas. Recopiez exactement.","hi":"वाक्य मेल नहीं खाता। उदाहरण के अनुसार लिखें।"},

    # ============ Intercept ============
    "잠깐 기다려봐요": {"en":"Wait a moment","ja":"少し待ってみましょう","zh-Hans":"稍等片刻","fr":"Un instant","hi":"एक पल रुकें"},
    "이 앱이 지금 꼭 필요한가요?": {"en":"Do you really need this app right now?","ja":"このアプリは今、本当に必要ですか?","zh-Hans":"现在真的需要这个应用吗?","fr":"Avez-vous vraiment besoin de cette app maintenant ?","hi":"क्या अभी वास्तव में इस ऐप की ज़रूरत है?"},
    "돌아가기": {"en":"Go back","ja":"戻る","zh-Hans":"返回","fr":"Revenir","hi":"वापस जाएँ"},
    "그래도 열기": {"en":"Open anyway","ja":"それでも開く","zh-Hans":"仍然打开","fr":"Ouvrir quand même","hi":"फिर भी खोलें"},
    "엄격 모드에서는 열 수 없어요": {"en":"Cannot open in strict mode","ja":"厳格モードでは開けません","zh-Hans":"严格模式下无法打开","fr":"Impossible en mode strict","hi":"सख्त मोड में नहीं खोला जा सकता"},

    # ============ Nickname Setup ============
    "닉네임 만들기": {"en":"Create nickname","ja":"ニックネームを作る","zh-Hans":"创建昵称","fr":"Créer un pseudo","hi":"उपनाम बनाएँ"},
    "랭킹에서 다른 사용자에게 이렇게 보여요.\n2~20자.": {"en":"This is how others see you in the ranking.\n2–20 characters.","ja":"ランキングで他ユーザーにはこのように表示されます。\n2〜20 文字。","zh-Hans":"其他用户在排行榜中这样看到你。\n2–20 字符。","fr":"Voici comment les autres vous voient dans le classement.\n2 à 20 caractères.","hi":"रैंकिंग में दूसरों को आप ऐसे दिखते हैं।\n2–20 अक्षर।"},
    "예: 집중러": {"en":"e.g. FocusHero","ja":"例: フォーカサー","zh-Hans":"例: 专注者","fr":"ex. FocusHero","hi":"उदा. फ़ोकसहीरो"},
    "닉네임은 2자 이상이어야 해요.": {"en":"Nickname must be at least 2 characters.","ja":"ニックネームは 2 文字以上必要です。","zh-Hans":"昵称至少 2 个字符。","fr":"Le pseudo doit faire au moins 2 caractères.","hi":"उपनाम कम से कम 2 अक्षर होना चाहिए।"},
    "닉네임은 20자 이하로 입력해주세요.": {"en":"Nickname must be 20 characters or fewer.","ja":"ニックネームは 20 文字以下で入力してください。","zh-Hans":"昵称不得超过 20 字符。","fr":"Le pseudo doit faire 20 caractères maximum.","hi":"उपनाम 20 अक्षरों से अधिक नहीं होना चाहिए।"},
    "허용되지 않은 단어가 포함돼 있어요.": {"en":"Contains a disallowed word.","ja":"許可されていない単語が含まれています。","zh-Hans":"包含不允许的词汇。","fr":"Contient un mot interdit.","hi":"अस्वीकृत शब्द शामिल है।"},

    # ============ Passcode ============
    "앱 비밀번호 입력": {"en":"Enter App Passcode","ja":"アプリパスコード入力","zh-Hans":"输入应用密码","fr":"Saisir le code d'accès","hi":"ऐप पासकोड दर्ज करें"},
    "설정한 6자리 비번을 입력하세요.": {"en":"Enter the 6-digit passcode you set.","ja":"設定した 6 桁のパスコードを入力してください。","zh-Hans":"请输入你设置的 6 位密码。","fr":"Saisissez votre code à 6 chiffres.","hi":"आपके द्वारा सेट किया गया 6 अंकों का पासकोड दर्ज करें।"},
    "비밀번호가 달라요. 다시 입력해주세요.": {"en":"Passcode doesn't match. Try again.","ja":"パスコードが一致しません。もう一度入力してください。","zh-Hans":"密码不一致。请重试。","fr":"Le code ne correspond pas. Réessayez.","hi":"पासकोड मेल नहीं खाता। पुनः प्रयास करें।"},

    # ============ Strict Duration Picker ============
    "얼마나 집중할까요?": {"en":"How long to focus?","ja":"どれくらい集中しますか?","zh-Hans":"专注多久?","fr":"Durée du focus ?","hi":"कितनी देर फ़ोकस?"},
    "고른 시간이 지나기 전까지는 비밀번호를 알아도 풀 수 없어요.": {"en":"Even if you know the passcode, you cannot unlock before the chosen time ends.","ja":"選んだ時間が経過するまではパスコードを知っていても解除できません。","zh-Hans":"所选时间结束前,即便知道密码也无法解除。","fr":"Même avec le code, impossible de déverrouiller avant la fin du délai choisi.","hi":"चुना गया समय समाप्त होने से पहले पासकोड जानते हुए भी अनलॉक नहीं कर सकते।"},
    "30분": {"en":"30 min","ja":"30分","zh-Hans":"30 分钟","fr":"30 min","hi":"30 मिनट"},
    "1시간": {"en":"1 hour","ja":"1時間","zh-Hans":"1 小时","fr":"1 heure","hi":"1 घंटा"},
    "2시간": {"en":"2 hours","ja":"2時間","zh-Hans":"2 小时","fr":"2 heures","hi":"2 घंटे"},
    "4시간": {"en":"4 hours","ja":"4時間","zh-Hans":"4 小时","fr":"4 heures","hi":"4 घंटे"},
    "8시간": {"en":"8 hours","ja":"8時間","zh-Hans":"8 小时","fr":"8 heures","hi":"8 घंटे"},

    # ============ Report ============
    "리포트": {"en":"Report","ja":"レポート","zh-Hans":"报告","fr":"Rapport","hi":"रिपोर्ट"},
    "최근 7일 평균": {"en":"7-day average","ja":"直近 7 日平均","zh-Hans":"最近 7 天平均","fr":"Moyenne 7 jours","hi":"7-दिन औसत"},
    "기록된 날": {"en":"Days recorded","ja":"記録日数","zh-Hans":"记录天数","fr":"Jours enregistrés","hi":"दर्ज दिन"},
    "총점": {"en":"Total","ja":"合計","zh-Hans":"总分","fr":"Total","hi":"कुल"},
    "최고 점수": {"en":"Best score","ja":"最高スコア","zh-Hans":"最高分","fr":"Meilleur score","hi":"सर्वश्रेष्ठ स्कोर"},
    "최근 30일": {"en":"Last 30 days","ja":"直近 30 日","zh-Hans":"最近 30 天","fr":"30 derniers jours","hi":"पिछले 30 दिन"},
    "평균": {"en":"Average","ja":"平均","zh-Hans":"平均","fr":"Moyenne","hi":"औसत"},
    "기록 일수": {"en":"Days","ja":"記録日数","zh-Hans":"记录天数","fr":"Jours","hi":"दिन"},
    "남은 목표": {"en":"Remaining","ja":"残り目標","zh-Hans":"剩余目标","fr":"Restant","hi":"शेष लक्ष्य"},
    "완료": {"en":"Done","ja":"完了","zh-Hans":"完成","fr":"Terminé","hi":"पूर्ण"},
    "획득 뱃지": {"en":"Badges earned","ja":"獲得バッジ","zh-Hans":"获得徽章","fr":"Badges obtenus","hi":"प्राप्त बैज"},
    "누적 집중 지킴": {"en":"Total focus saves","ja":"累計集中守り","zh-Hans":"累计专注守护","fr":"Total sauvegardes focus","hi":"कुल फ़ोकस बचत"},

    # ============ Quote Detail ============
    "공유하기": {"en":"Share","ja":"共有","zh-Hans":"分享","fr":"Partager","hi":"साझा करें"},
}

def escape(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

def write_lang(lang_code, key_is_korean=False):
    lproj = BASE / f"{lang_code}.lproj"
    lproj.mkdir(exist_ok=True)
    path = lproj / "Localizable.strings"
    lines = ['/* Auto-generated by docs/gen_strings.py. Edit this file directly if you tweak copy. */', '']
    for ko, vals in T.items():
        key = escape(ko)
        if lang_code == "ko":
            val = escape(ko)
        else:
            val = escape(vals.get(lang_code, ko))
        lines.append(f'"{key}" = "{val}";')
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f"Wrote {path} with {len(T)} strings")

for lang in ["ko", "en", "ja", "zh-Hans", "fr", "hi"]:
    write_lang(lang)

print(f"\nTotal strings per language: {len(T)}")
