//
//  Parser.swift
//  ChopChop
//
//  Created by Cao Wenjie on 14/3/21.
//
import Foundation
import NaturalLanguage

struct RecipeParser {
    // matches 1., 1), Step 1., Step 1)
    static let stepsIndexRegex = "(Step\\s)?[1-9][0-9]*(\\.|\\))\\s"
    // matches 2 or 2.5
    static let intOrDecimal = "[1-9]\\d*(\\.\\d+)?"
    // matches 2
    static let integer = "[1-9]\\d*"
    // matches 1/2 or 1 / 2
    static let fraction = "[1-9]\\s*/\\s*[1-9]"
    // matches 2 or 2.5 or 1/2
    static let decimalOrFraction = "\(intOrDecimal)|\(fraction)"
    static let whitespace = "\\s+"
    static let optionalWhiteSpace = "\\s*"
    // places all units into a group like (kg|g|cup)
    static let units: String = (Array(QuantityParser.volumeWordMap.keys) + Array(QuantityParser.massWordMap.keys))
        .joined(separator: "|")

    static let ingredientConnector = "of"

    /**
     Parses a chunk of instructions into an array of steps. Parsing is done differently depending on
     whether the instructions are already numbered.
     */
    static func parseInstructions(instructions: String) -> [String] {
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedInstructions.isEmpty {
            return []
        }
        if trimmedInstructions.contains(where: \.isNewline) {
            return splitByNewLine(text: trimmedInstructions)
        }
        let regex = NSRegularExpression(stepsIndexRegex)
        let indexes = regex.matches(in: instructions, options: [],
                                    range: NSRange(location: 0, length: instructions.utf16.count))
        // when instructions are numbered, just parse base on the numbering
        if !indexes.isEmpty {
            let ranges = indexes.map({ $0.range })
            return splitByStepIndex(ranges: ranges, instructions: instructions)
        // when instructions are not numbered, each sentence is taken as a step
        } else {
            return splitBySentence(paragraph: instructions)
        }
    }

    private static func splitByNewLine(text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map({ String($0) })
    }

    private static func splitByStepIndex(ranges: [NSRange], instructions: String) -> [String] {
        var steps = [String]()
        for idx in 1..<ranges.count {
            let startIndex = instructions.index(instructions.startIndex,
                                                offsetBy: ranges[idx - 1].upperBound)
            let endIndex = instructions.index(instructions.startIndex,
                                              offsetBy: ranges[idx].lowerBound - 1)
            steps.append(String(instructions[startIndex...endIndex])
                            .trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let lastStart = instructions.index(instructions.startIndex,
                                           offsetBy: ranges[ranges.count - 1].upperBound)
        steps.append(String(instructions[lastStart..<instructions.endIndex])
                        .trimmingCharacters(in: .whitespacesAndNewlines))
        return steps
    }

    private static func splitBySentence(paragraph: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = paragraph
        return tokenizer.tokens(for: paragraph.startIndex..<paragraph.endIndex)
            .map({ String(paragraph[$0]).trimmingCharacters(in: .whitespaces) })
    }

    static func parseIngredientString(ingredientString: String) -> [String: Quantity] {
        let trimmedIngredient = ingredientString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIngredient.isEmpty {
            return [:]
        }
        var ingredientList = [String]()
        if trimmedIngredient.contains(where: \.isNewline) {
            ingredientList = splitByNewLine(text: ingredientString)
        } else {
            ingredientList = splitBySentence(paragraph: ingredientString)
        }

        return parseIngredientList(ingredientList: ingredientList)
    }
    /**
     Parse a list of ingredient description into a dictionary of ingredient name and its corresponding quantity.
     */
    static func parseIngredientList(ingredientList: [String]) -> [String: Quantity] {

        var ingredientDict = [String: Quantity]()

        ingredientList.map({ parseIngredient(ingredientText: $0) })
            .forEach({ ingredient in
                ingredientDict[ingredient.name] = ingredient.quantity
            })
        return ingredientDict
    }
    /**
     Parse a ingredient description into a pair of ingredient name and its corresponding quantity
     */
    static func parseIngredient(ingredientText: String) -> (name: String, quantity: Quantity) {
        // checks if the text has both a number and a fraction, e.g. 1 1/2 gram of potato
        var parseResult = matchNumberFractionOptionalUnitFormat(text: ingredientText)
        if let ingredients = parseResult {
            return ingredients
        }
        // checks if the text has either a number or a fraction, e.g. 1 egg, 1/2 lemon
        parseResult = matchNumberOrFractionOptionalUnitFormat(text: ingredientText)
        if let ingredients = parseResult {
            return ingredients
        }

        // case where there is no numerical information about the ingredient, e.g. salt
        do {
            let count = try Quantity(.count, value: 0)
            return (ingredientText, count)
        } catch {
            fatalError("Invalid count")
        }
    }

    private static func generateNumberFractionOptionalUnitRegex() -> NSRegularExpression {
        let pattern = groupWithName(pattern: integer, name: "number")
            + whitespace + groupWithName(pattern: fraction, name: "fraction")
            + optionalWhiteSpace + groupWithName(pattern: units, name: "unit", isOptional: true)
            + whitespace + groupWithName(pattern: ".*", name: "ingredient")
        return NSRegularExpression(pattern)
    }

    private static func matchNumberFractionOptionalUnitFormat(text: String) -> (name: String, quantity: Quantity)? {

        let regex = generateNumberFractionOptionalUnitRegex()
        guard let result =
            regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) else {

            return nil
        }

        guard let numberRange = Range(result.range(withName: "number"), in: text),
              let number = Double(text[numberRange]),
              let fractionRange = Range(result.range(withName: "fraction"), in: text),
              let ingredientRange = Range(result.range(withName: "ingredient"), in: text) else {

            return nil
        }

        let value = number + parseFraction(fraction: String(text[fractionRange]))
        var quantity: Quantity?
        if let unitRange = Range(result.range(withName: "unit"), in: text) {
            let unit = text[unitRange]
            quantity = QuantityParser.parseQuantity(value: value, unit: String(unit))
        } else {
            do {
                quantity = try Quantity(.count, value: value)
            } catch {
                fatalError("Invalid quantity.")
            }
        }

        let ingredient = extractIngredient(text: text, range: ingredientRange)

        guard let ingredientQuantity = quantity, !ingredient.isEmpty else {
            return nil
        }

        return (ingredient, ingredientQuantity)

    }

    private static func extractIngredient(text: String, range: Range<String.Index>) -> String {
        var ingredient = text[range].trimmingCharacters(in: .whitespaces)
        if ingredient.hasPrefix(ingredientConnector) {
            ingredient = ingredient.dropFirst(ingredientConnector.count)
                .trimmingCharacters(in: .whitespaces)
        }
        return ingredient
    }

    private static func generateNumberOrFractionOptionalUnitRegex() -> NSRegularExpression {
        let pattern = groupWithName(pattern: decimalOrFraction, name: "numeral")
            + optionalWhiteSpace + groupWithName(pattern: units, name: "unit", isOptional: true)
            + whitespace + groupWithName(pattern: ".*", name: "ingredient")

        return NSRegularExpression(pattern)
    }

    private static func matchNumberOrFractionOptionalUnitFormat(text: String) -> (name: String, quantity: Quantity)? {

        let regex = generateNumberOrFractionOptionalUnitRegex()
        guard let result =
            regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) else {

            return nil
        }

        guard let numeralRange = Range(result.range(withName: "numeral"), in: text),
              let ingredientRange = Range(result.range(withName: "ingredient"), in: text) else {
            return nil
        }

        var value: Double = 0
        let numberText = text[numeralRange]
        if isFraction(text: String(numberText)) {
            value = parseFraction(fraction: String(numberText))
        } else if let number = Double(numberText) {
            value = number
        } else {
            return nil
        }

        var quantity: Quantity?
        if let unitRange = Range(result.range(withName: "unit"), in: text) {
            let unit = text[unitRange]
            quantity = QuantityParser.parseQuantity(value: value, unit: String(unit))
        } else {
            do {
                quantity = try Quantity(.count, value: value)
            } catch {
                fatalError("Invalid quantity")
            }
        }

        let ingredient = extractIngredient(text: text, range: ingredientRange)

        guard let ingredientQuantity = quantity, !ingredient.isEmpty else {
            return nil
        }

        return (ingredient, ingredientQuantity)
    }

    private static func parseFraction(fraction: String) -> Double {
        let fractionArray = fraction.split(separator: "/")
        if fractionArray.count != 2 {
            return 0
        }
        let numeratorStr = fractionArray[0].trimmingCharacters(in: .whitespaces)
        let denominatorStr = fractionArray[1].trimmingCharacters(in: .whitespaces)

        guard let numerator = Double(numeratorStr), let denominator = Double(denominatorStr) else {
            return 0
        }

        return numerator / denominator
    }

    private static func isFraction(text: String) -> Bool {
        NSRegularExpression(fraction).matches(text)
    }

    private static func groupWithName(pattern: String, name: String?, isOptional: Bool = false) -> String {
        if let groupName = name {
            return isOptional ? "(?<\(groupName)>\(pattern))?" : "(?<\(groupName)>\(pattern))"
        } else {
            return isOptional ? "(\(pattern))?" : "(\(pattern))"
        }
    }
}
