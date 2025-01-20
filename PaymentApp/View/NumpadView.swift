//
//  NumpadView.swift
//  PaymentApp
//
//  Created by Vinnicius Pereira on 15/01/25.
//

import SwiftUI

struct NumpadView: View {
    
    @StateObject var numpadViewModel: NumpadViewModel = NumpadViewModel()
    
    let numpadNumbers: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 32), count: 3)
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0){
                Text(self.numpadViewModel.currencySymbol)
                    .font(.system(size: 80, weight: .semibold))
                
                ForEach(Array(numpadViewModel.totalAmountDisplayed.enumerated()), id: \.offset) { index, number in
                    
                    if numpadViewModel.totalAmountDisplayed.count >= 4 && index == numpadViewModel.totalAmountDisplayed.count - 3 {
                        Text(",")
                            .font(.system(size: 70, weight: .semibold))
                            .transition(.blurReplace.combined(with: .scale))
                            .id(index)
                    }
                    Text(number)
                        .font(.system(size: 80, weight: .semibold))
                        .zIndex(Double(numpadViewModel.totalAmountDisplayed.count - 1 - index))
                        .transition(
                            .blurReplace.combined(with:
                                    .scale).combined(with:
                                            .offset(x: numpadViewModel.totalAmountInsertedArray.count > 1 ? -20 : 0 ,y: 60)))
                        .id(number)
                }
 
            }
            
            .scaleEffect(numpadViewModel.arrayScale)
            .modifier(HorizontalShakeEffect(animatableData: numpadViewModel.shake ? 0 : 1))
            .animation(.easeInOut, value: numpadViewModel.shake)
            .animation(.spring(duration: 0.4, bounce: 0.4, blendDuration: 0.425), value: numpadViewModel.totalAmountDisplayed)
            .frame(maxWidth: .infinity)
            
            
            
            Spacer()
            VStack(spacing: 32) {
                LazyVGrid(columns: numpadNumbers, spacing: 32){
                    ForEach(1..<10) { number in
                        NumberPadButtonView(numpadViewModel: self.numpadViewModel, buttonType: .number(number))
                    }
                    
                    NumberPadButtonView(numpadViewModel: self.numpadViewModel, buttonType: .dot)
                    NumberPadButtonView(numpadViewModel: self.numpadViewModel, buttonType: .number(0))
                    NumberPadButtonView(numpadViewModel: self.numpadViewModel, buttonType: .delete)
                    
                }
                
                PayButton(numpadViewModel: self.numpadViewModel)
                    
            }
            .padding()
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .fontDesign(.rounded)
    }
}

enum ButtonKeyType {
    case number(Int)
    case delete
    case dot
}

//MARK: - Number Button
struct NumberPadButtonView: View {
    
    @ObservedObject var numpadViewModel: NumpadViewModel
    
    var buttonType: ButtonKeyType
    
    @State var isTextPressed: Bool = false
    
    var body: some View {
        Button {
            let impactGesture = UIImpactFeedbackGenerator(style: .light)
            impactGesture.impactOccurred()
            
            self.numpadViewModel.didTapKey(buttonAction: self.buttonType)
        } label: {
            Group {
                switch self.buttonType {
                case .number(let number):
                    Text(String(describing: number))
                case .delete:
                    Image(systemName: "chevron.left")
                case .dot:
                    Text(".")
                }
            }
            .font(.title2)
            .scaleEffect(self.isTextPressed ? 1.6 : 1.0)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(.blackConstrast)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeIn(duration: 0.01)) {
                        isTextPressed = true
                    }
                }
                .onEnded { _ in
                    
                    withAnimation(.spring(response: 0.3,
                                          dampingFraction: 0.65,
                                          blendDuration: 0.9)) {
                        isTextPressed = false
                    }
                }
        )
    }
}

public struct HorizontalShakeEffect: GeometryEffect {
    private let intensity: CGFloat = 10
    private let frequency: CGFloat = 5
    public var animatableData: CGFloat

    public init(animatableData: CGFloat) {
        self.animatableData = animatableData
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: self.intensity * sin(self.animatableData * .pi * self.frequency),
                y: 0.0
            )
        )
    }
}

enum PayButtonStatus {
    case iddle, loading, completed, disabled
}

struct PayButton: View {
    
    @ObservedObject var numpadViewModel: NumpadViewModel
    
    @State private var t: CGFloat = 0.0
    @State var changeButtonTitle: Bool = true
    @State var showIcon: Bool = false
    
    @State private var currentButtonTitle: String = "Pay"
    @State private var nextButtonTitle: String = "Pay"
    
    var body: some View {
        
            
        VStack {
            
            ZStack {
                if currentButtonTitle == nextButtonTitle {
                    Text(currentButtonTitle)
                        .id(currentButtonTitle) // Força distinção no SwiftUI
                        .transition(.customAsymmetricMove(insertionOffset: 7, removalOffset: -7))
                } else {
                    // Mostra o próximo texto
                    
                    Label(nextButtonTitle, systemImage: self.showIcon ? "checkmark.circle.fill": "")
                        .labelStyle(ConditionalLabelStyle(showIcon: self.showIcon))
                        .id(nextButtonTitle) // Força distinção no SwiftUI
                        .transition(.customAsymmetricMove(insertionOffset: 7, removalOffset: -7))
                        .foregroundStyle(self.numpadViewModel.payButtonStatus == .completed ? .unsaturatedWhite : .white)
                        
                }
            }

        }
        .font(.body)
        .fontWeight(.bold)
        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        .fontDesign(.rounded)
        .contentTransition(.interpolate)
        .animation(.snappy(duration: 0.7, extraBounce: 0), value: self.changeButtonTitle)
        .foregroundStyle(.white)
        .frame(maxWidth: 250)
        .frame(height: 70)
        .background(
            MeshGradient(
                width: 3,
                height: 4,
                points: animatedPoints(t: t),
                colors: self.calculateButtonsColor(status: self.numpadViewModel.payButtonStatus), smoothsColors: self.numpadViewModel.payButtonStatus == .completed ? true : false
            )
            .ignoresSafeArea()
            .animation(.snappy(duration: 0.7), value: self.numpadViewModel.payButtonStatus)
        )
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                self.t += 0.016 // Incremento do tempo
            }
        }
        .onTapGesture {
            
            self.numpadViewModel.didTapPayKey()

        }
        .onChange(of: self.numpadViewModel.payButtonStatus, { _, newValue in
            self.updateTitles(for: newValue)
            self.changeButtonTitle.toggle()
        })
        .opacity(self.numpadViewModel.payButtonStatus == .disabled ? 0.3 : 1.0)
        //.disabled(self.payButtonStatus == .disabled)
    }
    
    private func updateTitles(for status: PayButtonStatus) {
        let newTitle = buttonTitle(for: status)
        if nextButtonTitle != newTitle {
            currentButtonTitle = nextButtonTitle
            nextButtonTitle = newTitle
            
            if status == .completed {
                showIcon = true
            } else {
                showIcon = false
            }
        }
    }
    
    private func buttonTitle(for status: PayButtonStatus) -> String {
        switch status {
        case .iddle, .disabled:
            return "Pay"
        case .loading:
            return "Paying"
        case .completed:
            return "Completed"
        }
    }
    
    func animatedPoints(t: CGFloat) -> [SIMD2<Float>] {
        return self.calculateButtonsWaveEffect(status: self.numpadViewModel.payButtonStatus, xValue: 0, t: t, index: 0)
    }
    
    private func calculateButtonsWaveEffect(status: PayButtonStatus, xValue: Float, t: CGFloat, index: Int) -> [SIMD2<Float>] {
        switch status {
        case .iddle, .disabled:
           
            return [.init(0.0, 0.0),
                    .init(0.5, 0.0),
                    .init(1.0, 0.0),
                    .init(0.0, 1.0),
                    .init(0.5, 1.0),
                    .init(1.0, 1.0),
                    .init(0.0, 1.0),
                    .init(0.5, 1.0),
                    .init(1.0, 1.0),
                    .init(0.0, 1.0),
                    .init(0.5, 1.0),
                    .init(1.0, 1.0),
            ]
        
        case .loading, .completed:
            var pointsArray: [SIMD2<Float>] = []
            pointsArray += [.init(0.0, 0.0),
                            .init(0.5, 0.0),
                            .init(1.0, 0.0)]
            pointsArray += mountainPointsHorizontal(amplitude: 0.4, frequency: 1.3, time: Float(t), bottomPositionY: 1.0, payButtonStatus: status)
            
            pointsArray += [.init(0.0, 1.0),
                            .init(0.5, 1.0),
                            .init(1.0, 1.0)]
            
            return pointsArray
        }
    }

    func mountainPointsHorizontal(
        amplitude: Float,
        frequency: Float,
        time: Float,
        bottomPositionY: Float,
        payButtonStatus: PayButtonStatus
    ) -> [SIMD2<Float>] {
        
        // Ajusta a frequência com base no estado do botão
        let effectiveFrequency = payButtonStatus == .loading ? frequency : 0.0

        // Define valores fixos para os pontos horizontais
        let leftX: Float = 0.0
        let baseMiddleX: Float = 0.5
        let rightX: Float = 1.0

        // Define espaçamentos e deslocamentos
        let differenceSpacing: Float = 0.05
        let baseEdgesY = bottomPositionY - differenceSpacing
        let reversedEdgesY = baseEdgesY - 2
        let baseMiddleY: Float = 0.6
        let reversedMiddleY: Float = baseMiddleY - 2

        // Determina as posições Y com base no estado do botão
        let topSectionLeftY = payButtonStatus == .loading ? baseEdgesY : reversedEdgesY
        let topSectionMiddleY = payButtonStatus == .loading ? baseMiddleY : reversedMiddleY
        let topSectionRightY = payButtonStatus == .loading ? baseEdgesY : reversedEdgesY
        
        let bottomOffset: Float = 0.6
        let bottomSectionLeftY = payButtonStatus == .loading ? (topSectionLeftY + bottomOffset) : -0.5
        let bottomSectionMiddleY = payButtonStatus == .loading ? (topSectionMiddleY + bottomOffset) : -0.5
        let bottomSectionRightY = payButtonStatus == .loading ? (topSectionRightY + bottomOffset) : -0.5

        // Calcula o deslocamento horizontal do ponto médio
        let middleX = baseMiddleX + amplitude * sin(effectiveFrequency * time)

        // Retorna os pontos em um único array
        return [
            SIMD2(leftX, topSectionLeftY),
            SIMD2(middleX, topSectionMiddleY),
            SIMD2(rightX, topSectionRightY),
            SIMD2(leftX, bottomSectionLeftY),
            SIMD2(middleX, bottomSectionMiddleY),
            SIMD2(rightX, bottomSectionRightY)
        ]
    }

    func calculateButtonsColor(status: PayButtonStatus) -> [Color] {
        switch status {
        case .iddle:
            return [
                .customBlue, .customBlue, .customBlue,
                
                .customPink.opacity(0.6), .customPink.opacity(0.6), .customPink.opacity(0.6),
                .customPink.opacity(0.6), .customPink.opacity(0.6), .customPink.opacity(0.6),
                
                .customBlue.opacity(0.6), .customBlue.opacity(0.6), .customBlue.opacity(0.6),
            ]

        case .loading, .completed:
            return [
                .customBlue, .customBlue, .customBlue,
                
                .customPink, .customPink, .customPink,
                .customPink, .customPink, .customPink,
                
                .customBlue, .customBlue, .customBlue,
            ]

        case .disabled:
            return [
                Color(UIColor.systemGray5), Color(UIColor.systemGray5), Color(UIColor.systemGray5),
                
                Color(UIColor.systemGray5), Color(UIColor.systemGray5), Color(UIColor.systemGray5),
                
                Color(UIColor.systemGray5), Color(UIColor.systemGray5), Color(UIColor.systemGray5),
                
                Color(UIColor.systemGray5), Color(UIColor.systemGray5), Color(UIColor.systemGray5),
            ]
        }
    }
}



#Preview {
    NumpadView()
}
