// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

protocol TemplateTokenConsumer {
    func parser(parser:TemplateParser, shouldContinueAfterParsingToken token:TemplateToken) -> Bool
    func parser(parser:TemplateParser, didFailWithError error:ErrorType)
}

final class TemplateParser {
    let tokenConsumer: TemplateTokenConsumer
    private let tagDelimiterPair: TagDelimiterPair
    
    init(tokenConsumer: TemplateTokenConsumer, configuration: Configuration) {
        self.tokenConsumer = tokenConsumer
        self.tagDelimiterPair = configuration.tagDelimiterPair
    }
    
    func parse(templateString:String, templateID: TemplateID?) {
        var currentDelimiters = ParserTagDelimiters(tagDelimiterPair: tagDelimiterPair)
        
        var i = templateString.startIndex
        let end = templateString.endIndex
        
        var state: State = .Start
        var stateStart = i
        
        var lineNumber = 1
        var startLineNumber = lineNumber
        
        let atString = { (string: String?) -> Bool in
            return string != nil && templateString.substringFromIndex(i).hasPrefix(string!)
        }
        
        while i < end {
            let c = templateString[i]
            
            switch state {
            case .Start:
                if c == "\n" {
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .Text
                    
                    ++lineNumber
                } else if atString(currentDelimiters.unescapedTagStart) {
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .UnescapedTag
                    i = i.advancedBy(currentDelimiters.unescapedTagStartLength).predecessor()
                } else if atString(currentDelimiters.setDelimitersStart) {
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .SetDelimitersTag
                    i = i.advancedBy(currentDelimiters.setDelimitersStartLength).predecessor()
                } else if atString(currentDelimiters.tagDelimiterPair.0) {
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .Tag
                    i = i.advancedBy(currentDelimiters.tagStartLength).predecessor()
                } else {
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .Text
                }
            case .Text:
                if c == "\n" {
                    ++lineNumber
                } else if atString(currentDelimiters.unescapedTagStart) {
                    if stateStart != i {
                        let range = stateStart..<i
                        let token = TemplateToken(
                            type: .Text(text: templateString[range]),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: stateStart..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .UnescapedTag
                    i = i.advancedBy(currentDelimiters.unescapedTagStartLength).predecessor()
                } else if atString(currentDelimiters.setDelimitersStart) {
                    if stateStart != i {
                        let range = stateStart..<i
                        let token = TemplateToken(
                            type: .Text(text: templateString[range]),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: stateStart..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .SetDelimitersTag
                    i = i.advancedBy(currentDelimiters.setDelimitersStartLength).predecessor()
                } else if atString(currentDelimiters.tagDelimiterPair.0) {
                    if stateStart != i {
                        let range = stateStart..<i
                        let token = TemplateToken(
                            type: .Text(text: templateString[range]),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: stateStart..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    startLineNumber = lineNumber
                    stateStart = i
                    state = .Tag
                    i = i.advancedBy(currentDelimiters.tagStartLength).predecessor()
                }
            case .Tag:
                if c == "\n" {
                    ++lineNumber
                } else if atString(currentDelimiters.tagDelimiterPair.1) {
                    let tagInitialIndex = stateStart.advancedBy(currentDelimiters.tagStartLength)
                    let tagInitial = templateString[tagInitialIndex]
                    let tokenRange = stateStart ..< i.advancedBy(currentDelimiters.tagEndLength)
                    switch tagInitial {
                    case "!":
                        let token = TemplateToken(
                            type: .Comment,
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "#":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .Section(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "^":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .InvertedSection(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "$":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .InheritableSection(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "/":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .Close(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case ">":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .Partial(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "<":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .InheritedPartial(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "&":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .UnescapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "%":
                        let content = templateString.substringWithRange(tagInitialIndex.successor()..<i)
                        let token = TemplateToken(
                            type: .Pragma(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    default:
                        let content = templateString.substringWithRange(tagInitialIndex..<i)
                        let token = TemplateToken(
                            type: .EscapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    stateStart = i.advancedBy(currentDelimiters.tagEndLength)
                    state = .Start
                    i = i.advancedBy(currentDelimiters.tagEndLength).predecessor()
                }
                break
            case .UnescapedTag:
                if c == "\n" {
                    ++lineNumber
                } else if atString(currentDelimiters.unescapedTagEnd) {
                    let tagInitialIndex = stateStart.advancedBy(currentDelimiters.unescapedTagStartLength)
                    let content = templateString.substringWithRange(tagInitialIndex..<i)
                    let token = TemplateToken(
                        type: .UnescapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                        lineNumber: startLineNumber,
                        templateID: templateID,
                        templateString: templateString,
                        range: stateStart ..< i.advancedBy(currentDelimiters.unescapedTagEndLength))
                    if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                        return
                    }
                    stateStart = i.advancedBy(currentDelimiters.unescapedTagEndLength)
                    state = .Start
                    i = i.advancedBy(currentDelimiters.unescapedTagEndLength).predecessor()
                }
            case .SetDelimitersTag:
                if c == "\n" {
                    ++lineNumber
                } else if atString(currentDelimiters.setDelimitersEnd) {
                    let tagInitialIndex = stateStart.advancedBy(currentDelimiters.setDelimitersStartLength)
                    let content = templateString.substringWithRange(tagInitialIndex..<i)
                    let newDelimiters = content.componentsSeparatedByCharactersInSet(CharacterSet.whitespaceAndNewline).filter { $0.characters.count > 0 }
                    if (newDelimiters.count != 2) {
                        let locationDescription: String
                        if let templateID = templateID {
                            locationDescription = "line \(startLineNumber) of template \(templateID)"
                        } else {
                            locationDescription = "line \(startLineNumber)"
                        }

                        let error = MustacheError.Parse("Parse error at \(locationDescription): Invalid set delimiters tag")
                        tokenConsumer.parser(self, didFailWithError: error)
                        return

                    }
                    
                    let token = TemplateToken(
                        type: .SetDelimiters,
                        lineNumber: startLineNumber,
                        templateID: templateID,
                        templateString: templateString,
                        range: stateStart ..< i.advancedBy(currentDelimiters.setDelimitersEndLength))
                    if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                        return
                    }
                    
                    stateStart = i.advancedBy(currentDelimiters.setDelimitersEndLength)
                    state = .Start
                    i = i.advancedBy(currentDelimiters.setDelimitersEndLength).predecessor()
                    
                    currentDelimiters = ParserTagDelimiters(tagDelimiterPair: (newDelimiters[0], newDelimiters[1]))
                }
            }
            
            i = i.successor()
        }
        
        
        // EOF
        
        switch state {
        case .Start:
            break
        case .Text:
            let range = stateStart..<end
            let token = TemplateToken(
                type: .Text(text: templateString[range]),
                lineNumber: startLineNumber,
                templateID: templateID,
                templateString: templateString,
                range: range)
            tokenConsumer.parser(self, shouldContinueAfterParsingToken: token)
        case .Tag, .UnescapedTag, .SetDelimitersTag:
            let locationDescription: String
            if let templateID = templateID {
                locationDescription = "line \(startLineNumber) of template \(templateID)"
            } else {
                locationDescription = "line \(startLineNumber)"
            }

            let error = MustacheError.Parse("Parse error at \(locationDescription): Unclosed Mustache tag")
            tokenConsumer.parser(self, didFailWithError: error)

        }

    }
    
    
    // MARK: - Private
    
    private enum State {
        case Start
        case Text
        case Tag
        case UnescapedTag
        case SetDelimitersTag
    }
    
    private struct ParserTagDelimiters {
        let tagDelimiterPair : TagDelimiterPair
        let tagStartLength: Int
        let tagEndLength: Int
        let unescapedTagStart: String?
        let unescapedTagStartLength: Int
        let unescapedTagEnd: String?
        let unescapedTagEndLength: Int
        let setDelimitersStart: String
        let setDelimitersStartLength: Int
        let setDelimitersEnd: String
        let setDelimitersEndLength: Int
        
        init(tagDelimiterPair : TagDelimiterPair) {
            self.tagDelimiterPair = tagDelimiterPair
            
            tagStartLength = tagDelimiterPair.0.startIndex.distanceTo(tagDelimiterPair.0.endIndex)
            tagEndLength = tagDelimiterPair.1.startIndex.distanceTo(tagDelimiterPair.1.endIndex)
            
            let usesStandardDelimiters = (tagDelimiterPair.0 == "{{") && (tagDelimiterPair.1 == "}}")
            unescapedTagStart = usesStandardDelimiters ? "{{{" : nil
            unescapedTagStartLength = unescapedTagStart != nil ? unescapedTagStart!.startIndex.distanceTo(unescapedTagStart!.endIndex) : 0
            unescapedTagEnd = usesStandardDelimiters ? "}}}" : nil
            unescapedTagEndLength = unescapedTagEnd != nil ? unescapedTagEnd!.startIndex.distanceTo(unescapedTagEnd!.endIndex) : 0
            
            setDelimitersStart = "\(tagDelimiterPair.0)="
            setDelimitersStartLength = setDelimitersStart.startIndex.distanceTo(setDelimitersStart.endIndex)
            setDelimitersEnd = "=\(tagDelimiterPair.1)"
            setDelimitersEndLength = setDelimitersEnd.startIndex.distanceTo(setDelimitersEnd.endIndex)
        }
    }
}
