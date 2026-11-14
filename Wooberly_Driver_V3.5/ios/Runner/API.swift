//  This file was automatically generated and should not be edited.

import Apollo

public final class UpdateDriverLocationMutation: GraphQLMutation {
  public let operationDefinition =
    "mutation updateDriverLocation($lat: Float!, $lng: Float!) {\n  updateDriverLocation(lat: $lat, lng: $lng) {\n    __typename\n    status\n    errorMessage\n  }\n}"

  public var lat: Double
  public var lng: Double

  public init(lat: Double, lng: Double) {
    self.lat = lat
    self.lng = lng
  }

  public var variables: GraphQLMap? {
    return ["lat": lat, "lng": lng]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateDriverLocation", arguments: ["lat": GraphQLVariable("lat"), "lng": GraphQLVariable("lng")], type: .object(UpdateDriverLocation.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(updateDriverLocation: UpdateDriverLocation? = nil) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "updateDriverLocation": updateDriverLocation.flatMap { (value: UpdateDriverLocation) -> ResultMap in value.resultMap }])
    }

    public var updateDriverLocation: UpdateDriverLocation? {
      get {
        return (resultMap["updateDriverLocation"] as? ResultMap).flatMap { UpdateDriverLocation(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "updateDriverLocation")
      }
    }

    public struct UpdateDriverLocation: GraphQLSelectionSet {
      public static let possibleTypes = ["UserAccount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("status", type: .scalar(Int.self)),
        GraphQLField("errorMessage", type: .scalar(String.self)),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(status: Int? = nil, errorMessage: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "UserAccount", "status": status, "errorMessage": errorMessage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var status: Int? {
        get {
          return resultMap["status"] as? Int
        }
        set {
          resultMap.updateValue(newValue, forKey: "status")
        }
      }

      public var errorMessage: String? {
        get {
          return resultMap["errorMessage"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "errorMessage")
        }
      }
    }
  }
}

public final class SendDriverLocationQuery: GraphQLQuery {
  public let operationDefinition =
    "query sendDriverLocation($lat: Float!, $lng: Float!, $riderId: String, $deviceId: String, $rotation: Float, $bookingId: Int) {\n  sendDriverLocation(lat: $lat, lng: $lng, riderId: $riderId, deviceId: $deviceId, rotation: $rotation, bookingId: $bookingId) {\n    __typename\n    status\n    errorMessage\n    isTripCreated\n  }\n}"

  public var lat: Double
  public var lng: Double
  public var riderId: String?
  public var deviceId: String?
  public var rotation: Double?
  public var bookingId: Int?

  public init(lat: Double, lng: Double, riderId: String? = nil, deviceId: String? = nil, rotation: Double? = nil, bookingId: Int? = nil) {
    self.lat = lat
    self.lng = lng
    self.riderId = riderId
    self.deviceId = deviceId
    self.rotation = rotation
    self.bookingId = bookingId
  }

  public var variables: GraphQLMap? {
    return ["lat": lat, "lng": lng, "riderId": riderId, "deviceId": deviceId, "rotation": rotation, "bookingId": bookingId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("sendDriverLocation", arguments: ["lat": GraphQLVariable("lat"), "lng": GraphQLVariable("lng"), "riderId": GraphQLVariable("riderId"), "deviceId": GraphQLVariable("deviceId"), "rotation": GraphQLVariable("rotation"), "bookingId": GraphQLVariable("bookingId")], type: .object(SendDriverLocation.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(sendDriverLocation: SendDriverLocation? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "sendDriverLocation": sendDriverLocation.flatMap { (value: SendDriverLocation) -> ResultMap in value.resultMap }])
    }

    public var sendDriverLocation: SendDriverLocation? {
      get {
        return (resultMap["sendDriverLocation"] as? ResultMap).flatMap { SendDriverLocation(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "sendDriverLocation")
      }
    }

    public struct SendDriverLocation: GraphQLSelectionSet {
      public static let possibleTypes = ["UserAccount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("status", type: .scalar(Int.self)),
        GraphQLField("errorMessage", type: .scalar(String.self)),
        GraphQLField("isTripCreated", type: .scalar(Bool.self)),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(status: Int? = nil, errorMessage: String? = nil, isTripCreated: Bool? = nil) {
        self.init(unsafeResultMap: ["__typename": "UserAccount", "status": status, "errorMessage": errorMessage, "isTripCreated": isTripCreated])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var status: Int? {
        get {
          return resultMap["status"] as? Int
        }
        set {
          resultMap.updateValue(newValue, forKey: "status")
        }
      }

      public var errorMessage: String? {
        get {
          return resultMap["errorMessage"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "errorMessage")
        }
      }

      public var isTripCreated: Bool? {
        get {
          return resultMap["isTripCreated"] as? Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "isTripCreated")
        }
      }
    }
  }
}

public final class DeclineBookingQuery: GraphQLQuery {
  public let operationDefinition =
    "query declineBooking($requestStatus: String!, $data: String) {\n  declineBooking(requestStatus: $requestStatus, data: $data) {\n    __typename\n    status\n    errorMessage\n    isTryAgain\n  }\n}"

  public var requestStatus: String
  public var data: String?

  public init(requestStatus: String, data: String? = nil) {
    self.requestStatus = requestStatus
    self.data = data
  }

  public var variables: GraphQLMap? {
    return ["requestStatus": requestStatus, "data": data]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("declineBooking", arguments: ["requestStatus": GraphQLVariable("requestStatus"), "data": GraphQLVariable("data")], type: .object(DeclineBooking.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(declineBooking: DeclineBooking? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "declineBooking": declineBooking.flatMap { (value: DeclineBooking) -> ResultMap in value.resultMap }])
    }

    public var declineBooking: DeclineBooking? {
      get {
        return (resultMap["declineBooking"] as? ResultMap).flatMap { DeclineBooking(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "declineBooking")
      }
    }

    public struct DeclineBooking: GraphQLSelectionSet {
      public static let possibleTypes = ["BookingRequestType"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("status", type: .scalar(Int.self)),
        GraphQLField("errorMessage", type: .scalar(String.self)),
        GraphQLField("isTryAgain", type: .scalar(Bool.self)),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(status: Int? = nil, errorMessage: String? = nil, isTryAgain: Bool? = nil) {
        self.init(unsafeResultMap: ["__typename": "BookingRequestType", "status": status, "errorMessage": errorMessage, "isTryAgain": isTryAgain])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var status: Int? {
        get {
          return resultMap["status"] as? Int
        }
        set {
          resultMap.updateValue(newValue, forKey: "status")
        }
      }

      public var errorMessage: String? {
        get {
          return resultMap["errorMessage"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "errorMessage")
        }
      }

      public var isTryAgain: Bool? {
        get {
          return resultMap["isTryAgain"] as? Bool
        }
        set {
          resultMap.updateValue(newValue, forKey: "isTryAgain")
        }
      }
    }
  }
}

public final class GetTripStatusQuery: GraphQLQuery {
  public let operationDefinition =
    "query getTripStatus {\n  GetTripStatus {\n    __typename\n    result {\n      __typename\n      id\n      riderId\n      tripStatus\n      updatedAt\n    }\n    status\n    errorMessage\n  }\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("GetTripStatus", type: .object(GetTripStatus.selections)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(getTripStatus: GetTripStatus? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "GetTripStatus": getTripStatus.flatMap { (value: GetTripStatus) -> ResultMap in value.resultMap }])
    }

    public var getTripStatus: GetTripStatus? {
      get {
        return (resultMap["GetTripStatus"] as? ResultMap).flatMap { GetTripStatus(unsafeResultMap: $0) }
      }
      set {
        resultMap.updateValue(newValue?.resultMap, forKey: "GetTripStatus")
      }
    }

    public struct GetTripStatus: GraphQLSelectionSet {
      public static let possibleTypes = ["GetTripStatus"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("result", type: .object(Result.selections)),
        GraphQLField("status", type: .scalar(Int.self)),
        GraphQLField("errorMessage", type: .scalar(String.self)),
      ]

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(result: Result? = nil, status: Int? = nil, errorMessage: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "GetTripStatus", "result": result.flatMap { (value: Result) -> ResultMap in value.resultMap }, "status": status, "errorMessage": errorMessage])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var result: Result? {
        get {
          return (resultMap["result"] as? ResultMap).flatMap { Result(unsafeResultMap: $0) }
        }
        set {
          resultMap.updateValue(newValue?.resultMap, forKey: "result")
        }
      }

      public var status: Int? {
        get {
          return resultMap["status"] as? Int
        }
        set {
          resultMap.updateValue(newValue, forKey: "status")
        }
      }

      public var errorMessage: String? {
        get {
          return resultMap["errorMessage"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "errorMessage")
        }
      }

      public struct Result: GraphQLSelectionSet {
        public static let possibleTypes = ["BookingType"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .scalar(Int.self)),
          GraphQLField("riderId", type: .scalar(String.self)),
          GraphQLField("tripStatus", type: .scalar(String.self)),
          GraphQLField("updatedAt", type: .scalar(String.self)),
        ]

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: Int? = nil, riderId: String? = nil, tripStatus: String? = nil, updatedAt: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "BookingType", "id": id, "riderId": riderId, "tripStatus": tripStatus, "updatedAt": updatedAt])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: Int? {
          get {
            return resultMap["id"] as? Int
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var riderId: String? {
          get {
            return resultMap["riderId"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "riderId")
          }
        }

        public var tripStatus: String? {
          get {
            return resultMap["tripStatus"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "tripStatus")
          }
        }

        public var updatedAt: String? {
          get {
            return resultMap["updatedAt"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "updatedAt")
          }
        }
      }
    }
  }
}