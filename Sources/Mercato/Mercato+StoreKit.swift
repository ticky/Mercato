//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 10.10.2021.
//

import Foundation
import StoreKit

@available(watchOS 8.0, *)
typealias RenewalState = Product.SubscriptionInfo.RenewalState

@available(watchOS 8.0, *)
public extension Product
{
	var isEligibleForIntroOffer: Bool
	{
		get async
		{
			await subscription?.isEligibleForIntroOffer ?? false
		}
	}
	
	var hasActiveSubscription: Bool
	{
		get async
		{
			await (try? subscription?.status.first?.state == RenewalState.subscribed) ?? false
		}
	}
}
