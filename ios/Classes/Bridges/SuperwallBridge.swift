import Flutter
import SuperwallKit

public class SuperwallBridge: BridgeInstance {
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "setDelegate":
        guard let delegateProxyBridge: SuperwallDelegate = call.bridgeInstance(for: "delegateProxyBridgeId") else {
          result(call.badArgs)
          return
        }

        Superwall.shared.delegate = delegateProxyBridge

        result(nil)

      case "getLogLevel":
        // Implement logic to get log level
        result(Superwall.shared.logLevel.rawValue)

      case "setLogLevel":
        // Implement logic to set log level
        if let args = call.arguments as? [String: Any], let level = args["logLevel"] as? Int, let logLevel = LogLevel(rawValue: level) {
          Superwall.shared.logLevel = logLevel
        }
        result(nil)

      case "getUserAttributes":
        // Implement logic to get user attributes
        result(Superwall.shared.userAttributes)

      case "setUserAttributes":
        guard let userAttributes: [String: Any?] = call.argument(for: "userAttributes") else {
          result(call.badArgs)
          return
        }

        Superwall.shared.setUserAttributes(userAttributes)

        result(nil)

      case "getUserId":
        // Implement logic to get the current user's id
        result(Superwall.shared.userId)

      case "getIsLoggedIn":
        // Implement logic to check if the user is logged in to Superwall
        result(Superwall.shared.isLoggedIn)

      case "getPresentedViewController":
        // Implement logic to get the presented paywall view controller
        // TODO: Since UIViewController cannot be returned directly to Dart, handle appropriately
        if let viewController = Superwall.shared.presentedViewController {
          result(viewController.description)
        } else {
          result(nil)
        }

      case "getLatestPaywallInfo":
        // Implement logic to get the latest PaywallInfo object
        if let paywallInfo = Superwall.shared.latestPaywallInfo {
          // TODO: Convert PaywallInfo to a format suitable for passing over method channels
          result(nil)
        } else {
          result(nil)
        }

      case "getSubscriptionStatusBridgeId":
        // Implement logic to get the subscription status of the user
        let subscriptionStatusBridgeId = Superwall.shared.subscriptionStatus.createBridgeId()
        result(subscriptionStatusBridgeId)

      case "setSubscriptionStatus":
        // Implement logic to set the subscription status of the user
        guard let subscriptionStatusBridge: SubscriptionStatusBridge = call.bridgeInstance(for: "subscriptionStatusBridgeId") else {
          result(call.badArgs)
          return
        }

        Superwall.shared.subscriptionStatus = subscriptionStatusBridge.status
        result(nil)

      case "getIsConfigured":
        // Implement logic to check if Superwall has finished configuring
        result(Superwall.shared.isConfigured)

      case "setIsConfigured":
        // Implement logic to set the configured state of Superwall
        if let args = call.arguments as? [String: Any], let configured = args["configured"] as? Bool {
          Superwall.shared.isConfigured = configured
        }
        result(nil)

      case "getIsPaywallPresented":
        // Implement logic to check if a paywall is currently being presented
        result(Superwall.shared.isPaywallPresented)

      case "preloadAllPaywalls":
        // Implement logic to preload all paywalls
        Superwall.shared.preloadAllPaywalls()
        result(nil)

      case "preloadPaywallsForEvents":
        // Implement logic to preload paywalls for specific event names
        if let args = call.arguments as? [String: Any], let eventNames = args["eventNames"] as? [String] {
          Superwall.shared.preloadPaywalls(forEvents: Set(eventNames))
        }
        result(nil)

      case "handleDeepLink":
        // Implement logic to handle deep links for paywall previews
        if let args = call.arguments as? [String: Any], let urlString = args["url"] as? String, let url = URL(string: urlString) {
          let handled = Superwall.shared.handleDeepLink(url)
          result(handled)
        } else {
          result(FlutterError(code: "INVALID_URL", message: "Invalid URL provided", details: nil))
        }

      case "togglePaywallSpinner":
        // Implement logic to toggle the paywall loading spinner
        if let args = call.arguments as? [String: Any], let isHidden = args["isHidden"] as? Bool {
          Superwall.shared.togglePaywallSpinner(isHidden: isHidden)
        }
        result(nil)

      case "reset":
        // Implement logic to reset the user ID, on-device paywall assignments, and stored data
        Superwall.shared.reset()
        result(nil)

      case "configure":
        // Implement logic to configure the Superwall instance
        guard let apiKey: String = call.argument(for: "apiKey") else {
          result(call.badArgs)
          return
        }

        let purchaseControllerProxyBridge: PurchaseControllerProxyBridge? = call.bridgeInstance(for: "purchaseControllerProxyBridgeId")

        // TODO
        let options: SuperwallOptions? = call.argument(for: "options")

        Superwall.configure(apiKey: apiKey, purchaseController: purchaseControllerProxyBridge, options: options)

        // Returning nil instead of the result from configure because we want to use the Dart
        // instance of Superwall, not a native variant
        result(nil)

      case "dismiss":
        Task {
          await Superwall.shared.dismiss()
          result(nil)
        }

      case "registerEvent":
        guard let event: String = call.argument(for: "event") else {
          result(call.badArgs)
          return
        }

        let params: [String: Any]? = call.argument(for: "params")

        let handler: PaywallPresentationHandler? = {
          guard let handlerProxyBridge: PaywallPresentationHandlerProxyBridge = call.bridgeInstance(for: "handlerProxyBridgeId") else {
            return nil
          }

          return handlerProxyBridge.handler
        }()

        Superwall.shared.register(event: event, params: params, handler: handler) {
          if let featureBlockProxyBridge: CompletionBlockProxyBridge = call.bridgeInstance(for: "featureBlockProxyBridgeId") {
            featureBlockProxyBridge.callCompletionBlock()
          }
        }

        result(nil)

      case "identify":
        guard let userId: String = call.argument(for: "userId") else {
          result(call.badArgs)
          return
        }

        let options: IdentityOptions? = {
          guard let restorePaywallAssignments: Bool = call.argument(for: "restorePaywallAssignments") else {
            return nil
          }

          return IdentityOptions(restorePaywallAssignments: restorePaywallAssignments)
        }()

        Superwall.shared.identify(userId: userId, options: options)

        result(nil)

      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
