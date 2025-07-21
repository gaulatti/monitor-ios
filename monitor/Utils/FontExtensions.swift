//
//  FontExtensions.swift
//  monitor
//
//  Created by Javier Godoy Núñez on 7/2/25.
//

import SwiftUI

extension Font {
    
    /// Libre Franklin Light
    static func libreFranklinLight(size: CGFloat) -> Font {
        // Try multiple possible font names
        let possibleNames = ["Libre Franklin Light", "LibreFranklin-Light", "libre-franklin-light"]
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        // Fallback to system font
        return Font.system(size: size, weight: .light, design: .default)
    }
    
    /// Libre Franklin Regular
    static func libreFranklinRegular(size: CGFloat) -> Font {
        let possibleNames = ["Libre Franklin", "Libre Franklin Regular", "LibreFranklin-Regular", "libre-franklin-regular"]
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        return Font.system(size: size, weight: .regular, design: .default)
    }
    
    /// Libre Franklin Medium
    static func libreFranklinMedium(size: CGFloat) -> Font {
        let possibleNames = ["Libre Franklin Medium", "LibreFranklin-Medium", "libre-franklin-medium"]
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        return Font.system(size: size, weight: .medium, design: .default)
    }
    
    /// Libre Franklin SemiBold
    static func libreFranklinSemiBold(size: CGFloat) -> Font {
        let possibleNames = ["Libre Franklin SemiBold", "Libre Franklin Semibold", "LibreFranklin-SemiBold", "libre-franklin-semibold"]
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        return Font.system(size: size, weight: .semibold, design: .default)
    }
    
    /// Libre Franklin Bold
    static func libreFranklinBold(size: CGFloat) -> Font {
        let possibleNames = ["Libre Franklin Bold", "LibreFranklin-Bold", "libre-franklin-bold"]
        for name in possibleNames {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
        }
        return Font.system(size: size, weight: .bold, design: .default)
    }
    
    // MARK: - Semantic Font Styles
    
    /// App title font
    static var appTitle: Font {
        return .libreFranklinBold(size: 28)
    }
    
    /// Section header font
    static var sectionHeader: Font {
        return .libreFranklinSemiBold(size: 18)
    }
    
    /// Body text font
    static var bodyText: Font {
        return .libreFranklinRegular(size: 15)
    }
    
    /// Body medium text font
    static var bodyMedium: Font {
        return .libreFranklinMedium(size: 15)
    }
    
    /// Small text font
    static var smallText: Font {
        return .libreFranklinRegular(size: 12)
    }
    
    
    /// Mid-point between medium and small
    static var subMedium: Font {
        return .libreFranklinRegular(size: 14)
    }
    
    /// Caption font
    static var caption: Font {
        return .libreFranklinMedium(size: 10)
    }
    
    /// Button font
    static var button: Font {
        return .libreFranklinSemiBold(size: 16)
    }
}
