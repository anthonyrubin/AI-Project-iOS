struct LiftData {
    let lift: Lift
    let icon: String
    let imagePrefix: String
}

enum Lift: String, CaseIterable {
    // Powerlifting / gym staples
    case deadlift
    case backSquat = "back squat"
    case benchPress = "bench press"
    case overheadPress = "overhead press"
    case barbellRow = "barbell row"
    case romanianDeadlift = "romanian deadlift"
    case pullUp = "pull up"
    case pushUp = "push up"
    case dip
    case tBarRow = "t-bar row"

    // Olympic lifts & close variants
    case cleanAndJerk = "clean and jerk"
    case snatch
    case powerClean = "power clean"
}

extension Lift {
    func data() -> LiftData {
        switch self {
        // MARK: - Gym staples
        case .deadlift:
            return LiftData(
                lift: self,
                icon: "deadlift_figure",
                imagePrefix: "deadlift"
            )

        case .backSquat:
            return LiftData(
                lift: self,
                icon: "back_squat_figure",
                imagePrefix: "back_squat"
            )

        case .benchPress:
            return LiftData(
                lift: self,
                icon: "bench_press_figure",
                imagePrefix: "bench_press"
            )

        case .overheadPress:
            return LiftData(
                lift: self,
                icon: "overhead_press_figure",
                imagePrefix: "overhead_press"
            )

        case .barbellRow:
            return LiftData(
                lift: self,
                icon: "barbell_row_figure",
                imagePrefix: "barbell_row"
            )

        case .romanianDeadlift:
            return LiftData(
                lift: self,
                icon: "romanian_deadlift_figure",
                imagePrefix: "romanian_deadlift"
            )

        case .pullUp:
            return LiftData(
                lift: self,
                icon: "pull_up_figure",
                imagePrefix: "pull_up"
            )
        case .pushUp:
            return LiftData(
                lift: self,
                icon: "push_up_figure",
                imagePrefix: "push_up"
            )

        case .dip:
            return LiftData(
                lift: self,
                icon: "dip_figure",
                imagePrefix: "dip"
            )

        // MARK: - Olympic lifts
        case .cleanAndJerk:
            return LiftData(
                lift: self,
                icon: "clean_and_jerk_figure",
                imagePrefix: "clean_and_jerk"
            )

        case .snatch:
            return LiftData(
                lift: self,
                icon: "snatch_figure",
                imagePrefix: "snatch"
            )

        case .powerClean:
            return LiftData(
                lift: self,
                icon: "power_clean_figure",
                imagePrefix: "power_clean"
            )
        case .tBarRow:
            return LiftData(
                lift: self,
                icon: "t_bar_row_figure",
                imagePrefix: "t_bar_row"
            )
        }
    }

    func analysisPlaceholder() -> String {
        switch self {
        // MARK: - Gym staples
        case .deadlift:
            return "Check my deadlift: bar over mid-foot, slack pull, hip/shoulder timing, lumbar neutrality, lockout."
        case .backSquat:
            return "Check my back squat: depth, knee tracking, bracing, bar path, hip drive."
        case .benchPress:
            return "Check my bench press: touch point, elbow flare, bar path (J-curve), scap retraction, leg drive."
        case .overheadPress:
            return "Check my overhead press: bar path close to face, rib flare control, vertical forearms, lockout."
        case .barbellRow:
            return "Check my barbell row: torso angle, bar path to lower ribcage, scap retraction, momentum control."
        case .romanianDeadlift:
            return "Check my RDL: hip hinge, minimal knee travel, bar proximity, neutral lumbar, hamstring tension."
        case .pullUp:
            return "Check my pull-up: full range, scap depression first, minimal leg swing, chin clear at top."
        case .dip:
            return "Check my dip: shoulder depth (below elbows), forearm vertical, torso angle, scapular position."
        case .tBarRow:
            return "Check my T-bar row: chest angle, neutral spine, full range pull, scap retraction, avoid jerking the weight."

        // MARK: - Olympic lifts
        case .cleanAndJerk:
            return "Check my clean & jerk: bar path close, powerful extension, fast elbows/rack, solid dip/drive, stable overhead lockout and footwork."
        case .snatch:
            return "Check my snatch: balanced start, vertical bar path, full extension, fast turnover, stable overhead in the bottom."
        case .powerClean:
            return "Check my power clean: bar close, extension timing, aggressive pull under, rack height without raiding the hips."
        case .pushUp:
            return "Check my push-up: full range, elbow angle, shoulder retraction, wrist alignment."
        }
    }
}
