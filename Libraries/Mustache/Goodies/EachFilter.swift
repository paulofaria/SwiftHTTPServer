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

let EachFilter = Filter { (box: MustacheBox) -> MustacheBox in
    
    // {{# each(nothing) }}...{{/ }}
    if box.isEmpty {

        return box

    }
    
    // {{# each(dictionary) }}...{{/ }}
    //
    //     // Renders "firstName: Charles, lastName: Bronson."
    //     let dictionary = ["firstName": "Charles", "lastName": "Bronson"]
    //     let template = try! Template(string: "{{# each(dictionary) }}{{ @key }}: {{ . }}{{^ @last }}, {{/ @last }}{{/ each(dictionary) }}.")
    //     template.registerInBaseContext("each", Box(StandardLibrary.each))
    //     try! template.render(Box(["dictionary": dictionary]))
    //
    // The dictionaryValue box property makes sure to return a
    // [String: MustacheBox] whatever the boxed dictionary-like value
    // (NSDictionary, [String: Int], [String: CustomObject], etc.
    if let dictionary = box.dictionaryValue {

        let count = dictionary.count

        let transformedBoxes = dictionary.enumerate().map { (index: Int, element: (key: String, box: MustacheBox)) -> MustacheBox in

            let customRenderFunction: RenderFunction = { (var info) in
                // Push positional keys in the context stack and then perform
                // a regular rendering.
                var position: [String: MustacheBox] = [:]
                position["@index"] = Box(boxable: index)
                position["@indexPlusOne"] = Box(boxable: index + 1)
                position["@indexIsEven"] = Box(boxable: index % 2 == 0)
                position["@first"] = Box(boxable: index == 0)
                position["@last"] = Box(boxable: (index == count - 1))
                position["@key"] = Box(boxable: element.key)
                info.context = info.context.extendedContext(box: Box(boxable: position))
                return try element.box.render(info: info)
            }

            return Box(render: customRenderFunction)

        }

        return Box(boxable: transformedBoxes)

    }
    
    
    // {{# each(array) }}...{{/ }}
    //
    //     // Renders "1: bread, 2: ham, 3: butter"
    //     let array = ["bread", "ham", "butter"]
    //     let template = try! Template(string: "{{# each(array) }}{{ @indexPlusOne }}: {{ . }}{{^ @last }}, {{/ @last }}{{/ each(array) }}.")
    //     template.registerInBaseContext("each", Box(StandardLibrary.each))
    //     try! template.render(Box(["array": array]))
    //
    // The arrayValue box property makes sure to return a [MustacheBox] whatever
    // the boxed collection: NSArray, NSSet, [String], [CustomObject], etc.
    if let boxes = box.arrayValue {
        let count = boxes.count
        let transformedBoxes = boxes.enumerate().map { (index: Int, box: MustacheBox) -> MustacheBox in
            let customRenderFunction: RenderFunction = { (var info) in
                // Push positional keys in the context stack and then perform
                // a regular rendering.
                var position: [String: MustacheBox] = [:]
                position["@index"] = Box(boxable: index)
                position["@indexPlusOne"] = Box(boxable: index + 1)
                position["@indexIsEven"] = Box(boxable: index % 2 == 0)
                position["@first"] = Box(boxable: index == 0)
                position["@last"] = Box(boxable: (index == count - 1))
                info.context = info.context.extendedContext(box: Box(boxable: position))
                return try box.render(info: info)
            }
            return Box(render: customRenderFunction)
        }
        return Box(boxable: transformedBoxes)
    }
    
    // Non-iterable value
    throw Error.Generic("Rendering Error", "Non-enumerable argument in each filter: \(box.value)")

}
