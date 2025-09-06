struct LiftData {
    let lift: Lift
    let icon: String
    let sentenceTitle: String   // e.g., “CoachAI makes you a better \(sentenceTitle)”
    let imagePrefix: String     // asset key prefix, e.g., “clean_and_jerk”
}

enum Lift: String, CaseIterable {
    // Powerlifting / gym staples
    case deadlift
    case backSquat = "back squat"
    case benchPress = "bench press"
    case overheadPress = "overhead press"
    case barbellRow = "barbell row"
    case romanianDeadlift = "romanian deadlift"
    case hipThrust = "hip thrust"
    case pullUp = "pull up"
    case dip
    case frontSquat = "front squat"

    // Olympic lifts & close variants
    case cleanAndJerk = "clean and jerk"
    case snatch
    case powerClean = "power clean"
    case powerSnatch = "power snatch"
    case hangPowerClean = "hang power clean"
    case hangPowerSnatch = "hang power snatch"
    case pushPress = "push press"
    case splitJerk = "split jerk"
}

extension Lift {
    func data() -> LiftData {
        switch self {
        // MARK: - Gym staples
        case .deadlift:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "deadlifter", imagePrefix: "deadlift")

        case .backSquat:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "squatter", imagePrefix: "back_squat")

        case .benchPress:
            return LiftData(lift: self, icon: "dumbbell",
                            sentenceTitle: "bench presser", imagePrefix: "bench_press")

        case .overheadPress:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "overhead presser", imagePrefix: "overhead_press")

        case .barbellRow:
            return LiftData(lift: self, icon: "dumbbell",
                            sentenceTitle: "barbell rower", imagePrefix: "barbell_row")

        case .romanianDeadlift:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "RDL lifter", imagePrefix: "rdl")

        case .hipThrust:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "hip thruster", imagePrefix: "hip_thrust")

        case .pullUp:
            return LiftData(lift: self, icon: "figure.pullup", // fallback to "figure.strengthtraining.traditional" if needed
                            sentenceTitle: "pull-up athlete", imagePrefix: "pull_up")

        case .dip:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "dip athlete", imagePrefix: "dip")

        case .frontSquat:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "front squatter", imagePrefix: "front_squat")

        // MARK: - Olympic lifts
        case .cleanAndJerk:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "Olympic lifter", imagePrefix: "clean_and_jerk")

        case .snatch:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "Olympic lifter", imagePrefix: "snatch")

        case .powerClean:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "power cleaner", imagePrefix: "power_clean")

        case .powerSnatch:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "power snatcher", imagePrefix: "power_snatch")

        case .hangPowerClean:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "hang power cleaner", imagePrefix: "hang_power_clean")

        case .hangPowerSnatch:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "hang power snatcher", imagePrefix: "hang_power_snatch")

        case .pushPress:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "push presser", imagePrefix: "push_press")

        case .splitJerk:
            return LiftData(lift: self, icon: "figure.strengthtraining.traditional",
                            sentenceTitle: "jerker", imagePrefix: "split_jerk")
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
        case .hipThrust:
            return "Check my hip thrust: shin vertical at top, full hip extension, posterior pelvic tilt, no lumbar over-extension."
        case .pullUp:
            return "Check my pull-up: full range, scap depression first, minimal leg swing, chin clear at top."
        case .dip:
            return "Check my dip: shoulder depth (below elbows), forearm vertical, torso angle, scapular position."
        case .frontSquat:
            return "Check my front squat: upright torso, full depth, knees tracking, elbows high in the rack, bracing."

        // MARK: - Olympic lifts
        case .cleanAndJerk:
            return "Check my clean & jerk: bar path close, powerful extension, fast elbows/rack, solid dip/drive, stable overhead lockout and footwork."
        case .snatch:
            return "Check my snatch: balanced start, vertical bar path, full extension, fast turnover, stable overhead in the bottom."
        case .powerClean:
            return "Check my power clean: bar close, extension timing, aggressive pull under, rack height without raiding the hips."
        case .powerSnatch:
            return "Check my power snatch: bar close, extension timing, punch under to solid overhead catch above parallel."
        case .hangPowerClean:
            return "Check my hang power clean: controlled hinge to hang, no early arm pull, vertical drive, quick rack."
        case .hangPowerSnatch:
            return "Check my hang power snatch: consistent hang position, vertical drive, fast turnover, stable catch above parallel."
        case .pushPress:
            return "Check my push press: vertical dip (knees forward, heels down), dip depth consistency, bar path stacked overhead."
        case .splitJerk:
            return "Check my split jerk: balanced dip/drive, aggressive punch under, front/back foot placement, stacked lockout, stable recovery."
        }
    }
}
