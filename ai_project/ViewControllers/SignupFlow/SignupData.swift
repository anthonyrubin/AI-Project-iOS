//.init(title: "Golf", iconName: "figure.golf", passdownTitle: "golfer"),
//.init(title: "Tennis", iconName: "figure.tennis", passdownTitle: "tennis player"),
//.init(title: "Pickleball", iconName: "figure.pickleball", passdownTitle: "pickleball player"),
//.init(title: "Basketball", iconName: "figure.basketball", passdownTitle: "basketball player"),
//.init(title: "Baseball", iconName: "figure.baseball", passdownTitle: "baseball player"),
//.init(title: "Soccer", iconName: "figure.indoor.soccer", passdownTitle: "soccer player"),
//.init(title: "Weightlifting", iconName: "figure.strengthtraining.traditional", passdownTitle: "weightlifter"),
//.init(title: "Running", iconName: "figure.run", passdownTitle: "runner"),
//.init(title: "Track & Field", iconName: "figure.track.and.field", passdownTitle: "track athlete"),
//.init(title: "Football (American)", iconName: "figure.american.football", passdownTitle: "football player"),
//.init(title: "Volleyball",  iconName: "figure.volleyball", passdownTitle: "volleyball player"),
//.init(title: "Hockey", iconName: "figure.hockey", passdownTitle: "hockey player"),
//.init(title: "Softball", iconName: "figure.softball", passdownTitle: "softball player"),
////.init(title: "Lacrosse", iconName: "figure.lacrosse", passdownTitle: "lacrosse player"),
////.init(title: "Cricket", iconName: "figure.cricket", passdownTitle: "cricketer"),
//.init(title: "Badminton", iconName: "figure.badminton", passdownTitle: "badminton player"),
//.init(title: "Table Tennis", iconName: "figure.table.tennis", passdownTitle: "table tennis player"),
//.init(title: "Rowing", iconName: "figure.indoor.rowing", passdownTitle: "rower"),
//.init(title: "Striking (Boxing / Kickboxing / TKD)", iconName: "figure.boxing", passdownTitle: "fighter")

struct SportData {
    let sport: Sport
    let icon: String
    let sentenceTitle: String
    let imagePrefix: String
}

enum Sport: String, CaseIterable {
    case golf, tennis, pickleball,
         basketball, baseball, soccer,
         weightlifting, running, football,
         volleyball, hockey, softball,
         badminton, rowing, striking
    case trackAndField = "track & field"
    case tableTennis = "table tennis"
}

extension Sport {
    func data() -> SportData {
        switch self {
        case .golf: return SportData(sport: self, icon: "figure.golf", sentenceTitle: "golfer", imagePrefix: "golf")
        case .tennis: return SportData(sport: self, icon: "figure.tennis", sentenceTitle: "tennis player", imagePrefix: "tennis")
        case .pickleball: return SportData(sport: self, icon: "figure.pickleball", sentenceTitle: "pickleball player", imagePrefix: "pickleball")
        case .basketball: return SportData(sport: self, icon: "figure.basketball", sentenceTitle: "basketball player", imagePrefix: "basketball")
        case .baseball: return SportData(sport: self, icon: "figure.baseball", sentenceTitle: "baseball player", imagePrefix: "baseball")
        case .soccer: return SportData(sport: self, icon: "figure.indoor.soccer", sentenceTitle: "soccer player", imagePrefix: "soccer")
        case .weightlifting: return SportData(sport: self, icon: "figure.strengthtraining.traditional", sentenceTitle: "weightlifter", imagePrefix: "weightlifting")
        case .running: return SportData(sport: self, icon: "figure.run", sentenceTitle: "runner", imagePrefix: "running")
        case .football: return SportData(sport: self, icon: "figure.american.football", sentenceTitle: "football player", imagePrefix: "football")
        case .volleyball: return SportData(sport: self, icon: "figure.volleyball", sentenceTitle: "volleyball player", imagePrefix: "volleyball")
        case .hockey: return SportData(sport: self, icon: "figure.hockey", sentenceTitle: "hockey player", imagePrefix: "hockey")
        case .softball: return SportData(sport: self, icon: "figure.softball", sentenceTitle: "softball player", imagePrefix: "softball")
        case .badminton: return SportData(sport: self, icon: "figure.badminton", sentenceTitle: "badminton player", imagePrefix: "badminton")
        case .rowing: return SportData(sport: self, icon: "figure.indoor.rowing", sentenceTitle: "rower", imagePrefix: "rowing")
        case .striking: return SportData(sport: self, icon: "figure.boxing", sentenceTitle: "fighter", imagePrefix: "striking")
        case .tableTennis: return SportData(sport: self, icon: "figure.table.tennis", sentenceTitle: "table tennis player", imagePrefix: "table_tennis")
        case .trackAndField: return SportData(sport: self, icon: "figure.track.and.field", sentenceTitle: "track athlete", imagePrefix: "track_and_field")
        }
    }
    
    func analysisPlaceholder() -> String {
        switch self {
        case .golf:
            return "Analyze my driver swing: club path, face angle, contact, weight shift."
        case .tennis:
            return "Break down my serve: toss, racquet drop, pronation, leg drive."
        case .pickleball:
            return "Assess my third-shot drop and dinks: paddle angle, contact point, footwork."
        case .basketball:
            return "Critique my jump shot: release, elbow alignment, lift, balance."
        case .baseball:
            return "Analyze my batting swing: timing, hip rotation, bat path."
        case .soccer:
            return "Assess my shooting form: plant foot, hip rotation, contact point."
        case .weightlifting:
            return "Check my back squat: depth, knee tracking, bracing, bar path."
        case .running:
            return "Evaluate my distance form: cadence, foot strike, hip posture, arm swing."
        case .football:
            return "Analyze my acceleration and cutting on this route: stance, first step, change of direction."
        case .volleyball:
            return "Break down my spike: approach steps, jump timing, arm swing, contact."
        case .hockey:
            return "Assess my skating stride: knee bend, edge control, extension, recovery."
        case .softball:
            return "Analyze my swing: timing, hip rotation, bat path."
        case .badminton:
            return "Evaluate my overhead smash: grip, footwork, contact height, recovery."
        case .rowing:
            return "Break down my stroke: catch, drive, finish, sequencing."
        case .striking:
            return "Critique my cross and hook: guard, hip rotation, weight transfer, recoil."
        case .tableTennis:
            return "Assess my forehand loop: timing, footwork, contact point, spin."
        case .trackAndField:
            return "Analyze my sprint mechanics: block setup, drive, transition, upright posture."
        }
    }
}

