
struct AttachPayload: Codable {
    let productId: String
    let jws: String
    let appAccountToken: String?
    
    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case jws
        case appAccountToken = "app_account_token"
    }
}

// MARK: - Response Models

struct AttachSubscriptionResponse: Codable {
    let success: Bool
    let message: String
    let membership: MembershipDetails?
}

struct MembershipStatusResponse: Codable {
    let isMember: Bool
    let membership: MembershipInfo?
    let monthlyUsage: MonthlyUsageInfo
    
    enum CodingKeys: String, CodingKey {
        case isMember = "is_member"
        case membership
        case monthlyUsage = "monthly_usage"
    }
}

struct MonthlyUsageInfo: Codable {
    let minutesUsed: Double
    let minutesAllowed: Double
    let minutesRemaining: Double
    
    enum CodingKeys: String, CodingKey {
        case minutesUsed = "minutes_used"
        case minutesAllowed = "minutes_allowed"
        case minutesRemaining = "minutes_remaining"
    }
}

struct MembershipInfo: Codable {
    let status: String?
    let daysRemaining: Int
    let subscriptionEndDate: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case daysRemaining = "days_remaining"
        case subscriptionEndDate = "subscription_end_date"
    }
}

struct RestorePurchaseResponse: Codable {
    let success: Bool
    let message: String
    let membership: MembershipDetails?
}

struct MembershipDetails: Codable {
    let status: String
    let daysRemaining: Int
    let monthlyAllowance: Double
    let minutesRemaining: Double
    
    enum CodingKeys: String, CodingKey {
        case status
        case daysRemaining = "days_remaining"
        case monthlyAllowance = "monthly_allowance"
        case minutesRemaining = "minutes_remaining"
    }
}

struct AnalysisAllowanceResponse: Codable {
    let canAnalyze: Bool
    let reason: String?
    let upgradeRequired: Bool?
    let minutesRemaining: Double?
    let resetDate: String?
    
    enum CodingKeys: String, CodingKey {
        case canAnalyze = "can_analyze"
        case reason
        case upgradeRequired = "upgrade_required"
        case minutesRemaining = "minutes_remaining"
        case resetDate = "reset_date"
    }
}
