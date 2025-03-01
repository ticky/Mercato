import Foundation
import StoreKit

@available(watchOS 8.0, *)
public typealias TransactionUpdate = ((Transaction) async -> ())

@available(watchOS 8.0, *)
public class Mercato {
	
	private var purchaseController = PurchaseController()
	private var productService = ProductService()
	
	private var updateListenerTask: Task<(), Never>? = nil
	
    public init()
	{
		
    }
		
	func listenForTransactions(finishAutomatically: Bool = true, updateBlock: TransactionUpdate?)
	{
		let task = Task.detached
		{
			for await result in Transaction.updates
			{
				do {
					let transaction = try checkVerified(result)
					
					if finishAutomatically
					{
						await transaction.finish()
					}
					
					await updateBlock?(transaction)
				} catch {
					print("Transaction failed verification")
				}
			}
		}
		
		self.updateListenerTask = task
	}
	
	//TODO: throw an error if productId are invalid
	public func retrieveProducts(productIds: Set<String>) async throws -> [Product]
	{
		try await productService.retrieveProducts(productIds: productIds)
	}
	
	@discardableResult
	public func purchase(product: Product, quantity: Int = 1, finishAutomatically: Bool = true, appAccountToken: UUID? = nil, simulatesAskToBuyInSandbox: Bool = false) async throws -> Purchase
	{
		try await purchaseController.makePurchase(product: product, quantity: quantity, finishAutomatically: finishAutomatically, appAccountToken: appAccountToken, simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox)
	}
	
	deinit {
		updateListenerTask?.cancel()
	}
}

@available(watchOS 8.0, *)
extension Mercato
{
	fileprivate static let shared: Mercato = .init()
	
	public static func listenForTransactions(finishAutomatically: Bool = true, updateBlock: TransactionUpdate?)
	{
		shared.listenForTransactions(finishAutomatically: finishAutomatically, updateBlock: updateBlock)
	}
	
	public static func retrieveProducts(productIds: Set<String>) async throws -> [Product]
	{
		try await shared.retrieveProducts(productIds: productIds)
	}
	
	@discardableResult
	public static func purchase(product: Product,
								quantity: Int = 1,
								finishAutomatically: Bool = true,
								appAccountToken: UUID? = nil,
								simulatesAskToBuyInSandbox: Bool = false) async throws -> Purchase
	{
		try await shared.purchase(product: product,
								  quantity: quantity,
								  finishAutomatically: finishAutomatically,
								  appAccountToken: appAccountToken,
								  simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox)
	}
	
	public static func restorePurchases() async throws
	{
		try await AppStore.sync()
	}
	
	public static func activeSubscriptions(onlyRenewable: Bool = true) async throws -> [String]
	{
		var productIds: Set<String> = []
		
		for await result in Transaction.currentEntitlements
		{
			do {
				let transaction = try checkVerified(result)
				
				if transaction.productType == .autoRenewable ||
					(!onlyRenewable && transaction.productType == .nonRenewable)
				{
					productIds.insert(transaction.productID)
				}
			} catch {
				throw error
			}
		}
		
		return Array(productIds)
	}
}

@available(watchOS 8.0, *)
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T
{
	switch result
	{
	case .verified(let safe):
		return safe
	case .unverified:
		throw MercatoError.failedVerification
	}
}
