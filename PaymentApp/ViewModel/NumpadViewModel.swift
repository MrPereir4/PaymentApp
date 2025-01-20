//
//  NumpadViewModel.swift
//  PaymentApp
//
//  Created by Vinnicius Pereira on 15/01/25.
//

import Foundation
import SwiftUI


protocol InputValidator {
    func validate(buttonAction: ButtonKeyType, currentInput: [String]) -> Bool
    func hasNumberToTransfer(totalAmountDisplayed: [String]) -> Bool
}

class DefaultInputValidator: InputValidator {
    private let maxDigits = 5

    func validate(buttonAction: ButtonKeyType, currentInput: [String]) -> Bool {
        switch buttonAction {
        case .number(let number):
            return validateNumber(number, currentInput: currentInput)
        case .delete:
            return !currentInput.isEmpty
        case .dot:
            return true
        }
    }

    private func validateNumber(_ number: Int, currentInput: [String]) -> Bool {
        if currentInput.count >= maxDigits || (number == 0 && currentInput.isEmpty) {
            return false
        }
        return true
    }
    
    func hasNumberToTransfer(totalAmountDisplayed: [String]) -> Bool {
        if totalAmountDisplayed != ["0"] {
            return true
        }else {
            return false
        }
    }
}







protocol ErrorHandler {
    func handleError()
}

class DefaultErrorHandler: ErrorHandler {
    func handleError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}






final class NumpadViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalAmountInsertedArray: [String] = []
    @Published var shake = false
    
    @Published var payButtonStatus: PayButtonStatus = .disabled

    // MARK: - Dependencies
    private let inputValidator: InputValidator
    private let errorHandler: ErrorHandler

    // MARK: - Initializer
    init(inputValidator: InputValidator = DefaultInputValidator(),
         errorHandler: ErrorHandler = DefaultErrorHandler()) {
        self.inputValidator = inputValidator
        self.errorHandler = errorHandler
    }

    // MARK: - Computed Properties
    var totalAmountDisplayed: [String] {
        totalAmountInsertedArray.isEmpty ? ["0"] : totalAmountInsertedArray
    }

    var totalAmount: String {
        totalAmountDisplayed.joined()
    }

    var currencySymbol: String = "R$"

    var arrayScale: CGFloat {
        max(0.8, 1 - CGFloat(totalAmountInsertedArray.count) * 0.04)
    }

    // MARK: - Public Methods
    func didTapKey(buttonAction: ButtonKeyType) {
        guard inputValidator.validate(buttonAction: buttonAction, currentInput: totalAmountInsertedArray) else {
            triggerError()
            return
        }
        
        switch buttonAction {
        case .number(let number):
            appendNumber(number)
        case .delete:
            removeLastInput()
        case .dot:
            applyDecimalLogic()
        }
        
        if !inputValidator.hasNumberToTransfer(totalAmountDisplayed: self.totalAmountDisplayed) {
            self.payButtonStatus = .disabled
        }else {
            self.payButtonStatus = .iddle
        }
    }
    
    func didTapPayKey() {
        switch self.payButtonStatus {
        case .iddle:
            self.payButtonStatus = .loading
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.payButtonStatus = .completed
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.payButtonStatus = .disabled
                    self.totalAmountInsertedArray = []
                }
                
            }
            
        case .loading, .completed, .disabled:
            return
        }
        
        
    }

    // MARK: - Private Methods
    private func appendNumber(_ number: Int) {
        totalAmountInsertedArray.append(String(number))
    }

    private func removeLastInput() {
        totalAmountInsertedArray.removeLast()
    }

    private func applyDecimalLogic() {
        
    }

    private func triggerError() {
        shake.toggle()
        errorHandler.handleError()
    }
}
